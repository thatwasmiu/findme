import 'dart:async';

import 'package:findme/core/config/app_config.dart';
import 'package:findme/core/theme/palette.dart';
import 'package:findme/features/bag/data/bag_repository.dart';
import 'package:findme/features/bag/domain/bag.dart';
import 'package:findme/features/bag/presentation/bag_widgets.dart';
import 'package:findme/features/trail/domain/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens a link from a pocket: tel: and mailto: hand over to the phone, https: to the browser or the app.
typedef LinkOpener = Future<bool> Function(Uri);

final linkOpenerProvider = Provider<LinkOpener>(
  (_) =>
      (uri) => launchUrl(uri, mode: LaunchMode.externalApplication),
);

/// Someone's bag, read-only (the web's BagSheet.tsx): tap a pocket to call, open the link, or see the picture or
/// note.
class BagSheet extends ConsumerStatefulWidget {
  const BagSheet({
    required this.title,
    required this.load,
    super.key,
    this.lead,
  });

  /// "Túi của Mèo".
  final String title;
  final Widget? lead;
  final Future<Slots> Function() load;

  static Future<void> open(
    BuildContext context, {
    required String title,
    required Future<Slots> Function() load,
    Widget? lead,
  }) => showBagSheet(context, BagSheet(title: title, load: load, lead: lead));

  @override
  ConsumerState<BagSheet> createState() => _BagSheetState();
}

class _BagSheetState extends ConsumerState<BagSheet> {
  Slots? _slots;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    unawaited(
      widget.load().then(
        (s) => mounted ? setState(() => _slots = s) : null,
        onError: (Object _) => mounted ? setState(() => _failed = true) : null,
      ),
    );
  }

  Future<void> _tap(int i) async {
    final it = _slots?[i];
    if (it == null) return;
    switch (itemAction(it)) {
      case OpenLink(:final href):
        final uri = Uri.tryParse(href);
        if (uri != null) await ref.read(linkOpenerProvider)(uri);
      case ShowInPlace():
        await Navigator.of(context).push(
          PageRouteBuilder<void>(
            opaque: false,
            pageBuilder: (_, _, _) => BagFull(it),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final count = _slots?.where((s) => s != null).length ?? 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BagHead(
            lead: widget.lead,
            title: widget.title,
            sub: _slots == null
                ? null
                : count > 0
                ? '$count món nhỏ xinh'
                : 'Túi còn trống trơn ✨',
          ),
          if (_failed)
            const _Centered('Chưa mở được túi này, thử lại sau nhé 🎒')
          else if (_slots == null)
            const _Centered('Đang mở túi…')
          else
            BagGrid(slots: _slots!, onTap: _tap),
        ],
      ),
    );
  }
}

class _Centered extends StatelessWidget {
  const _Centered(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(color: Palette.muted),
    ),
  );
}

/// A picture or a note, full screen; a tap closes it. Plain white behind a QR so another phone scans it.
class BagFull extends ConsumerWidget {
  const BagFull(this.item, {super.key});

  final BagItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final web = ref.watch(appConfigProvider).web;
    const gone = _Centered('Ảnh này đang trốn mất rồi 🙈 Thử lại sau nhé.');
    return Semantics(
      label: item.title,
      child: GestureDetector(
        onTap: () => Navigator.maybePop(context),
        child: ColoredBox(
          color: item.type == ItemType.qr ? Colors.white : bagCream,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (item.label != null && item.label!.isNotEmpty) ...[
                    Text(
                      item.label!,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Flexible(
                    child: item.type == ItemType.note
                        ? SingleChildScrollView(
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 420),
                              padding: const EdgeInsets.all(18),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.all(
                                  Radius.circular(18),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0xFFF6D3C8),
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Text(
                                item.value ?? '',
                                style: const TextStyle(
                                  fontSize: 17,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          )
                        : item.image == null
                        ? gone
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              '$web${item.image}',
                              fit: BoxFit.contain,
                              errorBuilder: (_, _, _) => gone,
                            ),
                          ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Chạm để đóng',
                    style: TextStyle(color: Palette.muted, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A friend's bag, from the friends list or their marker on the map.
Future<void> openFriendBag(
  BuildContext context,
  WidgetRef ref, {
  required String id,
  required String name,
  String? avatar,
}) {
  final color = friendColor(id);
  return BagSheet.open(
    context,
    title: 'Túi của $name',
    lead: AvatarCircle(
      media: avatar,
      border: color,
      fallback: Initial(name, color),
    ),
    load: () => ref.read(bagRepositoryProvider).friendBag(id),
  );
}
