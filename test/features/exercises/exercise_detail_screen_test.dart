import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymgym_a/app.dart';
import 'package:gymgym_a/data/exercise_catalog.dart';
import 'package:gymgym_a/features/exercises/exercise_detail_screen.dart';

import '../../helpers/fake_exercises.dart';

Widget _withCatalog(Widget child) {
  return ProviderScope(
    overrides: [
      exerciseCatalogProvider.overrideWith((ref) async => fakeExercises),
    ],
    child: child,
  );
}

Future<void> _pumpDetail(WidgetTester tester, String id) async {
  await tester.pumpWidget(
    _withCatalog(MaterialApp(home: ExerciseDetailScreen(id: id))),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the exercise for the given id', (tester) async {
    await _pumpDetail(tester, '1');

    expect(find.text('Bench Press'), findsWidgets);
    expect(find.text('Lat Pulldown'), findsNothing);
    expect(find.textContaining('Pectorals'), findsOneWidget);
    expect(find.textContaining('Shoulders, Triceps'), findsOneWidget);
    expect(find.text('1. Lie on the bench.'), findsOneWidget);
    expect(find.text('2. Barı yukarı itin.'), findsOneWidget);
  });

  testWidgets('shows the Gym visual attribution', (tester) async {
    await _pumpDetail(tester, '1');

    expect(find.text(fakeAttribution), findsOneWidget);
  });

  testWidgets('never shows the GIF larger than 180x180', (tester) async {
    await _pumpDetail(tester, '1');

    final gif = tester.widget<Image>(find.byType(Image));
    expect(gif.width, 180);
    expect(gif.height, 180);
    // Missing media falls back to the placeholder icon.
    expect(find.byIcon(Icons.fitness_center), findsOneWidget);
  });

  testWidgets('unknown id shows a not found state', (tester) async {
    await _pumpDetail(tester, 'no-such-id');

    expect(find.text('Exercise not found (id: no-such-id)'), findsOneWidget);
    expect(find.text(fakeAttribution), findsNothing);
  });

  testWidgets('tapping a list item opens its detail view', (tester) async {
    await tester.pumpWidget(_withCatalog(const GymGymApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Lat Pulldown'));
    await tester.pumpAndSettle();

    expect(find.byType(ExerciseDetailScreen), findsOneWidget);
    expect(find.textContaining('Lats'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byType(ExerciseDetailScreen), findsNothing);
    expect(find.text('Bench Press'), findsOneWidget);
  });
}
