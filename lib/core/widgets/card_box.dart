import 'package:findme/core/theme/palette.dart';
import 'package:flutter/material.dart';

/// The web's `.card`: white, rounded 22, soft pink shadow.
class CardBox extends StatelessWidget {
  const CardBox({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(10),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      color: Palette.card,
      borderRadius: BorderRadius.all(Radius.circular(22)),
      boxShadow: [
        BoxShadow(color: Palette.shadow, blurRadius: 24, offset: Offset(0, 6)),
      ],
    ),
    child: Padding(padding: padding, child: child),
  );
}

/// The web's `.notice` (muted) and `.notice.err` (red) one-liners.
class Notice extends StatelessWidget {
  const Notice(this.text, {super.key, this.error = false});

  final String text;
  final bool error;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Text(
      text,
      style: TextStyle(
        color: error ? Palette.error : Palette.muted,
        fontSize: 13,
      ),
    ),
  );
}
