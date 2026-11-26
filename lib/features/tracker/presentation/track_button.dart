import 'dart:async';

import 'package:findme/core/theme/palette.dart';
import 'package:findme/core/widgets/pill.dart';
import 'package:findme/features/tracker/domain/trip.dart';
import 'package:findme/features/tracker/presentation/tracker_controller.dart';
import 'package:findme/features/tracker/presentation/tracker_sheet.dart';
import 'package:findme/features/trail/presentation/trail_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The map's round start/stop button (above 📷) and its status chip. Always on: ▶ turns recording on, ■ off.
/// Trip mode: ▶ picks a preset and starts a trip, ■ ends it. The chip (or a long press) opens the full sheet.
class TrackButton extends ConsumerStatefulWidget {
  const TrackButton({super.key});

  @override
  ConsumerState<TrackButton> createState() => _TrackButtonState();
}

class _TrackButtonState extends ConsumerState<TrackButton> {
  /// Keeps "còn 42 phút" moving.
  late final Timer _clock;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(
      const Duration(seconds: 30),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _clock.cancel();
    super.dispose();
  }

  Future<void> _tap(TrackerState s) async {
    final ctl = ref.read(trackerControllerProvider.notifier);
    unawaited(HapticFeedback.selectionClick());
    if (s.on) return await _run(s.tripMode ? ctl.endTrip : ctl.turnOff);
    final p = s.tripMode ? await _pickPreset() : null;
    if (s.tripMode && p == null) return;
    if (!mounted || !await trackerDisclosed(context)) return;
    await _run(p == null ? ctl.turnOn : () => ctl.startTrip(p));
  }

  /// Spinner only while the controller works (GPS prompt, server), not while a sheet or dialog is open.
  Future<void> _run(Future<void> Function() work) async {
    setState(() => _busy = true);
    try {
      await work();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<TripPreset?> _pickPreset() => showModalBottomSheet<TripPreset>(
    context: context,
    builder: (c) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bắt đầu chuyến đi',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final p in TripPreset.values)
                  Pill(
                    label: p.label,
                    style: PillStyle.lav,
                    onTap: () => Navigator.pop(c, p),
                  ),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(trackerControllerProvider);
    final (status, bad) = trackerStatus(s, ref.watch(nowProvider)());
    final action = s.tripMode
        ? (s.on ? 'Kết thúc chuyến đi' : 'Bắt đầu chuyến đi')
        : (s.on ? 'Dừng ghi hành trình' : 'Bắt đầu ghi hành trình');
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Off and fine: the chip names what the button does, so a first-timer knows.
        _Chip(
          text: s.on || bad ? status : 'Ghi hành trình',
          live: s.on && !bad,
          bad: bad,
          onTap: () => TrackerSheet.open(context),
        ),
        const SizedBox(width: 8),
        Semantics(
          button: true,
          label: action,
          excludeSemantics: true,
          child: Material(
            color: s.on ? Palette.pink : Colors.white,
            shape: const CircleBorder(),
            elevation: 4,
            shadowColor: Palette.pink,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _busy ? null : () => unawaited(_tap(s)),
              onLongPress: () => TrackerSheet.open(context),
              child: SizedBox.square(
                dimension: 56,
                child: _busy
                    ? Padding(
                        padding: const EdgeInsets.all(18),
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: s.on ? Colors.white : Palette.pink,
                        ),
                      )
                    : Icon(
                        s.on ? Icons.stop_rounded : Icons.play_arrow_rounded,
                        size: 32,
                        color: s.on ? Colors.white : Palette.pink,
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// White rounded status label; a pink dot while recording, red text on a problem.
class _Chip extends StatelessWidget {
  const _Chip({
    required this.text,
    required this.live,
    required this.bad,
    required this.onTap,
  });

  final String text;
  final bool live;
  final bool bad;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Palette.card,
    shape: const StadiumBorder(),
    elevation: 2,
    shadowColor: Palette.shadow,
    child: InkWell(
      customBorder: const StadiumBorder(),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (live) ...[
              const DecoratedBox(
                decoration: BoxDecoration(
                  color: Palette.pink,
                  shape: BoxShape.circle,
                ),
                child: SizedBox.square(dimension: 8),
              ),
              const SizedBox(width: 6),
            ],
            if (bad) ...[
              const Text('⚠️', style: TextStyle(fontSize: 12)),
              const SizedBox(width: 4),
            ],
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 200),
              child: Text(
                text,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: bad
                      ? Palette.error
                      : live
                      ? Palette.ink
                      : Palette.muted,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
