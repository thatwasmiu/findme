import 'dart:async';

import 'package:findme/core/config/app_config.dart';
import 'package:findme/core/errors/app_errors.dart';
import 'package:findme/core/theme/palette.dart';
import 'package:findme/core/time/format.dart';
import 'package:findme/core/widgets/card_box.dart';
import 'package:findme/core/widgets/pill.dart';
import 'package:findme/features/auth/presentation/auth_controller.dart';
import 'package:findme/features/shares/data/shares_repository.dart';
import 'package:findme/features/shares/domain/share.dart';
import 'package:findme/features/trail/domain/date_range.dart';
import 'package:findme/features/trail/presentation/trail_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart' show ShareParams, SharePlus;

/// The link the recipient opens: the web share page.
String shareLink(AppConfig cfg, String id) => '${cfg.web}/s/$id';

/// Opens the system share sheet; replaceable in tests.
final shareLauncherProvider =
    Provider<Future<void> Function(String text, String url)>(
      (_) => (text, url) async {
        await SharePlus.instance.share(
          ShareParams(title: 'Find Me', text: '$text\n$url'),
        );
      },
    );

const _hour = Duration(hours: 1);
const _presets = <String, (String, Duration)>{
  '1h': ('1 giờ', _hour),
  '1d': ('1 ngày', Duration(days: 1)),
  '7d': ('7 ngày', Duration(days: 7)),
};
const _invalid = {
  'label': 'Tên cần từ 1 đến 40 ký tự nhé.',
  'expiresAt': 'Hạn dùng phải ở tương lai và tối đa 365 ngày.',
  'routeFrom': 'Ngày bắt đầu đường đi phải là hôm nay hoặc trước đó.',
};

/// 🔗 Chia sẻ vị trí (the web's SharePanel.tsx): create, copy, send, extend, route on/off, revoke.
class SharesSheet extends ConsumerStatefulWidget {
  const SharesSheet({super.key});

  static Future<void> open(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) =>
        const FractionallySizedBox(heightFactor: 0.85, child: SharesSheet()),
  );

  @override
  ConsumerState<SharesSheet> createState() => _SharesSheetState();
}

class _SharesSheetState extends ConsumerState<SharesSheet> {
  final _label = TextEditingController();
  List<Share> _shares = [];
  String _preset = '1d';
  DateTime? _custom;
  bool _route = false; // opt-in: off for every new link
  late String _routeFrom = _today();
  bool _bag = false; // opt-in: the bag (phone, QR…) for anyone holding the link
  bool _pics = false; // opt-in: photos switched to "Chia sẻ"
  String _extending = ''; // id of the link whose "Gia hạn" choices are open
  String _err = '';
  String _note = '';
  bool _busy = false;

  DateTime _now() => ref.read(nowProvider)();
  String _today() => ymd(_now());
  SharesRepository get _repo => ref.read(sharesRepositoryProvider);

  @override
  void initState() {
    super.initState();
    unawaited(_refresh());
  }

  @override
  void dispose() {
    _label.dispose();
    super.dispose();
  }

  void _say({String err = '', String note = ''}) => setState(() {
    _err = err;
    _note = note;
  });

  /// Runs one call; an expired session signs out, other errors go through [onError].
  Future<T?> _run<T>(
    Future<T> Function() fn,
    String Function(Object e) onError,
  ) async {
    try {
      return await fn();
    } on AuthExpired {
      if (mounted) {
        ref
            .read(authControllerProvider.notifier)
            .expired(); // closed meanwhile: the next call will tell
      }
    } on AccountMissing {
      if (mounted) ref.read(authControllerProvider.notifier).noAccount();
    } on Object catch (e) {
      if (mounted) _say(err: onError(e));
    }
    return null;
  }

  String _why(Object e, String fallback) => e is ShareInvalid
      ? (_invalid[e.field] ?? 'Thông tin chưa hợp lệ.')
      : '$fallback: $e';

  Future<void> _refresh() async {
    final list = await _run(_repo.list, (e) => 'Chưa tải được danh sách: $e');
    if (list != null && mounted) setState(() => _shares = list);
  }

