import 'package:findme/core/time/format.dart';
import 'package:findme/core/widgets/card_box.dart';
import 'package:findme/core/widgets/pill.dart';
import 'package:findme/features/replay/presentation/replay_controller.dart';
import 'package:findme/features/trail/domain/trail_math.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Replay timeline (replaces the top bar while replaying): clock, play/pause, speed, a slider to scrub the day.
/// Also runs the replay clock, one step per frame.
class ReplayBar extends ConsumerStatefulWidget {
  const ReplayBar({super.key});

  @override
  ConsumerState<ReplayBar> createState() => _ReplayBarState();
}

class _ReplayBarState extends ConsumerState<ReplayBar>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _prev = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      final dt = (elapsed - _prev).inMicroseconds / 1000;
      _prev = elapsed;
      ref.read(replayControllerProvider.notifier).step(dt);
    })..start();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reduced motion (the web's prefers-reduced-motion): no animation, straight to the end.
    if (MediaQuery.of(context).disableAnimations) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => ref.read(replayControllerProvider.notifier).finish(),
      );
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(replayControllerProvider);
    if (s == null) return const SizedBox.shrink();
    final ctl = ref.read(replayControllerProvider.notifier);
    final pts = s.track;
    final n = pts.length - 1;
    // Several days in one replay: put the date in front of the time.
    final multi = dayMonth(pts.first.t) != dayMonth(pts[n].t);
    String when(num t) => multi ? '${dayMonth(t)} ${hhmmSec(t)}' : hhmmSec(t);
    return CardBox(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Pill(
                label: s.playing ? '⏸' : '▶️',
                style: PillStyle.on,
                semanticLabel: s.playing ? 'Tạm dừng' : 'Phát',
                onTap: ctl.toggle,
              ),
              const SizedBox(width: 8),
              Text(
                when(at(pts, s.pos).$3),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Notice('${when(pts.first.t)} – ${when(pts[n].t)}'),
              ),
              Pill(
                label:
                    '${s.speed.toString().replaceAll(RegExp(r'\.0$'), '').replaceAll('.', ',')}×',
                style: PillStyle.lav,
                semanticLabel: 'Tốc độ ${s.speed}×, bấm để đổi',
                onTap: ctl.cycleSpeed,
              ),
              Pill(
                label: '✕',
                style: PillStyle.ghost,
                semanticLabel: 'Đóng phát lại',
                onTap: ctl.stop,
              ),
            ],
          ),
          Semantics(
            label: 'Thời điểm phát lại',
            child: Slider(
              value: s.pos.clamp(0, n.toDouble()),
              max: n.toDouble(),
              onChanged: ctl.seek,
            ),
          ),
        ],
      ),
    );
  }
}
