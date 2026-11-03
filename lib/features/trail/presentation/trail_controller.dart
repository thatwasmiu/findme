import 'dart:async';

import 'package:findme/core/errors/app_errors.dart';
import 'package:findme/core/storage/prefs.dart';
import 'package:findme/features/auth/data/auth_repository.dart';
import 'package:findme/features/auth/data/session_store.dart';
import 'package:findme/features/auth/presentation/auth_controller.dart';
import 'package:findme/features/friends/presentation/friends_controller.dart';
import 'package:findme/features/trail/data/track_repository.dart';
import 'package:findme/features/trail/domain/date_range.dart';
import 'package:findme/features/trail/domain/models.dart';
import 'package:findme/features/trail/domain/trail_math.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The clock, replaceable in tests.
final nowProvider = Provider<DateTime Function()>((_) => DateTime.now);

/// One /track request a minute for you and your shown friends.
const pollMs = 60000;

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
/// once, then only the newest part every minute, together with your shown friends; paused in the background.
/// "Hôm nay" is also kept on the phone (Prefs.readToday), so reopening draws it at once and asks only for what is new.
class TrailController extends Notifier<TrailState> {
  int _seq = 0; // only the latest load may update state
  ({DateRange range, Track track})?
  _shown; // what is on the map, for which range
  DateRange? _renamed; // the range already given its one "pick up names" reload
  String? _who; // the account (token `sub`) today's kept trail belongs to
  Timer? _timer;
  Timer? _rename;
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
    _who = null;
    // A friend switched on (or off) the map, or the friend list came in: ask for them right away, not at the next tick.
    ref.listen(friendsControllerProvider.select((s) => s.shown.join(',')), (
      _,
      _,
    ) {
      if (signedIn) unawaited(load(quiet: true));
    });
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
      final now = _now;
      final to = liveTo(range, now: now);
      var prev = quiet && !full && _shown?.range == range ? _shown : null;
      // "Hôm nay" opened again today: draw what this phone kept and ask only for what came in since.
      final day = isoMs(midnightOf(now));
      final isToday = isLive(range, now: now) && range.from == day;
      if (isToday) {
        _who ??= subOf(
          await ref.read(authRepositoryProvider).getAccessToken() ?? '',
        );
      }
      final who = _who;
      if (prev == null && !full && isToday && who != null) {
        final saved = await ref.read(prefsProvider).readToday(who, day);
        if (!latest()) return;
        if (saved != null) {
          prev = (range: range, track: saved.mine);
          state = state.copyWith(track: saved.mine);
          _friends.restore(saved.friends);
        }
      }
      final from = prev == null ? range.from : tailFrom(prev.track, range.from);
      // One request for you and your shown friends; `have`: if your newest point is still this one, nothing is re-read.
      final asked = _friends.ask(now);
      final got = await ref
          .read(trackRepositoryProvider)
          .fetch(
            DateRange(from: from, to: to),
            have: prev?.track.last?.ts,
            friends: asked,
          );
      if (!latest()) return;
      final theirs = _friends.apply(got.friends, asked, now);
      final tr = prev == null
          ? got.track
          : got.unchanged
          ? prev.track.copyWith(last: got.track.last ?? prev.track.last)
          : mergeTail(prev.track, got.track, from);
      _shown = (range: range, track: tr);
      if (isToday && who != null) {
        unawaited(ref.read(prefsProvider).writeToday(who, day, tr, theirs));
      }
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
    _timer?.cancel();
    _timer = Timer.periodic(
      const Duration(milliseconds: pollMs),
      (_) => _tick(),
    );
  }

  void _tick() {
    if (_paused || !ref.mounted) return;
    if (isLive(state.range, now: _now)) {
      unawaited(load(quiet: true));
    } else {
      // A past range has nothing new to fetch, but "👀 x phút trước" must still move on.
      // ponytail: viewing a past range, shown friends are not refreshed either; pick today to follow them.
      state = state.copyWith(tick: state.tick + 1);
    }
  }

  /// The app went to the background: stop asking.
  void paused() => _paused = true;

  /// Back in the app: refresh right away.
  void resumed() {
    _paused = false;
    _tick();
  }

  FriendsController get _friends =>
      ref.read(friendsControllerProvider.notifier);
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
