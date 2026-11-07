import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymgym_a/core/router.dart';
import 'package:gymgym_a/data/models/routine.dart';
import 'package:gymgym_a/data/models/routine_item.dart';
import 'package:gymgym_a/data/repositories/fake_routine_repository.dart';
import 'package:gymgym_a/features/routines/exercise_picker_screen.dart';
import 'package:gymgym_a/features/routines/routine_create_screen.dart';
import 'package:gymgym_a/features/routines/routine_draft.dart';

import '../../helpers/fake_exercises.dart';
import '../../helpers/routine_app.dart';

final _nameField = find.byKey(const ValueKey('routine-name'));
final _save = find.byKey(const ValueKey('routine-save'));

bool _saveEnabled(WidgetTester tester) =>
    tester.widget<TextButton>(_save).onPressed != null;

Future<void> _openPicker(WidgetTester tester) async {
  await tester.tap(find.textContaining('Add exercises'));
  await tester.pumpAndSettle();
}

Future<void> _pick(WidgetTester tester, List<String> names) async {
  await _openPicker(tester);
  for (final name in names) {
    await tester.tap(find.text(name));
    await tester.pump();
  }
  await tester.tap(find.text('Done'));
  await tester.pumpAndSettle();
}

Future<void> _tapKey(WidgetTester tester, String key) async {
  await tester.tap(find.byKey(ValueKey(key)));
  await tester.pump();
}

class _FailingRepository extends FakeRoutineRepository {
  @override
  Future<void> save(Routine routine) async => throw Exception('offline');
}

class _OverfullDraft extends RoutineDraftNotifier {
  @override
  RoutineDraft build() => RoutineDraft(
    name: 'Too long',
    items: [
      for (var i = 0; i < 16; i++)
        RoutineDraftItem(
          fakeExercise(id: '$i', name: 'Exercise $i', primaryMuscle: 'chest'),
        ),
    ],
  );
}

