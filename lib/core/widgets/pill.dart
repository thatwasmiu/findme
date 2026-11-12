import 'package:findme/core/theme/palette.dart';
import 'package:flutter/material.dart';

/// The web's `.pill` variants: plain (white), `on` (pink), `lav` (lavender), `ghost` (transparent).
enum PillStyle { plain, on, lav, ghost }

/// The rounded button used everywhere (`.pill` in the web's CSS).
class Pill extends StatelessWidget {
  const Pill({
    required this.label,
    super.key,
    this.onTap,
    this.style = PillStyle.plain,
    this.selected = false,
    this.semanticLabel,
    this.badge,
  });

  final String label;
  final VoidCallback? onTap;
  final PillStyle style;

  /// Selected beats lavender, like `.pill.lav.on`.
  final bool selected;
  final String? semanticLabel;

  /// A small count bubble (incoming friend requests).
  final int? badge;

  @override
  Widget build(BuildContext context) {
    final on = style == PillStyle.on || selected;
    final bg = on
        ? Palette.pink
        : switch (style) {
            PillStyle.lav => Palette.lavender,
            PillStyle.ghost => Colors.transparent,
            _ => Colors.white,
          };
    final text = Text(
      label,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: on ? Colors.white : Palette.ink,
        fontWeight: on ? FontWeight.w700 : FontWeight.w500,
      ),
    );
    return Semantics(
      button: true,
      selected: selected,
      label: semanticLabel,
      excludeSemantics: semanticLabel != null,
      child: Opacity(
        opacity: onTap == null ? 0.6 : 1,
        child: Material(
          color: bg,
          shape: const StadiumBorder(),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: 40,
                minWidth: 40,
              ), // comfortable tap target
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                // No badge: the bare text, so a long label wraps instead of overflowing a Row.
                child: badge == null || badge! <= 0
                    ? Center(widthFactor: 1, heightFactor: 1, child: text)
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          text,
                          if (badge != null && badge! > 0) ...[
                            const SizedBox(width: 4),
                            CircleAvatar(
                              radius: 9,
                              backgroundColor: Palette.pink,
                              child: Text(
                                '$badge',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
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
