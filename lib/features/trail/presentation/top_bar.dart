import 'package:findme/core/time/format.dart';
import 'package:findme/core/widgets/card_box.dart';
import 'package:findme/core/widgets/pill.dart';
import 'package:findme/features/auth/presentation/auth_controller.dart';
import 'package:findme/features/trail/presentation/date_filter.dart';
import 'package:findme/features/trail/presentation/trail_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Brand, "👀 x phút trước", share, friends, sign out, the date filter and the status line (the web's top bar).
class TopBar extends ConsumerWidget {
  const TopBar({
    required this.onShare,
    required this.onFriends,
    required this.incomingCount,
    super.key,
  });

  final VoidCallback onShare;
  final VoidCallback onFriends;
  final int incomingCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(trailControllerProvider);
    final ctl = ref.read(trailControllerProvider.notifier);
    final now = ref.watch(nowProvider);
    final last = s.track.last;
    return CardBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  '📍 Find Me',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                ),
              ),
              if (last != null)
                Pill(
                  label: '👀 ${ago(last.ts, now: now())}',
                  onTap: () =>
                      ref.read(flyToProvider.notifier).go(last.lon, last.lat),
                ),
              Pill(
                label: '🔗 Chia sẻ',
                semanticLabel: 'Chia sẻ vị trí',
                onTap: onShare,
              ),
              Pill(
                label: '👥',
                semanticLabel: incomingCount > 0
                    ? 'Bạn bè, $incomingCount lời mời'
                    : 'Bạn bè',
                badge: incomingCount,
                onTap: onFriends,
              ),
              Pill(
                label: '👋',
                style: PillStyle.ghost,
                semanticLabel: 'Đăng xuất',
                onTap: () =>
                    ref.read(authControllerProvider.notifier).signOut(),
              ),
            ],
          ),
          const SizedBox(height: 6),
          DateFilter(value: s.range, onChange: ctl.setRange, now: now),
          if (s.loading)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Notice('Đang lần theo dấu chân… 🐾'),
            ),
          if (s.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Notice(s.error!, error: true),
            ),
        ],
      ),
    );
  }
}
