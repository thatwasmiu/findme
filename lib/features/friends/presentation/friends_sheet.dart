import 'dart:async';

import 'package:findme/core/errors/app_errors.dart';
import 'package:findme/core/time/format.dart';
import 'package:findme/core/widgets/card_box.dart';
import 'package:findme/core/widgets/pill.dart';
import 'package:findme/features/auth/presentation/auth_controller.dart';
import 'package:findme/features/friends/presentation/friends_controller.dart';
import 'package:findme/features/trail/presentation/trail_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _why = {
  'code': 'Không tìm thấy mã này.',
  'self': 'Đây là mã của bạn mà 😄',
  'already': 'Hai bạn đã là bạn bè rồi.',
  'pending': 'Đã gửi lời mời rồi, chờ bạn ấy nhé.',
};

/// 👥 Bạn bè (the web's FriendsPanel.tsx): your code, send a request, answer requests, show friends on the map.
class FriendsSheet extends ConsumerStatefulWidget {
  const FriendsSheet({super.key});

  static Future<void> open(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) =>
        const FractionallySizedBox(heightFactor: 0.85, child: FriendsSheet()),
  );

  @override
  ConsumerState<FriendsSheet> createState() => _FriendsSheetState();
}

class _FriendsSheetState extends ConsumerState<FriendsSheet> {
  final _code = TextEditingController();
  bool _busy = false;
  String _err = '';
  String _note = '';

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  /// Runs one change; [fn] may return its own message instead of [done].
  Future<void> _act(Future<Object?> Function() fn, String done) async {
    setState(() {
      _err = '';
      _note = '';
      _busy = true;
    });
    try {
      final said = await fn();
      if (mounted) setState(() => _note = said is String ? said : done);
    } on AuthExpired {
      ref.read(authControllerProvider.notifier).expired();
    } on AccountMissing {
      ref.read(authControllerProvider.notifier).noAccount();
    } on Object catch (e) {
      if (mounted) {
        setState(
          () => _err = e is FriendError
              ? (_why[e.code] ?? 'Không làm được, thử lại nhé.')
              : 'Không kết nối được, thử lại sau chút nhé ✨',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _confirm(String text) async =>
      await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          content: Text(text),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Thôi'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Xoá'),
            ),
          ],
        ),
      ) ??
      false;

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(friendsControllerProvider);
    final ctl = ref.read(friendsControllerProvider.notifier);
    final now = ref.watch(nowProvider);
    final rel = s.relations;
    const bold = TextStyle(fontWeight: FontWeight.w700);
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
                  '👥 Bạn bè',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                ),
              ),
              Pill(
                label: '✕',
                style: PillStyle.ghost,
                semanticLabel: 'Đóng',
                onTap: () => Navigator.maybePop(context),
              ),
            ],
          ),
          if (s.me != null)
            Row(
              children: [
                const Notice('Mã của bạn  '),
                SelectableText(
                  s.me!.friendCode,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 8),
                Pill(
                  label: 'Sao chép',
                  onTap: () async {
                    await Clipboard.setData(
                      ClipboardData(text: s.me!.friendCode),
                    );
                    setState(() => _note = 'Đã sao chép mã của bạn.');
                  },
                ),
              ],
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const Key('code'),
                  controller: _code,
                  textCapitalization: TextCapitalization.characters,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    hintText: 'Nhập mã của bạn ấy (vd: K7QM-3XPA)',
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Pill(
                label: 'Gửi lời mời',
                style: PillStyle.on,
                onTap: _busy
                    ? null
                    : () {
                        if (_code.text.trim().isEmpty) return;
                        unawaited(
                          _act(() async {
                            final note = await ctl.send(_code.text);
                            _code.clear();
                            return note;
                          }, 'Đã gửi lời mời 💌'),
                        );
                      },
              ),
            ],
          ),
          if (_err.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Notice(_err, error: true),
            ),
          if (_note.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Notice(_note),
            ),
          if (rel.incoming.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('Lời mời đến', style: bold),
            for (final r in rel.incoming)
              _Row(
                title: r.name,
                subtitle: 'muốn làm bạn với bạn',
                actions: [
                  Pill(
                    label: 'Đồng ý',
                    style: PillStyle.on,
                    onTap: _busy
                        ? null
                        : () => _act(
                            () => ctl.answer(r.id, accept: true),
                            'Bạn và ${r.name} đã là bạn bè 🎉',
                          ),
                  ),
                  Pill(
                    label: 'Từ chối',
                    style: PillStyle.ghost,
                    onTap: _busy
                        ? null
                        : () => _act(
                            () => ctl.answer(r.id, accept: false),
                            'Đã từ chối.',
                          ),
                  ),
                ],
              ),
          ],
          const SizedBox(height: 12),
          Text('Bạn bè (${rel.friends.length})', style: bold),
          for (final f in rel.friends)
            _Row(
              title: f.name,
              subtitle: f.lastTs != null
                  ? 'thấy ${ago(f.lastTs!, now: now())}'
                  : 'chưa thấy hôm nay',
              actions: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value: s.shownIds.contains(f.id),
                      onChanged: (_) => ctl.toggle(f.id),
                    ),
                    const Text('Hiện trên bản đồ'),
                  ],
                ),
                Pill(
                  label: 'Xoá bạn',
                  style: PillStyle.ghost,
                  onTap: _busy
                      ? null
                      : () async {
                          if (await _confirm(
                            'Xoá ${f.name} khỏi bạn bè? Hai bạn sẽ không thấy nhau nữa.',
                          )) {
                            await _act(
                              () => ctl.remove(f.id),
                              'Đã xoá ${f.name}.',
                            );
                          }
                        },
                ),
              ],
            ),
          if (rel.friends.isEmpty)
            const Notice('Chưa có bạn nào. Gửi mã của bạn cho người thân nhé.'),
          if (rel.outgoing.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('Đang chờ', style: bold),
            for (final r in rel.outgoing)
              _Row(
                title: r.name,
                subtitle: 'chưa trả lời',
                actions: [
                  Pill(
                    label: 'Huỷ',
                    style: PillStyle.ghost,
                    onTap: _busy
                        ? null
                        : () => _act(() => ctl.remove(r.id), 'Đã huỷ lời mời.'),
                  ),
                ],
              ),
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.title,
    required this.subtitle,
    required this.actions,
  });

  final String title;
  final String subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: CardBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          Notice(subtitle),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: actions,
          ),
        ],
      ),
    ),
  );
}
