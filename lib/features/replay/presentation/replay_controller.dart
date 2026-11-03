import 'package:findme/features/auth/presentation/auth_controller.dart';
import 'package:findme/features/replay/domain/replay_math.dart';
import 'package:findme/features/trail/domain/models.dart';
import 'package:findme/features/trail/domain/trail_math.dart';
import 'package:findme/features/trail/presentation/trail_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Replay together: everyone's day in about a minute at 1×.
const togetherMs = 60000;

class ReplayState {
  const ReplayState({
    required this.track,
    required this.totalMs,
    this.own = const [],
    this.clock = false,
    this.pos = 0,
    this.playing = true,
    this.speed = 1,
  });

  /// What the bar plays: your prints, or (by the clock) a two-point track whose times are the span.
  final List<TrackPoint> track;

  /// By the clock: your trail as it was when ▶️ was pressed (the refresh must not restart the walker).
  final List<TrackPoint> own;
  final bool clock;

  /// Fractional index into [track].
  final double pos;
  final bool playing;
  final double speed;
  final int totalMs;

  /// The clock time (epoch s) when replaying together.
  double get clockAt => at(track, pos).$3;

  ReplayState copyWith({double? pos, bool? playing, double? speed}) =>
      ReplayState(
        track: track,
        totalMs: totalMs,
        own: own,
        clock: clock,
        pos: pos ?? this.pos,
        playing: playing ?? this.playing,
        speed: speed ?? this.speed,
      );
}

/// Replay state + clock (port of the web's useReplay and replayAll). null = not replaying.
class ReplayController extends Notifier<ReplayState?> {
  @override
  ReplayState? build() {
    ref
      ..watch(
        signedInProvider,
      ) // signed out: drop the replay and its frozen trail
      ..listen(
        trailControllerProvider.select((s) => s.range),
        (_, _) => stop(),
      );
    return null;
  }

  /// Alone, print by print. With friends' prints and a range reaching today: everyone together by the clock.
  void start(
    List<TrackPoint> own, {
    List<List<TrackPoint>> others = const [],
    bool live = false,
  }) {
    final span = live ? togetherSpan(own, others) : null;
    state = span == null
        ? ReplayState(track: List.of(own), totalMs: replayMs(own.length))
        : ReplayState(
            track: [TrackPoint(0, 0, span.$1), TrackPoint(0, 0, span.$2)],
            totalMs: togetherMs,
            own: List.of(own),
            clock: true,
          );
  }

  void stop() => state = null;

  /// One frame of the clock ([dtMs] since the last one).
  void step(double dtMs) {
    final s = state;
    if (s == null || !s.playing) return;
    final n = s.track.length - 1;
    final pos = advance(s.pos, dtMs, s.speed, s.totalMs.toDouble(), n);
    state = s.copyWith(pos: pos, playing: pos < n);
  }

  /// Jump to the end (reduced motion).
  void finish() {
    final s = state;
    if (s != null) {
      state = s.copyWith(pos: (s.track.length - 1).toDouble(), playing: false);
    }
  }

  void toggle() {
    final s = state;
    if (s == null) return;
    final atEnd = s.pos >= s.track.length - 1;
    state = s.copyWith(
      pos: !s.playing && atEnd ? 0 : null,
      playing: !s.playing,
    ); // at the end: ▶️ starts over
  }

  void seek(double pos) => state = state?.copyWith(pos: pos, playing: false);

  void cycleSpeed() => state = state?.copyWith(speed: nextSpeed(state!.speed));
}

final replayControllerProvider =
    NotifierProvider<ReplayController, ReplayState?>(ReplayController.new);
