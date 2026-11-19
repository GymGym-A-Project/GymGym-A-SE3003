import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymgym_a/core/theme/app_theme.dart';
import 'package:gymgym_a/core/theme/gym_colors.dart';
import 'package:gymgym_a/core/widgets/attribution_note.dart';
import 'package:gymgym_a/core/widgets/empty_state.dart';
import 'package:gymgym_a/core/widgets/stat_tile.dart';

Future<void> _pump(WidgetTester tester, Widget child) => tester.pumpWidget(
  MaterialApp(
    theme: AppTheme.dark,
    home: Scaffold(body: child),
  ),
);

void main() {
  testWidgets('StatTile shows the label and the value with its unit', (
    tester,
  ) async {
    await _pump(
      tester,
      const StatTile(label: 'Total volume', value: '1,440 kg', accent: true),
    );
    expect(find.text('Total volume'), findsOneWidget);
    final value = tester.widget<Text>(find.text('1,440 kg'));
    expect(value.style!.color, GymColors.dark.kor);
  });

  testWidgets('AttributionNote keeps the credit text unchanged', (
    tester,
  ) async {
    await _pump(tester, const AttributionNote('© Gym visual — gymvisual.com'));
    expect(find.text('© Gym visual — gymvisual.com'), findsOneWidget);
  });

  testWidgets('EmptyState shows title, message and an optional action', (
    tester,
  ) async {
    var tapped = false;
    await _pump(
      tester,
      EmptyState(
        icon: Icons.history,
        title: 'No completed workouts yet',
        message: 'Finish a workout to see it here.',
        action: FilledButton(
          onPressed: () => tapped = true,
          child: const Text('Choose a routine'),
        ),
      ),
    );
    expect(find.text('No completed workouts yet'), findsOneWidget);
    expect(find.text('Finish a workout to see it here.'), findsOneWidget);
    await tester.tap(find.text('Choose a routine'));
    expect(tapped, isTrue);
  });
}
