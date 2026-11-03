import 'dart:ui';

/// The web's `styles.css :root` colours.
abstract final class Palette {
  static const pink = Color(0xFFEC4899);
  static const pinkSoft = Color(0xFFFCE7F3);
  static const lavender = Color(0xFFEDE9FE);
  static const ink = Color(0xFF3F2A3A);
  static const muted = Color(0xFF9B7B92);
  static const card = Color(0xF2FFFFFF); // rgba(255,255,255,0.95)
  static const page = Color(0xFFFFF7FB);
  static const error = Color(0xFFBE123C);

  /// The pink card shadow: 0 6px 24px rgba(236,72,153,0.18).
  static const shadow = Color(0x2EEC4899);
}
