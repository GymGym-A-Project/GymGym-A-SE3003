import 'package:flutter/material.dart';

/// Type scale of the design system. One family (Manrope); numbers use tabular
/// figures so kg and rep columns stay aligned.
abstract final class AppText {
  static const family = 'Manrope';

  static const tabular = [FontFeature.tabularFigures()];

  /// 28 / w800, e.g. a big stat value.
  static const display = TextStyle(
    fontFamily: family,
    fontSize: 28,
    fontWeight: FontWeight.w800,
    height: 1.15,
    fontFeatures: tabular,
  );

  /// 22 / w800, screen and routine titles.
  static const title = TextStyle(
    fontFamily: family,
    fontSize: 22,
    fontWeight: FontWeight.w800,
    height: 1.2,
  );

  /// 17 / w700, section and card headings.
  static const headline = TextStyle(
    fontFamily: family,
    fontSize: 17,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );

  /// 15 / w500, running text.
  static const body = TextStyle(
    fontFamily: family,
    fontSize: 15,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  /// 11 / w700 / +1.2 tracking, small caps-style labels.
  static const label = TextStyle(
    fontFamily: family,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.2,
    height: 1.3,
  );

  /// Material text theme mapped onto the scale above, coloured with [text]
  /// and [muted].
  static TextTheme textTheme(Color text, Color muted) {
    TextStyle c(TextStyle style, [Color? color]) =>
        style.copyWith(color: color ?? text);
    return TextTheme(
      displayLarge: c(display.copyWith(fontSize: 40)),
      displayMedium: c(display.copyWith(fontSize: 34)),
      displaySmall: c(display),
      headlineLarge: c(title.copyWith(fontSize: 26)),
      headlineMedium: c(title.copyWith(fontSize: 24)),
      headlineSmall: c(title),
      titleLarge: c(title),
      titleMedium: c(headline),
      titleSmall: c(headline.copyWith(fontSize: 15)),
      bodyLarge: c(body.copyWith(fontSize: 16)),
      bodyMedium: c(body),
      bodySmall: c(body.copyWith(fontSize: 13), muted),
      labelLarge: c(body.copyWith(fontWeight: FontWeight.w700)),
      labelMedium: c(label.copyWith(fontSize: 12, letterSpacing: 0.4)),
      labelSmall: c(label, muted),
    );
  }
}
