import 'dart:async';

import 'package:findme/core/theme/palette.dart';
import 'package:findme/core/time/format.dart';
import 'package:findme/core/widgets/card_box.dart';
import 'package:findme/core/widgets/pill.dart';
import 'package:findme/features/tracker/domain/location_source.dart';
import 'package:findme/features/tracker/domain/upload_policy.dart';
import 'package:findme/features/tracker/presentation/tracker_controller.dart';
import 'package:findme/features/trail/presentation/trail_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Google Play's "prominent disclosure": shown once, before the first location prompt.
const _disclosureKey = 'findme.trackerDisclosure';
const _disclosure =
    'Find Me sẽ ghi lại vị trí của bạn ở chế độ nền, kể cả khi bạn đóng ứng dụng. '
    'Vị trí được gửi về máy chủ Find Me để vẽ hành trình của bạn, và chỉ hiện cho bạn bè '
    'cùng những link chia sẻ mà bạn chọn. Bạn có thể tắt bất cứ lúc nào.';

/// 📍 Ghi hành trình: the switch and what the tracker is doing. The ingest token is fetched by the controller.
class TrackerSheet extends ConsumerStatefulWidget {
  const TrackerSheet({super.key});

  static Future<void> open(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) =>
        const FractionallySizedBox(heightFactor: 0.75, child: TrackerSheet()),
  );

  @override
  ConsumerState<TrackerSheet> createState() => _TrackerSheetState();
}

class _TrackerSheetState extends ConsumerState<TrackerSheet> {
  Future<void> _switch({required bool on}) async {
    final ctl = ref.read(trackerControllerProvider.notifier);
    if (!on) {
      await ctl.turnOff();
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(_disclosureKey) ?? false)) {
      if (!mounted) return;
      final ok = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Ghi hành trình'),
          content: const Text(_disclosure),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Không'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Đồng ý'),
            ),
          ],
        ),
      );
      if (ok != true) return;
      await prefs.setBool(_disclosureKey, true);
    }
    await ctl.turnOn();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(trackerControllerProvider);
    final ctl = ref.read(trackerControllerProvider.notifier);
    final now = ref.watch(nowProvider)();
    String when(DateTime? t) =>
        t == null ? 'chưa' : ago(t.toIso8601String(), now: now);
    final openSettings = ref.read(locationSourceProvider).openSettings;
    final (status, bad) = switch (s.problem) {
      TrackerProblem.needAlways => ('Thiếu quyền vị trí "Luôn luôn"', true),
      TrackerProblem.badToken => ('Token sai hoặc đã đổi', true),
      TrackerProblem.noToken => ('Chưa có token', true),
      TrackerProblem.noAccount => (
        'Tài khoản này không ghi được hành trình',
        true,
      ),
      TrackerProblem.none => (s.on ? 'Đang ghi' : 'Đã tắt', false),
    };
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: ListView(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  '📍 Ghi hành trình',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                ),
              ),
              Switch(
                value: s.on,
                activeThumbColor: Palette.pink,
                onChanged: (v) => unawaited(_switch(on: v)),
              ),
            ],
          ),
          Notice(status, error: bad),
          if (defaultTargetPlatform == TargetPlatform.iOS)
            Row(
              children: [
                const Expanded(child: Text('Hiện chỉ báo vị trí')),
                Switch(
                  key: const Key('indicator'),
                  value: s.indicator,
                  activeThumbColor: Palette.pink,
                  onChanged: (v) => unawaited(ctl.setIndicator(on: v)),
                ),
              ],
            ),
          if (s.problem == TrackerProblem.needAlways)
            Align(
              alignment: Alignment.centerLeft,
              child: Pill(
                label: 'Mở cài đặt',
                onTap: () => unawaited(openSettings()),
              ),
            ),
          const SizedBox(height: 8),
          Text('Điểm chờ gửi: ${s.queued}'),
          Text('Gửi lần cuối: ${when(s.lastOk)}'),
          Text('Điểm cuối: ${when(s.lastFix)}'),
          if (s.rejected > 0)
            Notice('Điểm bị từ chối: ${s.rejected}', error: true),
          const SizedBox(height: 8),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text('Gửi mỗi'),
              for (final d in uploadChoices)
                Pill(
                  label: d.inSeconds < 60
                      ? '${d.inSeconds} giây'
                      : '${d.inMinutes} phút',
                  selected: s.uploadEvery == d,
                  onTap: () => unawaited(ctl.setUploadEvery(d)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Pill(
              label: 'Gửi ngay',
              style: PillStyle.on,
              onTap: s.sending ? null : () => unawaited(ctl.sendNow()),
            ),
          ),
          if (defaultTargetPlatform == TargetPlatform.android) ...[
            const SizedBox(height: 16),
            const Notice(
              'Nếu máy hay tắt ứng dụng, hãy tắt tối ưu pin cho Find Me.',
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Pill(
                label: 'Mở cài đặt',
                onTap: () => unawaited(openSettings()),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
