import 'package:flutter/widgets.dart';

/// Spacing scale: 4 · 8 · 12 · 16 · 24 · 32.
abstract final class Gap {
  static const xs = 4.0;
  static const s = 8.0;
  static const m = 12.0;
  static const l = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;

  /// Horizontal screen edge.
  static const screen = l;

  /// Minimum touch target, including the set ✓ button.
  static const touch = 48.0;

  static const vS = SizedBox(height: s);
  static const vM = SizedBox(height: m);
  static const vL = SizedBox(height: l);
  static const vXl = SizedBox(height: xl);
  static const hS = SizedBox(width: s);
  static const hM = SizedBox(width: m);
}

/// Corner radii: input 10, card 16, sheet 24, button 999 (pill).
abstract final class Radii {
  static const input = 10.0;
  static const card = 16.0;
  static const sheet = 24.0;
  static const pill = 999.0;

  static final inputBorder = BorderRadius.circular(input);
  static final cardBorder = BorderRadius.circular(card);
  static final sheetBorder = BorderRadius.circular(sheet);
  static final pillBorder = BorderRadius.circular(pill);
}
