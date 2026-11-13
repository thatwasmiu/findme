import 'dart:async';

import 'package:findme/core/errors/app_errors.dart';
import 'package:findme/core/widgets/card_box.dart';
import 'package:findme/core/widgets/pill.dart';
import 'package:findme/features/auth/presentation/auth_controller.dart';
import 'package:findme/features/bag/presentation/bag_editor.dart';
import 'package:findme/features/friends/data/friends_repository.dart';
import 'package:findme/features/friends/presentation/friends_controller.dart';
import 'package:findme/features/tracker/presentation/tracker_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 👤 Tài khoản (the web's AccountPanel.tsx): your bag and avatar, sign out, and delete the account for good
/// (App Store 5.1.1(v)).
class AccountSheet extends ConsumerStatefulWidget {
  const AccountSheet({super.key});

  static Future<void> open(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const AccountSheet(),
  );

  @override
  ConsumerState<AccountSheet> createState() => _AccountSheetState();
}

class _AccountSheetState extends ConsumerState<AccountSheet> {
  bool _busy = false;
  String _err = '';

  /// The typed name, or null when cancelled.
  Future<String?> _askName(String name) {
    // No controller: one disposed when the dialog closes is still read by its closing animation.
    var typed = '';
    return showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Xoá tài khoản sẽ xoá hết dấu chân, ảnh, túi đồ, bạn bè và link chia sẻ của bạn. Không lấy lại được.',
            ),
            const SizedBox(height: 12),
            Text('Gõ đúng tên "$name" để xoá:'),
            TextField(
              key: const Key('confirmName'),
              onChanged: (v) => typed = v,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Thôi'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, typed),
            child: const Text('Xoá'),
          ),
        ],
      ),
    );
  }

  Future<void> _delete(String name) async {
    final typed = await _askName(name);
    if (typed == null || !mounted) return;
    if (typed.trim() != name) {
      setState(() => _err = 'Tên chưa khớp, tài khoản vẫn còn nguyên.');
      return;
    }
    setState(() {
      _err = '';
      _busy = true;
    });
    final auth = ref.read(authControllerProvider.notifier);
    try {
      await ref.read(friendsRepositoryProvider).deleteMe();
      // A deliberate sign-out: also stops the tracker, which would otherwise keep uploading for a deleted account.
      await auth.signOut();
    } on AuthExpired {
      await auth.signOut(); // already gone
    } on AccountMissing {
      await auth.signOut(); // switched off: a delete that stopped halfway; it finishes on the next try
    } on Object catch (e) {
      if (mounted) {
        setState(
          () => _err = e is FriendError && e.code == 'owner'
              ? 'Tài khoản chủ không xoá được.'
              : 'Chưa xoá xong (nhiều dữ liệu quá), bấm xoá lại lần nữa nhé.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// "Luôn bật" / "Chỉ khi đi".
  Future<void> _mode({required bool trip}) async {
    setState(() {
      _err = '';
      _busy = true;
    });
    try {
      await ref.read(trackerControllerProvider.notifier).setMode(trip: trip);
    } on Object {
      if (mounted) setState(() => _err = 'Chưa đổi được, thử lại nhé.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(friendsControllerProvider.select((s) => s.me));
    final sharing = ref.watch(
      trackerControllerProvider.select((s) => s.sharing),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '👤 ${me?.name ?? 'Tài khoản'}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
              ),
              Pill(
                label: '✕',
                style: PillStyle.ghost,
                semanticLabel: 'Đóng',
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (me != null)
            Pill(
              label: '🎒 Túi của tôi & ảnh đại diện',
              style: PillStyle.lav,
              onTap: () => BagEditor.open(context),
            ),
          // Trip mode (travel-heatmap chapter 22): only once the server has said which mode this account is in.
          if (sharing != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Pill(
                  label: 'Luôn bật',
                  selected: sharing == 'always',
                  onTap: _busy || sharing == 'always'
                      ? null
                      : () => unawaited(_mode(trip: false)),
                ),
                const SizedBox(width: 6),
                Pill(
                  label: 'Chỉ khi đi',
                  selected: sharing == 'trip',
                  onTap: _busy || sharing == 'trip'
                      ? null
                      : () => unawaited(_mode(trip: true)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Notice(
              sharing == 'trip'
                  ? 'Chỉ ghi và chia sẻ khi bạn bắt đầu chuyến đi trong app Find Me.'
                  : 'Luôn ghi và chia sẻ vị trí.',
            ),
          ],
          const SizedBox(height: 8),
          Pill(
            label: '👋 Đăng xuất',
            onTap: () => ref.read(authControllerProvider.notifier).signOut(),
          ),
          const Divider(height: 24),
          if (me != null && me.owner)
            const Notice('Tài khoản chủ không xoá được.')
          else if (me != null) ...[
            Pill(
              label: _busy ? 'Đang xoá…' : '🗑️ Xoá tài khoản',
              onTap: _busy ? null : () => _delete(me.name),
            ),
            const SizedBox(height: 4),
            const Notice(
              'Xoá hết dấu chân, ảnh, bạn bè, link. Không hoàn tác được.',
            ),
          ],
          if (_err.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Notice(_err, error: true),
            ),
        ],
      ),
    );
  }
}
