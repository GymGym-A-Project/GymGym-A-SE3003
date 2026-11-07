import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymgym_a/core/router.dart';
import 'package:gymgym_a/data/models/routine.dart';
import 'package:gymgym_a/data/models/routine_item.dart';
import 'package:gymgym_a/data/repositories/fake_routine_repository.dart';
import 'package:gymgym_a/features/routines/routine_detail_screen.dart';

import '../../helpers/fake_exercises.dart';
import '../../helpers/routine_app.dart';

final _created = DateTime.utc(2026, 11, 5);

Routine _routine({List<RoutineItem>? items}) => Routine(
  id: 'r1',
  name: 'Push day',
  order: 4,
  items:
      items ??
      [
        RoutineItem(exerciseId: '1', targetSets: 3),
        RoutineItem(exerciseId: '2', targetSets: 5),
      ],
  source: 'starter:ppl',
  updatedAt: _created,
);

Future<FakeRoutineRepository> _pumpEdit(
  WidgetTester tester, {
  Routine? routine,
}) async {
  final repository = FakeRoutineRepository(routines: [routine ?? _routine()]);
  await pumpRoutineApp(
    tester,
    location: AppRoutes.routineEdit('r1'),
    repository: repository,
  );
  return repository;
}

Finder get _save => find.byKey(const ValueKey('routine-save'));
Finder get _name => find.byKey(const ValueKey('routine-name'));

Future<void> _tapSave(WidgetTester tester) async {
  await tester.tap(_save);
  await tester.pumpAndSettle();
}

bool _saveEnabled(WidgetTester tester) =>
    tester.widget<TextButton>(_save).onPressed != null;

void main() {
  testWidgets('opens prefilled with name, exercises and target sets', (
    tester,
  ) async {
    await _pumpEdit(tester);

    expect(find.text('Edit routine'), findsOneWidget);
    expect(tester.widget<TextField>(_name).controller!.text, 'Push day');
    expect(find.text('Bench Press'), findsOneWidget);
    expect(find.text('Lat Pulldown'), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('sets-value-2'))).data,
      '5',
    );
    expect(find.text(fakeAttribution), findsOneWidget);
  });

  testWidgets('a saved edit shows in the view and the list', (tester) async {
    final repository = await _pumpEdit(tester);

    await tester.enterText(_name, 'Heavy push');
    await tester.tap(find.byKey(const ValueKey('sets-increase-1')));
    await tester.pumpAndSettle();
    await _tapSave(tester);

    expect(find.byType(RoutineDetailScreen), findsOneWidget);
    expect(find.text('Heavy push'), findsOneWidget);
    expect(find.text('4 sets'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Heavy push'), findsOneWidget);
    expect(find.text('Push day'), findsNothing);

    final saved = (await repository.get('r1'))!;
    expect(saved.items.first.targetSets, 4);
  });

  testWidgets('keeps id, order and source and refreshes updatedAt', (
    tester,
  ) async {
    final repository = await _pumpEdit(tester);

    await tester.enterText(_name, 'Heavy push');
    await tester.pumpAndSettle();
    await _tapSave(tester);

    final all = await repository.watch().first;
    expect(all, hasLength(1));
    expect(all.single.id, 'r1');
    expect(all.single.order, 4);
    expect(all.single.source, 'starter:ppl');
    expect(all.single.updatedAt.isAfter(_created), isTrue);
  });

  testWidgets('dragging an exercise saves the new exercise order', (
    tester,
  ) async {
    final repository = await _pumpEdit(tester);

    await dragHandle(tester, 'drag-exercise-1', 100);
    await _tapSave(tester);

    final saved = (await repository.get('r1'))!;
    expect(saved.items.map((item) => item.exerciseId), ['2', '1']);
    expect(saved.items.map((item) => item.targetSets), [5, 3]);
  });

  testWidgets('exercises can be removed and added through the picker', (
    tester,
  ) async {
    final repository = await _pumpEdit(tester);

    await tester.tap(find.byTooltip('Remove exercise').first);
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Add exercises'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Barbell Squat'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    await _tapSave(tester);

    final saved = (await repository.get('r1'))!;
    expect(saved.items.map((item) => item.exerciseId), ['2', '3']);
  });

  testWidgets(
    'selecting a routine exercise in the picker never duplicates it',
    (tester) async {
      await _pumpEdit(tester);

      await tester.tap(find.textContaining('Add exercises'));
      await tester.pumpAndSettle();

      expect(find.text('Add exercises (2/15)'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsNWidgets(2));
    },
  );

  testWidgets('Save is off for a blank name or without exercises', (
    tester,
  ) async {
    await _pumpEdit(
      tester,
      routine: _routine(items: [RoutineItem(exerciseId: '1', targetSets: 3)]),
    );
    expect(_saveEnabled(tester), isTrue);

    await tester.enterText(_name, '   ');
    await tester.pumpAndSettle();
    expect(_saveEnabled(tester), isFalse);

    await tester.enterText(_name, 'Push day');
    await tester.tap(find.byTooltip('Remove exercise'));
    await tester.pumpAndSettle();
    expect(_saveEnabled(tester), isFalse);
  });

  testWidgets('an exercise missing from the catalog survives an edit', (
    tester,
  ) async {
    final repository = await _pumpEdit(
      tester,
      routine: _routine(
        items: [
          RoutineItem(exerciseId: 'gone', targetSets: 4),
          RoutineItem(exerciseId: '1', targetSets: 3),
        ],
      ),
    );

    expect(find.text('Unknown exercise'), findsOneWidget);
    expect(find.text(fakeAttribution), findsOneWidget);

    await tester.enterText(_name, 'Heavy push');
    await tester.pumpAndSettle();
    await _tapSave(tester);

    final saved = (await repository.get('r1'))!;
    expect(saved.items.first.exerciseId, 'gone');
    expect(saved.items.first.targetSets, 4);
  });

  testWidgets('unknown id shows Routine not found', (tester) async {
    await pumpRoutineApp(tester, location: AppRoutes.routineEdit('nope'));

    expect(find.text('Routine not found'), findsOneWidget);
  });
}