  Future<void> _create() async {
    _say();
    if (_label.text.trim().isEmpty) return _say(err: _invalid['label']!);
    final expires = _preset == 'custom'
        ? _custom
        : _now().add(_presets[_preset]!.$2);
    if (expires == null) return _say(err: _invalid['expiresAt']!);
    setState(() => _busy = true);
    final s = await _run(
      () => _repo.create(
        label: _label.text.trim(),
        expiresAt: isoMs(expires),
        route: _route,
        routeFrom: _routeFrom,
        bag: _bag,
        pics: _pics,
      ),
      (e) => _why(e, 'Chưa tạo được link'),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (s == null) return;
    _label.clear();
    setState(() {
      _route = false;
      _routeFrom = _today();
      _bag = false;
      _pics = false;
      _shares = [s, ..._shares];
    });
    _say(note: 'Đã tạo link ✨ — bấm Sao chép để gửi.');
  }

  Future<void> _copy(Share s) async {
    await Clipboard.setData(
      ClipboardData(text: shareLink(ref.read(appConfigProvider), s.id)),
    );
    _say(note: 'Đã sao chép link cho "${s.label}" 💖');
  }

  Future<void> _send(Share s) => ref.read(shareLauncherProvider)(
    'Vị trí của mình (${s.label})',
    shareLink(ref.read(appConfigProvider), s.id),
  );

  Future<void> _edit(
    Share s, {
    required String done,
    String? expiresAt,
    bool? route,
    String? routeFrom,
    bool? bag,
    bool? pics,
  }) async {
    _say();
    final n = await _run(
      () => _repo.edit(
        s.id,
        expiresAt: expiresAt,
        route: route,
        routeFrom: routeFrom,
        bag: bag,
        pics: pics,
      ),
      (e) => _why(e, 'Chưa sửa được'),
    );
    if (n == null || !mounted) return;
    setState(() {
      _shares = _shares.map((x) => x.id == s.id ? n : x).toList();
      _extending = '';
    });
    _say(note: done);
  }

  /// Turning the bag on for a link: anyone holding it sees everything in the bag, and links get passed on.
  Future<bool> _bagOk() => _ok(
    'Ai có link này đều thấy số điện thoại, mã QR và mọi thứ trong túi của bạn, và link có thể bị chuyển tiếp cho người khác. Bật nhé?',
  );

  /// Turning "Ảnh" on: anyone holding the link sees every shared photo.
  Future<bool> _picsOk() =>
      _ok('Ai có link này đều thấy mọi ảnh bạn đã bật Chia sẻ. Bật nhé?');

  Future<bool> _ok(String question) async =>
      await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          content: Text(question),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Thôi'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Bật'),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> _revoke(Share s) async {
    final expired = s.expiredAt(_now());
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        content: Text(
          expired
              ? 'Xoá hẳn link của "${s.label}"? Sẽ không gia hạn lại được nữa.'
              : 'Thu hồi link của "${s.label}"? Người đó sẽ không xem được nữa.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Thôi'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(expired ? 'Xoá' : 'Thu hồi'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    _say();
    final done = await _run(
      () => _repo.revoke(s.id).then((_) => true),
      (e) => 'Chưa thu hồi được: $e',
    );
    if (done == true && mounted) {
      setState(
        () => _shares = [
          for (final x in _shares)
            if (x.id != s.id) x,
        ],
      );
    }
  }

  Future<String?> _pickDay(String initial) async {
    final d = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: _now(),
      initialDate: DateTime.parse(initial),
      helpText: 'Đường đi từ ngày',
    );
    return d == null ? null : ymd(d);
  }

  Future<void> _pickExpiry() async {
    final d = await showDatePicker(
      context: context,
      firstDate: _now(),
      lastDate: _now().add(const Duration(days: 365)),
      helpText: 'Hết hạn lúc',
    );
    if (d == null || !mounted) return;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_now()),
    );
    if (t == null) return;
    setState(
      () => _custom = DateTime(d.year, d.month, d.day, t.hour, t.minute),
    );
  }

  @override
  Widget build(BuildContext context) => Padding(
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
                '🔗 Chia sẻ vị trí',
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
        const SizedBox(height: 8),
        TextField(
          key: const Key('label'),
          controller: _label,
          maxLength: 40,
          decoration: const InputDecoration(
            hintText: 'Gửi cho ai? (vd: Mẹ)',
            counterText: '',
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final MapEntry(key: k, value: (text, _)) in _presets.entries)
              Pill(
                label: text,
                style: PillStyle.lav,
                selected: _preset == k,
                onTap: () => setState(() => _preset = k),
              ),
            Pill(
              label: _preset == 'custom' && _custom != null
                  ? '${dm(ymd(_custom!))} ${hhmm(_custom!)}'
                  : 'Chọn ngày',
              style: PillStyle.lav,
              selected: _preset == 'custom',
              onTap: () async {
                setState(() => _preset = 'custom');
                await _pickExpiry();
              },
            ),
          ],
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          value: _route,
          onChanged: (v) => setState(() => _route = v ?? false),
          title: const Text('Cho xem cả đường đi 🐾'),
        ),
        if (_route)
          Row(
            children: [
              const Text('từ ngày '),
              Pill(
                label: dm(_routeFrom),
                style: PillStyle.lav,
                onTap: () async {
                  final d = await _pickDay(_routeFrom);
                  if (d != null) setState(() => _routeFrom = d);
                },
              ),
              const Text(' đến hôm nay'),
            ],
          ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          value: _bag,
          onChanged: (v) async {
            final on = v == true && await _bagOk();
            if (mounted) setState(() => _bag = on);
          },
          title: const Text('Cho mở túi đồ 🎒'),
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          value: _pics,
          onChanged: (v) async {
            final on = v == true && await _picsOk();
            if (mounted) setState(() => _pics = on);
          },
          title: const Text('Cho xem ảnh đã chia sẻ 🖼️'),
        ),
        const SizedBox(height: 8),
        Pill(
          label: 'Tạo link 💖',
          style: PillStyle.on,
          onTap: _busy ? null : _create,
        ),
        if (_err.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Notice(_err, error: true),
          ),
        if (_note.isNotEmpty)
          Padding(padding: const EdgeInsets.only(top: 8), child: Notice(_note)),
        const SizedBox(height: 12),
        for (final s in _shares) _shareRow(s),
        if (_shares.isEmpty) const Notice('Chưa có link nào.'),
      ],
    ),
  );

  Widget _shareRow(Share s) {
    final expired = s.expiredAt(_now());
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Opacity(
        opacity: expired ? 0.7 : 1,
        child: CardBox(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${s.label}${s.route ? ' · 🐾 ${s.routeFrom != null ? 'từ ${dm(s.routeFrom!)}' : 'hôm nay'}' : ''}${s.bag ? ' · 🎒' : ''}${s.pics ? ' · 🖼️' : ''}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              Text(
                '${remaining(s.expiresAt, now: _now())} · tạo ${dm(ymd(DateTime.parse(s.createdAt)))} ${hhmmIso(s.createdAt)}',
                style: const TextStyle(color: Palette.muted, fontSize: 12),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (!expired) Pill(label: 'Sao chép', onTap: () => _copy(s)),
                  if (!expired)
                    Pill(
                      label: 'Gửi',
                      style: PillStyle.lav,
                      onTap: () => _send(s),
                    ),
                  Pill(
                    label: expired ? 'Gia hạn' : 'Sửa',
                    style: expired ? PillStyle.on : PillStyle.lav,
                    onTap: () => setState(
                      () => _extending = _extending == s.id ? '' : s.id,
                    ),
                  ),
                  Pill(
                    label: '🐾',
                    style: PillStyle.lav,
                    selected: s.route,
                    semanticLabel: 'Cho xem cả đường đi hôm nay',
                    onTap: () => _edit(
                      s,
                      route: !s.route,
                      done: s.route
                          ? 'Đã tắt đường đi cho "${s.label}".'
                          : 'Đã bật đường đi cho "${s.label}" 🐾',
                    ),
                  ),
                  Pill(
                    label: '🎒',
                    style: PillStyle.lav,
                    selected: s.bag,
                    semanticLabel: 'Cho mở túi đồ',
                    onTap: () async {
                      if (s.bag) {
                        return await _edit(
                          s,
                          bag: false,
                          done: 'Đã đóng túi với "${s.label}".',
                        );
                      }
                      if (await _bagOk()) {
                        await _edit(
                          s,
                          bag: true,
                          done: '"${s.label}" mở được túi đồ 🎒',
                        );
                      }
                    },
                  ),
                  Pill(
                    label: '🖼️',
                    style: PillStyle.lav,
                    selected: s.pics,
                    semanticLabel: 'Ảnh: cho xem ảnh đã chia sẻ',
                    onTap: () async {
                      if (s.pics) {
                        return await _edit(
                          s,
                          pics: false,
                          done: 'Đã tắt ảnh với "${s.label}".',
                        );
                      }
                      if (await _picsOk()) {
                        await _edit(
                          s,
                          pics: true,
                          done: '"${s.label}" xem được ảnh đã chia sẻ 🖼️',
                        );
                      }
                    },
                  ),
                  Pill(
                    label: expired ? 'Xoá' : 'Thu hồi',
                    style: PillStyle.ghost,
                    onTap: () => _revoke(s),
                  ),
                ],
              ),
              if (_extending == s.id) ...[
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Notice('Hết hạn sau'),
                    for (final (text, d) in _presets.values)
                      Pill(
                        label: text,
                        style: PillStyle.lav,
                        onTap: () => _edit(
                          s,
                          expiresAt: isoMs(_now().add(d)),
                          done: 'Đã gia hạn "${s.label}" thêm $text ✨',
                        ),
                      ),
                    Pill(
                      label: '🐾 từ ${dm(s.routeFrom ?? _today())}',
                      style: PillStyle.lav,
                      onTap: () async {
                        final d = await _pickDay(s.routeFrom ?? _today());
                        if (d != null) {
                          await _edit(
                            s,
                            route: true,
                            routeFrom: d,
                            done:
                                '"${s.label}" xem được đường đi từ ${dm(d)} 🐾',
                          );
                        }
                      },
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
