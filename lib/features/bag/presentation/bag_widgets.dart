import 'package:findme/core/config/app_config.dart';
import 'package:findme/core/theme/palette.dart';
import 'package:findme/features/bag/domain/bag.dart';
import 'package:findme/features/bag/presentation/bag_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// The web's bag CSS colours.
const bagCream = Color(0xFFFFF4EE);
const _bagBody = Color(0xFFFFD9C9);
const _bagRim = Color(0xFFF6C3AE);
const _strap = Color(0xFFF6B8A4);
const _pocketShadow = Color(0xFFF6D3C8);
const _emptyPocket = Color(0xFFFFEAE1);
const _emptyPlus = Color(0xFFE6A898);
const bagInk = Color(0xFF7A5560);
const _avatarBg = Color(0xFFFFD9D2);

/// Opens [child] as the bag's cream bottom sheet (`.bag-backdrop` + `.bag-sheet`).
Future<T?> showBagSheet<T>(BuildContext context, Widget child) =>
    showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: bagCream,
      barrierColor: const Color(0x403F2A3A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => child,
    );

/// The sheet's head: picture, title (+ a line under it), ✕.
class BagHead extends StatelessWidget {
  const BagHead({required this.title, super.key, this.lead, this.sub});

  final Widget? lead;
  final String title;
  final String? sub;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      if (lead != null) ...[lead!, const SizedBox(width: 10)],
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
            ),
            if (sub != null)
              Text(
                sub!,
                style: const TextStyle(color: Palette.muted, fontSize: 13),
              ),
          ],
        ),
      ),
      Semantics(
        button: true,
        label: 'Đóng',
        excludeSemantics: true,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => Navigator.maybePop(context),
          child: const CircleAvatar(
            radius: 17,
            backgroundColor: _emptyPocket,
            child: Text('✕', style: TextStyle(color: bagInk, fontSize: 15)),
          ),
        ),
      ),
    ],
  );
}

/// A round picture (`.avatar-pin`). Until the picture has loaded, or if it never does, [fallback] stays (the
/// initial, or Hachiware), like the web's useLoadedAvatars.
class AvatarCircle extends ConsumerWidget {
  const AvatarCircle({
    required this.media,
    required this.fallback,
    super.key,
    this.size = 44,
    this.border = Palette.pink,
    this.borderWidth = 3,
  });

  /// Look Back media id; null = [fallback].
  final String? media;
  final Widget fallback;
  final double size;
  final Color border;
  final double borderWidth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final url = media == null
        ? null
        : '${ref.watch(appConfigProvider).web}${avatarPath(media!)}';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _avatarBg,
        border: Border.all(color: border, width: borderWidth),
        boxShadow: const [
          BoxShadow(
            color: Color(0x597A5560),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: url == null
          ? fallback
          : Image.network(
              url,
              fit: BoxFit.cover,
              frameBuilder: (_, child, frame, sync) =>
                  frame == null && !sync ? fallback : child,
              errorBuilder: (_, _, _) => fallback,
            ),
    );
  }
}

/// A friend's first letter, in their colour (the map's marker before a picture).
class Initial extends StatelessWidget {
  const Initial(this.name, this.color, {super.key, this.fontSize = 15});

  final String name;
  final Color color;
  final double fontSize;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Colors.white,
    child: Center(
      child: Text(
        name.trim().isEmpty ? '?' : name.trim().characters.first.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: fontSize,
        ),
      ),
    ),
  );
}

/// One puffy pocket: an icon and its name, or an empty one (a `+` only when it can be tapped).
class Pocket extends StatelessWidget {
  const Pocket({super.key, this.item, this.type, this.onTap});

  final BagItem? item;

  /// For the "add" list: a type with no item yet.
  final ItemType? type;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = item?.type ?? type;
    final label = item?.title ?? (t == null ? null : typeInfo(t).name);
    return Semantics(
      button: onTap != null,
      label: label ?? (onTap != null ? 'Thêm vào túi' : 'Ô trống'),
      excludeSemantics: true,
      child: AspectRatio(
        aspectRatio: 1,
        child: DecoratedBox(
          // `box-shadow: 0 4px 0` under a full pocket
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: t == null
                ? null
                : const [BoxShadow(color: _pocketShadow, offset: Offset(0, 4))],
          ),
          child: Material(
            color: t == null ? _emptyPocket : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: t == null
                    ? Center(
                        child: Text(
                          onTap != null ? '+' : '',
                          style: const TextStyle(
                            color: _emptyPlus,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          BagIcon(t),
                          const SizedBox(height: 2),
                          Text(
                            label!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: bagInk,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Pockets four to a row.
class PocketGrid extends StatelessWidget {
  const PocketGrid({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => GridView.count(
    crossAxisCount: 4,
    mainAxisSpacing: 9,
    crossAxisSpacing: 9,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    children: children,
  );
}

/// The soft backpack: 4 × 2 puffy pockets under a strap.
class BagGrid extends StatelessWidget {
  const BagGrid({
    required this.slots,
    required this.onTap,
    super.key,
    this.editable = false,
  });

  final Slots slots;
  final void Function(int index) onTap;
  final bool editable;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 22),
    child: Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Positioned(
          top: -18,
          child: Container(
            width: 70,
            height: 30,
            // its bottom edge is hidden behind the bag
            decoration: BoxDecoration(
              border: Border.all(color: _strap, width: 7),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(35),
              ),
            ),
          ),
        ),
        Container(
          // the rim (`inset 0 -6px 0`) shows under the body
          padding: const EdgeInsets.only(bottom: 6),
          decoration: const BoxDecoration(
            color: _bagRim,
            borderRadius: _bagShape,
            boxShadow: [
              BoxShadow(
                color: Color(0x73F6B8A4),
                blurRadius: 18,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
            decoration: const BoxDecoration(
              color: _bagBody,
              borderRadius: _bagShape,
            ),
            child: PocketGrid(
              children: [
                for (var i = 0; i < slotCount; i++)
                  Pocket(
                    item: i < slots.length ? slots[i] : null,
                    onTap: (i < slots.length && slots[i] != null) || editable
                        ? () => onTap(i)
                        : null,
                  ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

const _bagShape = BorderRadius.vertical(
  top: Radius.circular(26),
  bottom: Radius.circular(30),
);
