import 'dart:async';

import 'package:findme/features/auth/data/auth_repository.dart';
import 'package:findme/features/auth/data/session_store.dart';
import 'package:findme/features/tracker/data/ingest_client.dart';
import 'package:findme/features/tracker/data/point_queue.dart';
import 'package:findme/features/tracker/data/tracker_store.dart';
import 'package:findme/features/tracker/data/wake_channel.dart';
import 'package:findme/features/tracker/domain/fix.dart';
import 'package:findme/features/tracker/domain/location_source.dart';
import 'package:findme/features/tracker/domain/upload_policy.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What the status line says is wrong, if anything. needAlways wins over token problems.
enum TrackerProblem { none, noToken, badToken, needAlways }

@immutable
class TrackerState {
  const TrackerState({
    this.on = false,
    this.problem = TrackerProblem.none,
    this.queued = 0,
    this.rejected = 0,
    this.lastOk,
    this.lastFix,
    this.sending = false,
  });

  /// Recording right now.
  final bool on;
  final TrackerProblem problem;

  /// Fixes waiting for the server, and fixes it refused as malformed.
  final int queued;
  final int rejected;
  final DateTime? lastOk;
  final DateTime? lastFix;
  final bool sending;

  TrackerState copyWith({
    bool? on,
    TrackerProblem? problem,
    int? queued,
    int? rejected,
    DateTime? lastOk,
    DateTime? lastFix,
    bool? sending,
  }) => TrackerState(
    on: on ?? this.on,
    problem: problem ?? this.problem,
    queued: queued ?? this.queued,
    rejected: rejected ?? this.rejected,
    lastOk: lastOk ?? this.lastOk,
    lastFix: lastFix ?? this.lastFix,
    sending: sending ?? this.sending,
  );
}

/// The time, replaceable in tests.
final trackerClockProvider = Provider<DateTime Function()>((_) => DateTime.now);

/// Records fixes into the queue and uploads them to `/ingest`. Deliberately not tied to the sign-in session
/// (`signedInProvider`): a lapsed session must not stop tracking. Only [forget] (a deliberate sign-out, or another
/// account signing in) ends it.
class TrackerController extends Notifier<TrackerState> {
  StreamSubscription<Fix>? _fixes;
  Timer? _tick;
  bool _uploading = false;
  int _failures = 0;
  DateTime? _notBefore;

  LocationSource get _gps => ref.read(locationSourceProvider);
  TrackerStore get _store => ref.read(trackerStoreProvider);
  Future<PointQueue> get _queue => ref.read(pointQueueProvider.future);
  DateTime _now() => ref.read(trackerClockProvider)();

  @override
  TrackerState build() {
    ref
      ..onDispose(_stop)
      ..read(wakeChannelProvider).onWake(() => unawaited(wake()));
    return const TrackerState();
  }

  /// iOS woke the app (significant location change, possibly a background relaunch): start GPS again, since iOS
  /// may have paused it while you stood still.
  Future<void> wake() async {
    if (_fixes == null) return;
    unawaited(_fixes!.cancel());
    _fixes = null;
    await _start();
  }

  /// At app start (also a background relaunch): carry on if tracking was left on.
  Future<void> resume() async {
    await _refresh();
    if (!await _store.enabled()) return;
    if (await _gps.access() != LocationAccess.always) {
      state = state.copyWith(on: false, problem: TrackerProblem.needAlways);
      return;
    }
    await _start();
  }

  /// The user turned the switch on (after the disclosure screen).
  Future<void> turnOn() async {
    if (await _gps.request() != LocationAccess.always) {
      state = state.copyWith(on: false, problem: TrackerProblem.needAlways);
      return;
    }
    await _store.setEnabled(on: true);
    // Whose points these are, even before a token is pasted: another account signing in ends them (AuthController).
    final access = await ref.read(authRepositoryProvider).getAccessToken();
    final sub = subOf(access ?? '');
    if (sub != null) await _store.setOwner(sub);
    await _start();
  }

  Future<void> turnOff() async {
    _stop();
    await ref.read(wakeChannelProvider).stop();
    await _store.setEnabled(on: false);
    state = state.copyWith(
      on: false,
      problem: state.problem == TrackerProblem.needAlways
          ? TrackerProblem.none
          : null,
    );
  }

  Future<void> sendNow() {
    _notBefore = null;
    return _upload(force: true);
  }

