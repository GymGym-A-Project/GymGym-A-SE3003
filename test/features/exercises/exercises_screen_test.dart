import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymgym_a/data/exercise_catalog.dart';
import 'package:gymgym_a/features/exercises/exercises_screen.dart';

import '../../helpers/fake_exercises.dart';

Future<void> _pumpScreen(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        exerciseCatalogProvider.overrideWith((ref) async => fakeExercises),
      ],
      child: const MaterialApp(home: ExercisesScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows all exercises and the Gym visual attribution', (
    tester,
  ) async {
    await _pumpScreen(tester);

    expect(find.text('Bench Press'), findsOneWidget);
    expect(find.text('Lat Pulldown'), findsOneWidget);
    expect(find.text('Barbell Squat'), findsOneWidget);
    expect(find.text(fakeAttribution), findsOneWidget);
    // Missing media falls back to the placeholder icon.
    expect(find.byIcon(Icons.fitness_center), findsNWidgets(3));
  });

  testWidgets('tapping a muscle chip filters the list', (tester) async {
    await _pumpScreen(tester);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Back'));
    await tester.pumpAndSettle();

    expect(find.text('Lat Pulldown'), findsOneWidget);
    expect(find.text('Bench Press'), findsNothing);
    expect(find.text('Barbell Squat'), findsNothing);

    await tester.tap(find.widgetWithText(ChoiceChip, 'All'));
    await tester.pumpAndSettle();
    expect(find.text('Bench Press'), findsOneWidget);
  });

  testWidgets('search combines with the chip and shows an empty state', (
    tester,
  ) async {
    await _pumpScreen(tester);

    await tester.enterText(find.byType(TextField), 'BARBELL');
    await tester.pumpAndSettle();
    expect(find.text('Bench Press'), findsOneWidget);
    expect(find.text('Barbell Squat'), findsOneWidget);
    expect(find.text('Lat Pulldown'), findsNothing);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Back'));
    await tester.pumpAndSettle();
    expect(find.text('No exercises match your search.'), findsOneWidget);
    expect(find.text(fakeAttribution), findsOneWidget);
  });
}
