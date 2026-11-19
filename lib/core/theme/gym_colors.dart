import 'package:flutter/material.dart';

/// Colour tokens of the GymGym-A design system.
///
/// Widgets read colours from here instead of writing hex values. `ghost` is
/// reserved for values from the previous session, never for placeholders, so
/// the user can tell "this number is from last time" at a glance.
@immutable
class GymColors extends ThemeExtension<GymColors> {
  const GymColors({
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.border,
    required this.text,
    required this.textMuted,
    required this.ghost,
    required this.kor,
    required this.onKor,
    required this.success,
    required this.successSurface,
    required this.plateau,
    required this.danger,
  });

  /// Page background.
  final Color bg;

  /// Cards and sheets.
  final Color surface;

  /// Inputs and nested surfaces.
  final Color surface2;

  /// 1 px card outline (cards use a border instead of a shadow).
  final Color border;
  final Color text;
  final Color textMuted;

  /// Previous-session values only.
  final Color ghost;

  /// The "Kor" (ember) accent that keeps the original orange identity.
  final Color kor;
  final Color onKor;

  /// Completed set ✓.
  final Color success;

  /// Background of a completed set row.
  final Color successSurface;

  /// Plateau and warnings.
  final Color plateau;
  final Color danger;

  static const dark = GymColors(
    bg: Color(0xFF0E0D0C),
    surface: Color(0xFF1A1816),
    surface2: Color(0xFF262320),
    border: Color(0xFF2E2A26),
    text: Color(0xFFF5F1EC),
    textMuted: Color(0xFFA39A91),
    ghost: Color(0xFF5F5852),
    kor: Color(0xFFFF7A3D),
    onKor: Color(0xFF1B0E06),
    success: Color(0xFF8FB573),
    successSurface: Color(0xFF1F2A19),
    plateau: Color(0xFFE8B04B),
    danger: Color(0xFFE5674C),
  );

  static const light = GymColors(
    bg: Color(0xFFFAF8F5),
    surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFF0ECE6),
    border: Color(0xFFE6E0D8),
    text: Color(0xFF1B1814),
    textMuted: Color(0xFF6B635B),
    ghost: Color(0xFFB3ABA2),
    kor: Color(0xFFE0581A),
    onKor: Color(0xFFFFFFFF),
    success: Color(0xFF4E7A35),
    successSurface: Color(0xFFE7F0DF),
    plateau: Color(0xFFB07D16),
    danger: Color(0xFFC4452B),
  );

  /// Tokens of the current theme; falls back to the brightness default so a
  /// widget also renders inside a plain `MaterialApp` (for example in tests).
  static GymColors of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<GymColors>() ??
        (theme.brightness == Brightness.dark ? dark : light);
  }

  @override
  GymColors copyWith({
    Color? bg,
    Color? surface,
    Color? surface2,
    Color? border,
    Color? text,
    Color? textMuted,
    Color? ghost,
    Color? kor,
    Color? onKor,
    Color? success,
    Color? successSurface,
    Color? plateau,
    Color? danger,
  }) => GymColors(
    bg: bg ?? this.bg,
    surface: surface ?? this.surface,
    surface2: surface2 ?? this.surface2,
    border: border ?? this.border,
    text: text ?? this.text,
    textMuted: textMuted ?? this.textMuted,
    ghost: ghost ?? this.ghost,
    kor: kor ?? this.kor,
    onKor: onKor ?? this.onKor,
    success: success ?? this.success,
    successSurface: successSurface ?? this.successSurface,
    plateau: plateau ?? this.plateau,
    danger: danger ?? this.danger,
  );

  @override
  GymColors lerp(GymColors? other, double t) {
    if (other == null) return this;
    return GymColors(
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surface2: Color.lerp(surface2, other.surface2, t)!,
      border: Color.lerp(border, other.border, t)!,
      text: Color.lerp(text, other.text, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      ghost: Color.lerp(ghost, other.ghost, t)!,
      kor: Color.lerp(kor, other.kor, t)!,
      onKor: Color.lerp(onKor, other.onKor, t)!,
      success: Color.lerp(success, other.success, t)!,
      successSurface: Color.lerp(successSurface, other.successSurface, t)!,
      plateau: Color.lerp(plateau, other.plateau, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
    );
  }
}
