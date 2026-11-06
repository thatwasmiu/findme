import 'dart:async';

import 'package:findme/core/errors/app_errors.dart';
import 'package:findme/features/auth/data/auth_repository.dart';
import 'package:findme/features/auth/data/session_store.dart';
import 'package:findme/features/auth/presentation/auth_controller.dart';
import 'package:findme/features/tracker/data/ingest_client.dart';
import 'package:findme/features/tracker/data/point_queue.dart';
import 'package:findme/features/tracker/data/tracker_store.dart';
import 'package:findme/features/tracker/data/wake_channel.dart';
import 'package:findme/features/tracker/domain/fix.dart';
import 'package:findme/features/tracker/domain/location_source.dart';
import 'package:findme/features/tracker/domain/upload_policy.dart';
import 'package:findme/features/tracker/domain/upload_policy.dart'
    as policy
    show uploadEvery;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What the status line says is wrong, if anything. needAlways wins over token problems.
/// noToken: none yet (signed out, offline…); badToken: even a fresh one was refused; noAccount: the server will not
/// give this login one (403), asked again only by "Gửi ngay" or the switch.
enum TrackerProblem { none, noToken, badToken, noAccount, needAlways }

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
    this.indicator = false,
    this.uploadEvery = policy.uploadEvery,
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

  /// iPhone shows its blue location indicator while recording.
  final bool indicator;

  /// Chosen wait between uploads.
  final Duration uploadEvery;

  TrackerState copyWith({
    bool? on,
    TrackerProblem? problem,
    int? queued,
    int? rejected,
    DateTime? lastOk,
    DateTime? lastFix,
    bool? sending,
    bool? indicator,
    Duration? uploadEvery,
  }) => TrackerState(
    on: on ?? this.on,
    problem: problem ?? this.problem,
    queued: queued ?? this.queued,
    rejected: rejected ?? this.rejected,
    lastOk: lastOk ?? this.lastOk,
    lastFix: lastFix ?? this.lastFix,
    sending: sending ?? this.sending,
    indicator: indicator ?? this.indicator,
    uploadEvery: uploadEvery ?? this.uploadEvery,
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

  /// The "Hiện chỉ báo vị trí" switch: saved; a running GPS stream restarts with it.
  Future<void> setIndicator({required bool on}) async {
    await _store.setIndicator(on: on);
    state = state.copyWith(indicator: on);
    await wake();
  }

  /// The "Gửi mỗi" choice: saved; what waits goes now if it is already due.
  Future<void> setUploadEvery(Duration d) async {
    await _store.setUploadEvery(d);
    state = state.copyWith(uploadEvery: d);
    if (_tick != null) {
      _tick!.cancel();
      _tick = Timer.periodic(d, (_) => unawaited(_upload()));
    }
    await _upload();
  }

  /// At app start (also a background relaunch): carry on if tracking was left on.
  Future<void> resume() async {
    await _refresh();
    state = state.copyWith(
      indicator: await _store.indicator(),
      uploadEvery: await _store.uploadEvery(),
    );
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
    state = state.copyWith(uploadEvery: await _store.uploadEvery());
    // Whose points these are, even before a token is pasted: another account signing in ends them (AuthController).
    final access = await ref.read(authRepositoryProvider).getAccessToken();
    final sub = subOf(access ?? '');
    if (sub != null) await _store.setOwner(sub);
    if (state.problem == TrackerProblem.noAccount) {
      state = state.copyWith(problem: TrackerProblem.none);
    }
    await _start();
    await _upload(); // fetches the ingest token now, not at the first fix
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
    final indicator = await _store.indicator();
    // Checked again after the await, so two starts at once never subscribe twice.
    _fixes ??= _gps
        .fixes(indicator: indicator)
        .listen(
          _onFix,
          onError: (Object _) => state = state.copyWith(
            on: false,
            problem: TrackerProblem.needAlways,
          ),
        );
    // Standing still sends no fixes; this still uploads what waits once "Gửi mỗi" is up.
    _tick ??= Timer.periodic(state.uploadEvery, (_) => unawaited(_upload()));
    await ref.read(wakeChannelProvider).start();
    final token = await _readToken();
    state = state.copyWith(
      on: true,
      problem: token != null || _locked
          ? TrackerProblem.none
          : state.problem == TrackerProblem.noAccount
          ? null
          : TrackerProblem.noToken,
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

  void _failed() {
    _failures++;
    _notBefore = _now().add(backoff(_failures));
  }

  /// True after the last token read failed (locked iPhone): that is not "no token".
  bool _locked = false;

  Future<IngestToken?> _readToken() async {
    try {
      final t = await _store.token();
      _locked = false;
      return t;
    } on StorageUnreadable {
      _locked = true;
      return null;
    }
  }

  /// Asks the server for this account's ingest token and keeps it (the old one stops working). null: none now,
  /// [TrackerState.problem] says why.
  Future<String?> _issue() async {
    final keep = state.problem == TrackerProblem.needAlways;
    try {
      final sub = subOf(
        await ref.read(authRepositoryProvider).getAccessToken() ?? '',
      );
      final owner = await _store.owner();
      // Signed out, or someone else signed in (their points must never go out under this account's token, nor
      // these under theirs): wait for this account's sign-in.
      if (sub == null || (owner != null && owner != sub)) {
        if (!keep) state = state.copyWith(problem: TrackerProblem.noToken);
        return null;
      }
      final t = await ref.read(ingestClientProvider).newToken();
      await _store.saveToken(t, sub);
      if (!keep) state = state.copyWith(problem: TrackerProblem.none);
      return t;
    } on AccountMissing {
      if (!keep) state = state.copyWith(problem: TrackerProblem.noAccount);
    } on AuthExpired {
      if (!keep) state = state.copyWith(problem: TrackerProblem.noToken);
      if (ref.read(signedInProvider)) {
        ref.read(authControllerProvider.notifier).expired();
      }
    } on AppError {
      // offline, 429 (too many new tokens), 5xx: try again after the backoff
      if (!keep && state.problem != TrackerProblem.badToken) {
        state = state.copyWith(problem: TrackerProblem.noToken);
      }
      _failed();
    }
    return null;
  }

  /// One upload run at a time; [force] = "Gửi ngay": ignore the thresholds and the backoff, send everything.
  Future<void> _upload({bool force = false}) {
    if (_uploading) return Future.value();
    _uploading = true;
    return _running = _uploadRun(force: force);
  }

  Future<void> _uploadRun({required bool force}) async {
    try {
      if (state.problem == TrackerProblem.noAccount && !force) return;
      var token = (await _readToken())?.token;
      if (_locked) return; // Keychain locked: the token is there, just not readable yet; next tick tries again
      var fresh = false;
      if (token == null || state.problem == TrackerProblem.badToken) {
        if (!force && _notBefore != null && _now().isBefore(_notBefore!)) {
          return;
        }
        token = await _issue();
        if (token == null) return;
        fresh = true;
      }
      final q = await _queue;
      state = state.copyWith(sending: true);
      while (force ||
          shouldUpload(
            queued: await q.count(),
            lastOk: state.lastOk,
            now: _now(),
            notBefore: _notBefore,
            every: state.uploadEvery,
          )) {
        final batch = await q.peek(maxBatch);
        if (batch.isEmpty) break;
        final r = await ref
            .read(ingestClientProvider)
            .send(token!, batch, deviceIdForPlatform);
        if (r == IngestResult.ok) {
          await q.commit(batch.length);
          _failures = 0;
          _notBefore = null;
          state = state.copyWith(lastOk: _now());
        } else if (r == IngestResult.rejected) {
          await q.reject(batch.length);
        } else if (r == IngestResult.unauthorized) {
          // Rotated elsewhere (another phone asked for one): ask once more; a fresh token refused is a real problem.
          if (fresh) {
            state = state.copyWith(problem: TrackerProblem.badToken);
            _failed();
            break;
          }
          token = await _issue();
          if (token == null) break;
          fresh = true;
        } else {
          _failed();
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
