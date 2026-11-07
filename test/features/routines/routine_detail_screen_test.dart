import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymgym_a/core/router.dart';
import 'package:gymgym_a/data/models/routine.dart';
import 'package:gymgym_a/data/models/routine_item.dart';
import 'package:gymgym_a/data/repositories/fake_routine_repository.dart';
import 'package:gymgym_a/features/routines/routine_create_screen.dart';
import 'package:gymgym_a/features/routines/routine_detail_screen.dart';
import 'package:gymgym_a/features/routines/routines_screen.dart';

import '../../helpers/fake_exercises.dart';
import '../../helpers/routine_app.dart';

Routine _routine(List<RoutineItem> items) => Routine(
  id: 'r1',
  name: 'Push day',
  order: 0,
  items: items,
  source: 'custom',
  updatedAt: DateTime.utc(2026, 11, 5),
);

Future<void> _pumpDetail(WidgetTester tester, List<RoutineItem> items) =>
    pumpRoutineApp(
      tester,
      location: AppRoutes.routineDetail('r1'),
      repository: FakeRoutineRepository(routines: [_routine(items)]),
    );

void main() {
  testWidgets('shows exercises in routine order with target sets', (
    tester,
  ) async {
    await _pumpDetail(tester, [
      RoutineItem(exerciseId: '3', targetSets: 5),
      RoutineItem(exerciseId: '1', targetSets: 1),
      RoutineItem(exerciseId: '2', targetSets: 3),
    ]);

    expect(find.text('Push day'), findsOneWidget);
    final squat = tester.getTopLeft(find.text('Barbell Squat')).dy;
    final bench = tester.getTopLeft(find.text('Bench Press')).dy;
    final lat = tester.getTopLeft(find.text('Lat Pulldown')).dy;
    expect(squat, lessThan(bench));
    expect(bench, lessThan(lat));
    expect(find.text('5 sets'), findsOneWidget);
    expect(find.text('1 set'), findsOneWidget);
    expect(find.text('3 sets'), findsOneWidget);
  });

  testWidgets('shows thumbnails with fallback and the attribution', (
    tester,
  ) async {
    await _pumpDetail(tester, [
      RoutineItem(exerciseId: '1', targetSets: 3),
      RoutineItem(exerciseId: '2', targetSets: 3),
    ]);

    expect(find.byType(Image), findsNWidgets(2));
    // Missing media falls back to the placeholder icon. The third icon is the
    // Exercises tab in the bottom navigation.
    expect(find.byIcon(Icons.fitness_center), findsNWidgets(3));
    expect(find.text(fakeAttribution), findsOneWidget);
  });

  testWidgets('an exercise missing from the catalog does not break the view', (
    tester,
  ) async {
    await _pumpDetail(tester, [RoutineItem(exerciseId: 'gone', targetSets: 4)]);

    expect(find.text('Unknown exercise'), findsOneWidget);
    expect(find.text('4 sets'), findsOneWidget);
  });

  testWidgets('unknown id shows Routine not found', (tester) async {
    await pumpRoutineApp(tester, location: AppRoutes.routineDetail('nope'));

    expect(find.text('Routine not found'), findsOneWidget);
    expect(find.text(fakeAttribution), findsNothing);
    expect(find.byTooltip('Edit routine'), findsNothing);
    expect(find.byTooltip('Delete routine'), findsNothing);
  });

  testWidgets('the edit action opens the edit screen', (tester) async {
    await _pumpDetail(tester, [RoutineItem(exerciseId: '1', targetSets: 3)]);

    await tester.tap(find.byTooltip('Edit routine'));
    await tester.pumpAndSettle();

    expect(find.byType(RoutineEditScreen), findsOneWidget);
  });

  group('delete', () {
    late FakeRoutineRepository repository;

    Future<void> openDialog(WidgetTester tester) async {
      repository = FakeRoutineRepository(
        routines: [
          _routine([RoutineItem(exerciseId: '1', targetSets: 3)]),
        ],
      );
      await pumpRoutineApp(
        tester,
        location: AppRoutes.routineDetail('r1'),
        repository: repository,
      );
      await tester.tap(find.byTooltip('Delete routine'));
      await tester.pumpAndSettle();
    }

    testWidgets('cancel keeps the routine and stays on the view', (
      tester,
    ) async {
      await openDialog(tester);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(await repository.get('r1'), isNotNull);
      expect(find.byType(RoutineDetailScreen), findsOneWidget);
    });

    testWidgets('confirm removes the routine and goes back to the list', (
      tester,
    ) async {
      await openDialog(tester);

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(await repository.get('r1'), isNull);
      expect(find.byType(RoutineDetailScreen), findsNothing);
      expect(find.byType(RoutinesScreen), findsOneWidget);
      expect(find.text('No routines yet'), findsOneWidget);
    });
  });
}
