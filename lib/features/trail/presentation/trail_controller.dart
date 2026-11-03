import 'dart:async';
import 'dart:math';

import 'package:findme/core/errors/app_errors.dart';
import 'package:findme/features/auth/presentation/auth_controller.dart';
import 'package:findme/features/trail/data/track_repository.dart';
import 'package:findme/features/trail/domain/date_range.dart';
import 'package:findme/features/trail/domain/models.dart';
import 'package:findme/features/trail/domain/trail_math.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The clock, replaceable in tests.
final nowProvider = Provider<DateTime Function()>((_) => DateTime.now);

const pollMs = 7000;

/// Nothing new for a while (Overland uploads in batches): ask less often, down to this.
const idlePollMs = 60000;

/// After a load with unnamed stops: one full reload to pick up their names.
const renameMs = 20000;

class TrailState {
  const TrailState({
    required this.range,
    this.track = Track.empty,
    this.loading = false,
    this.error,
    this.tick = 0,
  });

  final DateRange range;
  final Track track;
  final bool loading;
  final String? error;

  /// Bumped on every refresh tick, so "👀 x phút trước" re-renders even when nothing was fetched.
  final int tick;

  TrailState copyWith({
    DateRange? range,
    Track? track,
    bool? loading,
    String? Function()? error,
    int? tick,
  }) => TrailState(
    range: range ?? this.range,
    track: track ?? this.track,
    loading: loading ?? this.loading,
    error: error == null ? this.error : error(),
    tick: tick ?? this.tick,
  );
}

/// Your trail for the chosen range, kept fresh (port of the load/poll logic in the web's App.tsx): the whole range
/// once, then only the newest part every 7 s, backing off to 60 s while nothing changes; paused in the background.
class TrailController extends Notifier<TrailState> {
  int _seq = 0; // only the latest load may update state
  ({DateRange range, Track track})?
  _shown; // what is on the map, for which range
  DateRange? _renamed; // the range already given its one "pick up names" reload
  Timer? _timer;
  Timer? _rename;
  int _delay = pollMs;
  bool _busy = false;
  bool _paused = false;

  DateTime get _now => ref.read(nowProvider)();

  @override
  TrailState build() {
    final signedIn = ref.watch(
      signedInProvider,
    ); // signing out rebuilds this empty
    ref.onDispose(() {
      _timer?.cancel();
      _rename?.cancel();
    });
    _shown = null;
    _renamed = null;
    final initial = TrailState(range: presetRange(Preset.today, _now));
    if (signedIn) {
      unawaited(
        Future.microtask(() {
          unawaited(load());
          _restartPolling();
        }),
      );
    }
    return initial;
  }

  void setRange(DateRange r) {
    state = state.copyWith(range: r);
    unawaited(load());
    _restartPolling();
  }

  /// [quiet]: a background refresh: no spinner, no error banner. [full]: the whole range, not only the newest part.
  Future<void> load({bool quiet = false, bool full = false}) async {
    final mine = ++_seq;
    bool latest() => mine == _seq;
    final range = state.range;
    if (!quiet) state = state.copyWith(loading: true);
    try {
      // "Hôm nay" / "7 ngày"… end when they were picked: stretch them to now so new prints show up.
      final to = liveTo(range, now: _now);
      final prev = quiet && !full && _shown?.range == range ? _shown : null;
      final from = prev == null ? range.from : tailFrom(prev.track, range.from);
      final got = await ref
          .read(trackRepositoryProvider)
          .fetch(DateRange(from: from, to: to));
      if (!latest()) return;
      final tr = prev == null ? got : mergeTail(prev.track, got, from);
      _shown = (range: range, track: tr);
      state = state.copyWith(track: tr, error: () => null);
      // Stop names come from a slow lookup on the server and refreshes fetch only the newest part, so older
      // unnamed stops would never get theirs: one full reload a little later picks them up (the web's RENAME_MS).
      if (prev == null &&
          _renamed != range &&
          tr.stops.any((s) => s.name == null)) {
        _renamed = range;
        _rename?.cancel();
        _rename = Timer(const Duration(milliseconds: renameMs), () {
          if (ref.mounted && _shown?.range == range) {
            unawaited(load(quiet: true, full: true));
          }
        });
      }
    } on AuthExpired {
      if (latest()) ref.read(authControllerProvider.notifier).expired();
    } on AccountMissing {
      if (latest()) ref.read(authControllerProvider.notifier).noAccount();
    } on Object catch (e) {
      if (latest() && !quiet) {
        state = state.copyWith(
          error: () => e is HttpError && e.status == 400
              ? 'Chọn tối đa 31 ngày một lần nhé 📅'
              : 'Chưa tải được dấu chân — thử lại sau chút nhé ✨',
        );
      }
    } finally {
      if (latest() && ref.mounted) state = state.copyWith(loading: false);
    }
  }

  void _restartPolling() {
    _delay = pollMs;
    _schedule();
  }

  void _schedule() {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: _delay), _tick);
  }

  Future<void> _tick() async {
    if (_busy || !ref.mounted) return; // the one running schedules the next
    _busy = true;
    _timer?.cancel();
    if (!_paused) {
      if (!isLive(state.range, now: _now)) {
        state = state.copyWith(tick: state.tick + 1);
      } else {
        final before = _shown?.track.last?.ts;
        final seq = _seq;
        await load(quiet: true);
        if (!ref.mounted) return;
        // A new range was picked meanwhile: setRange already restarted the 7 s rhythm.
        if (_seq != seq + 1) {
          _busy = false;
          return;
        }
        // Nothing new: wait twice as long next time (7 s → 14 s → … → 60 s); new prints: back to 7 s.
        _delay = _shown?.track.last?.ts == before
            ? min(idlePollMs, _delay * 2)
            : pollMs;
      }
    }
    _busy = false;
    if (ref.read(signedInProvider)) _schedule();
  }

  /// The app went to the background: stop asking.
  void paused() => _paused = true;

  /// Back in the app: refresh right away, and quickly again.
  void resumed() {
    _paused = false;
    _delay = pollMs;
    unawaited(_tick());
  }
}

final trailControllerProvider = NotifierProvider<TrailController, TrailState>(
  TrailController.new,
);

/// Where the map should fly next (lon, lat); the 👀 pill and the trail sheet rows set it.
class FlyTo extends Notifier<(double, double)?> {
  @override
  (double, double)? build() {
    ref.watch(
      signedInProvider,
    ); // forgotten on sign-out like the rest of the account
    return null;
  }

  void go(double lon, double lat) => state = (lon, lat);
}

final flyToProvider = NotifierProvider<FlyTo, (double, double)?>(FlyTo.new);