void main() {
  testWidgets('create flow: name, 2 exercises and sets appear in the list', (
    tester,
  ) async {
    final repository = FakeRoutineRepository(
      routines: [
        Routine(
          id: 'old',
          name: 'Old routine',
          order: 0,
          items: [RoutineItem(exerciseId: '3', targetSets: 1)],
          source: 'custom',
          updatedAt: DateTime.utc(2026, 11, 1),
        ),
      ],
    );
    await pumpRoutineApp(tester, repository: repository);

    await tester.tap(find.text('New routine'));
    await tester.pumpAndSettle();
    await tester.enterText(_nameField, '  Push day  ');
    await _pick(tester, ['Lat Pulldown', 'Bench Press']);

    expect(find.text('Add exercises (2/15)'), findsOneWidget);
    expect(find.text(fakeAttribution), findsOneWidget);

    await _tapKey(tester, 'sets-increase-1');
    await _tapKey(tester, 'sets-increase-1');
    await _tapKey(tester, 'sets-decrease-2');
    await tester.tap(_save);
    await tester.pumpAndSettle();

    expect(find.byType(RoutineCreateScreen), findsNothing);
    expect(find.text('Push day'), findsOneWidget);
    expect(find.text('2 exercises'), findsOneWidget);

    final saved = (await repository.watch().first).last;
    expect(saved.id, isNot('old'));
    expect(saved.name, 'Push day');
    expect(saved.order, 1);
    expect(saved.source, 'custom');
    expect(saved.items.map((item) => item.exerciseId), ['2', '1']);
    expect(saved.items.map((item) => item.targetSets), [2, 5]);
  });

  testWidgets('Save is disabled for a blank name or 0 exercises', (
    tester,
  ) async {
    await pumpRoutineApp(tester, location: AppRoutes.routineNew);
    expect(_saveEnabled(tester), isFalse);

    await tester.enterText(_nameField, 'Push day');
    await tester.pump();
    expect(_saveEnabled(tester), isFalse);

    await _pick(tester, ['Bench Press']);
    expect(_saveEnabled(tester), isTrue);

    await tester.enterText(_nameField, '   ');
    await tester.pump();
    expect(_saveEnabled(tester), isFalse);

    await tester.enterText(_nameField, 'Push day');
    await tester.pump();
    await tester.tap(find.byTooltip('Remove exercise'));
    await tester.pump();
    expect(_saveEnabled(tester), isFalse);
  });

  testWidgets('the stepper starts at 3 and stops at 1', (tester) async {
    await pumpRoutineApp(tester, location: AppRoutes.routineNew);
    await _pick(tester, ['Bench Press']);

    Text value() =>
        tester.widget<Text>(find.byKey(const ValueKey('sets-value-1')));
    IconButton decrease() => tester.widget<IconButton>(
      find.byKey(const ValueKey('sets-decrease-1')),
    );

    expect(value().data, '3');
    await _tapKey(tester, 'sets-decrease-1');
    await _tapKey(tester, 'sets-decrease-1');

    expect(value().data, '1');
    expect(decrease().onPressed, isNull);
  });

  testWidgets('cannot add a 16th exercise', (tester) async {
    final exercises = [
      for (var i = 0; i < 16; i++)
        fakeExercise(id: '$i', name: 'Exercise $i', primaryMuscle: 'chest'),
    ];
    await pumpRoutineApp(
      tester,
      location: AppRoutes.routineNew,
      exercises: exercises,
      size: const Size(400, 2000),
    );
    await _openPicker(tester);

    for (var i = 0; i < 15; i++) {
      await tester.tap(find.text('Exercise $i'));
      await tester.pump();
    }
    expect(find.text('Add exercises (15/15)'), findsOneWidget);

    await tester.tap(find.text('Exercise 15'));
    await tester.pumpAndSettle();

    expect(
      find.text('A routine can have at most 15 exercises.'),
      findsOneWidget,
    );
    expect(find.text('Add exercises (15/15)'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsNWidgets(15));
  });

  testWidgets('the picker uses search and muscle chips and can unselect', (
    tester,
  ) async {
    await pumpRoutineApp(tester, location: AppRoutes.routineNew);
    await _openPicker(tester);

    expect(find.byType(ExercisePickerScreen), findsOneWidget);
    expect(find.text(fakeAttribution), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, 'BARBELL');
    await tester.pump();
    expect(find.text('Bench Press'), findsOneWidget);
    expect(find.text('Lat Pulldown'), findsNothing);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Legs'));
    await tester.pump();
    expect(find.text('Barbell Squat'), findsOneWidget);
    expect(find.text('Bench Press'), findsNothing);

    await tester.tap(find.text('Barbell Squat'));
    await tester.pump();
    expect(find.text('Add exercises (1/15)'), findsOneWidget);

    await tester.tap(find.text('Barbell Squat'));
    await tester.pump();
    expect(find.text('Add exercises (0/15)'), findsOneWidget);
  });

  testWidgets('shows a message when the routine cannot be saved', (
    tester,
  ) async {
    await pumpRoutineApp(
      tester,
      location: AppRoutes.routineNew,
      repository: _FailingRepository(),
    );
    await tester.enterText(_nameField, 'Push day');
    await _pick(tester, ['Bench Press']);

    await tester.tap(_save);
    await tester.pumpAndSettle();

    expect(
      find.text('Could not save the routine. Please try again.'),
      findsOneWidget,
    );
    expect(find.byType(RoutineCreateScreen), findsOneWidget);
    expect(_saveEnabled(tester), isTrue);
  });

  testWidgets('shows a message when the Routine constructor throws', (
    tester,
  ) async {
    final repository = FakeRoutineRepository();
    await pumpRoutineApp(
      tester,
      location: AppRoutes.routineNew,
      repository: repository,
      overrides: [routineDraftProvider.overrideWith(_OverfullDraft.new)],
      size: const Size(400, 3000),
    );

    await tester.tap(_save);
    await tester.pumpAndSettle();

    expect(
      find.text('Could not save the routine. Please try again.'),
      findsOneWidget,
    );
    expect(await repository.watch().first, isEmpty);
  });

  testWidgets('fits a small phone with a long exercise name', (tester) async {
    await pumpRoutineApp(
      tester,
      location: AppRoutes.routineNew,
      exercises: [
        fakeExercise(
          id: '1',
          name: 'Very Long Alternating Incline Dumbbell Press Variation',
          primaryMuscle: 'chest',
        ),
      ],
      size: const Size(320, 568),
    );

    await _openPicker(tester);
    await tester.tap(find.textContaining('Very Long'));
    await tester.pump();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Very Long'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
