// SVG markup: adjacent strings join tags, no space wanted.
// ignore_for_file: missing_whitespace_between_adjacent_strings

import 'package:findme/features/bag/domain/bag.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

// Soft pocket icons, copied from the web's bagIcons.tsx: pastel fill, rounded cocoa outline, one per item type.
// Drawn here so they look the same on every phone (system emoji don't).
const _s =
    'stroke="#7a5560" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"';
const _ink = '#7a5560';

const _icons = <ItemType, String>{
  ItemType.phone:
      '<rect x="10" y="4" width="12" height="24" rx="4" fill="#ffd6e0" $_s/>'
      '<circle cx="16" cy="23" r="1.4" fill="$_ink"/>'
      '<circle cx="12.5" cy="15" r="1.2" fill="#f7a8bb"/><circle cx="19.5" cy="15" r="1.2" fill="#f7a8bb"/>',
  ItemType.zalo:
      '<path d="M6 9a5 5 0 0 1 5-5h10a5 5 0 0 1 5 5v8a5 5 0 0 1-5 5h-7l-5 4v-4.5A5 5 0 0 1 6 17z" fill="#cfe6ff" $_s/>'
      '<path d="M12 10h8l-8 8h8" fill="none" $_s/>',
  ItemType.email:
      '<rect x="4" y="8" width="24" height="17" rx="4" fill="#fff0c2" $_s/>'
      '<path d="M5 10l11 8 11-8" fill="none" $_s/>',
  ItemType.youtube:
      '<rect x="4" y="8" width="24" height="17" rx="6" fill="#ffc9c9" $_s/>'
      '<path d="M14 12.5v8l6.5-4z" fill="#fff" $_s/>',
  ItemType.spotify:
      '<circle cx="16" cy="16" r="12" fill="#c9f0d6" $_s/>'
      '<path d="M10 12.5c4-1.3 8.5-1 12 1M10.8 16.5c3.4-1 6.8-.7 9.7.8M11.6 20.3c2.6-.7 5.2-.5 7.3.6" fill="none" $_s/>',
  ItemType.tiktok:
      '<rect x="4" y="4" width="24" height="24" rx="8" fill="#e3dcff" $_s/>'
      '<path d="M17 9v10.5a3.5 3.5 0 1 1-3.5-3.5M17 9c.6 2.2 2.2 3.6 4.5 3.8" fill="none" $_s/>',
  ItemType.instagram:
      '<rect x="5" y="5" width="22" height="22" rx="7" fill="#ffd9ec" $_s/>'
      '<circle cx="16" cy="16" r="5" fill="#fff" $_s/>'
      '<circle cx="22" cy="10" r="1.3" fill="$_ink"/>',
  ItemType.link:
      '<rect x="3.5" y="11" width="14" height="10" rx="5" fill="#dff3ff" $_s/>'
      '<rect x="14.5" y="11" width="14" height="10" rx="5" fill="#dff3ff" $_s/>'
      '<path d="M12 16h8" $_s/>',
  ItemType.qr:
      '<rect x="4" y="4" width="24" height="24" rx="6" fill="#fff" $_s/>'
      '<rect x="8.5" y="8.5" width="5.5" height="5.5" rx="1.5" fill="$_ink"/>'
      '<rect x="18" y="8.5" width="5.5" height="5.5" rx="1.5" fill="$_ink"/>'
      '<rect x="8.5" y="18" width="5.5" height="5.5" rx="1.5" fill="$_ink"/>'
      '<rect x="18" y="18" width="2.6" height="2.6" rx=".8" fill="#f7a8bb"/>'
      '<rect x="21" y="21" width="2.6" height="2.6" rx=".8" fill="#f7a8bb"/>',
  ItemType.photo:
      '<rect x="4" y="6" width="24" height="20" rx="5" fill="#fff4d6" $_s/>'
      '<circle cx="11" cy="12.5" r="2.4" fill="#ffc48a"/>'
      '<path d="M6 23l7-7 4.5 4.5L21 17l6 6" fill="#c9f0d6" $_s/>',
  ItemType.note:
      '<rect x="5" y="8" width="22" height="17" rx="4" fill="#ffe3ea" $_s/>'
      '<path d="M6 10l10 7 10-7" fill="none" $_s/>'
      '<path d="M16 23.2c-2.6-1.6-3.6-2.7-3.6-3.9a1.8 1.8 0 0 1 3.6-.4 1.8 1.8 0 0 1 3.6.4c0 1.2-1 2.3-3.6 3.9z" fill="#f47c9c"/>',
};

class BagIcon extends StatelessWidget {
  const BagIcon(this.type, {super.key, this.size = 30});

  final ItemType type;
  final double size;

  @override
  Widget build(BuildContext context) => SvgPicture.string(
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32">${_icons[type]}</svg>',
    width: size,
    height: size,
    excludeFromSemantics: true,
  );
}