  // ponytail: pasted ingest token until the server hands it out after sign-in; delete TokenField + saveToken then.
  Future<void> saveToken(String raw) async {
    final access = await ref.read(authRepositoryProvider).getAccessToken();
    await _store.saveToken(raw, subOf(access ?? '') ?? '');
    _notBefore = null;
    state = state.copyWith(
      problem: state.problem == TrackerProblem.needAlways
          ? null
          : TrackerProblem.none,
    );
    await _upload();
  }

  /// This account's tracking ends on this phone: one last upload (best effort), then queue and token are gone.
  Future<void> forget() async {
    _stop();
    await ref.read(wakeChannelProvider).stop();
    try {
      await () async {
        await _work; // fixes already received are written first
        await _running; // an upload in flight is not forced: wait for it…
        await _upload(force: true); // …then send whatever is left
      }().timeout(const Duration(seconds: 10));
    } on Object {
      // offline or slow: those fixes are lost with the account's queue, by design
    }
    await _work; // nothing lands in the queue after it is cleared
    await (await _queue).clear();
    await _store.forget();
    _failures = 0;
    _notBefore = null;
    state = const TrackerState();
  }

  Future<void> _start() async {
    _fixes ??= _gps.fixes().listen(
      _onFix,
      onError: (Object _) =>
          state = state.copyWith(on: false, problem: TrackerProblem.needAlways),
    );
    // Standing still sends no fixes; this still uploads what waits once the 5 minutes are up.
    _tick ??= Timer.periodic(
      const Duration(minutes: 1),
      (_) => unawaited(_upload()),
    );
    await ref.read(wakeChannelProvider).start();
    final token = await _store.token();
    state = state.copyWith(
      on: true,
      problem: token == null ? TrackerProblem.noToken : TrackerProblem.none,
    );
  }

  void _stop() {
    unawaited(_fixes?.cancel());
    _fixes = null;
    _tick?.cancel();
    _tick = null;
  }

  /// Fixes are written one after another, in order; the upload they may start runs beside them, so fixes keep
  /// landing in the queue while a slow upload is in flight.
  void _onFix(Fix f) {
    _work = _work.then((_) async {
      await (await _queue).append(f);
      state = state.copyWith(lastFix: f.at);
      await _refresh();
      unawaited(_upload());
    });
  }

  Future<void> _work = Future.value();
  Future<void> _running = Future.value();

  /// Resolves once every fix received so far is written and (with [uploads]) no upload is running.
  @visibleForTesting
  Future<void> idle({bool uploads = true}) async {
    while (true) {
      final w = _work;
      final u = _running;
      await w;
      if (uploads) await u;
      if (identical(w, _work) && identical(u, _running)) return;
    }
  }

  Future<void> _refresh() async {
    final q = await _queue;
    state = state.copyWith(
      queued: await q.count(),
      rejected: await q.rejectedCount(),
    );
  }

  /// One upload run at a time; [force] = "Gửi ngay": ignore the thresholds and the backoff, send everything.
  Future<void> _upload({bool force = false}) {
    if (_uploading) return Future.value();
    _uploading = true;
    return _running = _uploadRun(force: force);
  }

  Future<void> _uploadRun({required bool force}) async {
    try {
      final token = await _store.token();
      if (token == null) {
        if (state.problem != TrackerProblem.needAlways) {
          state = state.copyWith(problem: TrackerProblem.noToken);
        }
        return;
      }
      if (state.problem == TrackerProblem.badToken) return;
      final q = await _queue;
      state = state.copyWith(sending: true);
      while (force ||
          shouldUpload(
            queued: await q.count(),
            lastOk: state.lastOk,
            now: _now(),
            notBefore: _notBefore,
          )) {
        final batch = await q.peek(maxBatch);
        if (batch.isEmpty) break;
        final r = await ref
            .read(ingestClientProvider)
            .send(token.token, batch, deviceIdForPlatform);
        if (r == IngestResult.ok) {
          await q.commit(batch.length);
          _failures = 0;
          _notBefore = null;
          state = state.copyWith(lastOk: _now());
        } else if (r == IngestResult.rejected) {
          await q.reject(batch.length);
        } else if (r == IngestResult.unauthorized) {
          state = state.copyWith(problem: TrackerProblem.badToken);
          break;
        } else {
          _failures++;
          _notBefore = _now().add(backoff(_failures));
          break;
        }
      }
    } finally {
      _uploading = false;
      state = state.copyWith(sending: false);
      await _refresh();
    }
  }
}

final trackerControllerProvider =
    NotifierProvider<TrackerController, TrackerState>(TrackerController.new);
