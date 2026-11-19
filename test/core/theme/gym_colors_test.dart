import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymgym_a/core/theme/gym_colors.dart';

void main() {
  testWidgets('of() falls back to the brightness default without extension', (
    tester,
  ) async {
    late GymColors dark;
    late GymColors light;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(brightness: Brightness.dark),
        home: Builder(
          builder: (context) {
            dark = GymColors.of(context);
            return Theme(
              data: ThemeData(brightness: Brightness.light),
              child: Builder(
                builder: (context) {
                  light = GymColors.of(context);
                  return const SizedBox();
                },
              ),
            );
          },
        ),
      ),
    );
    expect(dark, same(GymColors.dark));
    expect(light, same(GymColors.light));
  });

  test('ghost differs from text so previous values stay recognisable', () {
    for (final colors in [GymColors.dark, GymColors.light]) {
      expect(colors.ghost, isNot(colors.text));
      expect(colors.ghost, isNot(colors.textMuted));
    }
  });

  test('lerp reaches the other palette at t = 1', () {
    final mixed = GymColors.dark.lerp(GymColors.light, 1);
    expect(mixed.kor, GymColors.light.kor);
    expect(mixed.bg, GymColors.light.bg);
    expect(GymColors.dark.lerp(null, 0.5), same(GymColors.dark));
  });
}
