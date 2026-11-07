import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymgym_a/data/models/routine.dart';
import 'package:gymgym_a/data/models/routine_item.dart';
import 'package:gymgym_a/features/routines/routine_draft.dart';

import '../../helpers/fake_exercises.dart';

void main() {
  late ProviderContainer container;
  late RoutineDraftNotifier notifier;

  RoutineDraft draft() => container.read(routineDraftProvider);

  setUp(() {
    container = ProviderContainer();
    addTearDown(container.dispose);
    container.listen(routineDraftProvider, (_, _) {});
    notifier = container.read(routineDraftProvider.notifier);
  });

  test('can save only with a name and at least one exercise', () {
    expect(draft().canSave, isFalse);

    notifier.rename('   ');
    notifier.add(fakeExercises.first);
    expect(draft().canSave, isFalse);

    notifier.rename('Push');
    expect(draft().canSave, isTrue);

    notifier.remove(fakeExercises.first.id);
    expect(draft().canSave, isFalse);
  });

  test('new exercises default to 3 sets and never go below 1', () {
    final id = fakeExercises.first.id;
    notifier.add(fakeExercises.first);
    expect(draft().items.single.targetSets, 3);

    notifier.changeTargetSets(id, 1);
    expect(draft().items.single.targetSets, 4);

    for (var i = 0; i < 10; i++) {
      notifier.changeTargetSets(id, -1);
    }
    expect(draft().items.single.targetSets, 1);
  });

  test('an exercise is added only once', () {
    expect(notifier.add(fakeExercises.first), isTrue);
    expect(notifier.add(fakeExercises.first), isTrue);

    expect(draft().items, hasLength(1));
  });

  test('the 16th exercise is rejected', () {
    for (var i = 0; i < 15; i++) {
      final exercise = fakeExercise(
        id: '$i',
        name: 'Exercise $i',
        primaryMuscle: 'chest',
      );
      expect(notifier.add(exercise), isTrue);
    }

    final extra = fakeExercise(id: 'x', name: 'X', primaryMuscle: 'chest');
    expect(notifier.add(extra), isFalse);
    expect(draft().items, hasLength(15));
    expect(draft().contains('x'), isFalse);
  });

  test('toRoutine trims the name and keeps the selected order', () {
    notifier.rename('  Push  ');
    notifier.add(fakeExercises[1]);
    notifier.add(fakeExercises[0]);
    notifier.changeTargetSets(fakeExercises[0].id, 2);
    final updatedAt = DateTime.utc(2026, 11, 5);

    final routine = draft().toRoutine(id: 'r', order: 4, updatedAt: updatedAt);

    expect(routine.id, 'r');
    expect(routine.name, 'Push');
    expect(routine.order, 4);
    expect(routine.source, 'custom');
    expect(routine.updatedAt, updatedAt);
    expect(routine.items.map((item) => item.exerciseId), ['2', '1']);
    expect(routine.items.map((item) => item.targetSets), [3, 5]);
  });

  test('toRoutine throws when the draft breaks a Routine rule', () {
    expect(
      () => const RoutineDraft().toRoutine(
        id: 'r',
        order: 0,
        updatedAt: DateTime.utc(2026, 11, 5),
      ),
      throwsArgumentError,
    );
  });

  test('new ids are different even when created back to back', () {
    final ids = {for (var i = 0; i < 100; i++) newRoutineId()};

    expect(ids, hasLength(100));
  });

  group('editing', () {
    Routine routine(List<RoutineItem> items) => Routine(
      id: 'r1',
      name: 'Push',
      order: 4,
      items: items,
      source: 'starter:ppl',
      updatedAt: DateTime.utc(2026, 11, 5),
    );

    List<String> ids() => draft().items.map((i) => i.exercise.id).toList();

    test('a draft of a routine keeps name, order of items and sets', () {
      final loaded = RoutineDraft.fromRoutine(
        routine([
          RoutineItem(exerciseId: '3', targetSets: 5),
          RoutineItem(exerciseId: '1', targetSets: 2),
        ]),
        fakeExercises,
      );

      expect(loaded.name, 'Push');
      expect(loaded.items.map((item) => item.exercise.name), [
        'Barbell Squat',
        'Bench Press',
      ]);
      expect(loaded.items.map((item) => item.targetSets), [5, 2]);
    });

    test('a repeated exercise of a routine is loaded once', () {
      final loaded = RoutineDraft.fromRoutine(
        routine([
          RoutineItem(exerciseId: '1', targetSets: 5),
          RoutineItem(exerciseId: '1', targetSets: 2),
        ]),
        fakeExercises,
      );

      expect(loaded.items.single.targetSets, 5);
    });

    test('move changes the item order', () {
      fakeExercises.forEach(notifier.add);

      notifier.move(0, 2);
      expect(ids(), ['2', '3', '1']);

      notifier.move(2, 0);
      expect(ids(), ['1', '2', '3']);
    });

    test('toRoutine can keep the source of an edited routine', () {
      notifier.rename('Push');
      notifier.add(fakeExercises.first);

      final saved = draft().toRoutine(
        id: 'r1',
        order: 4,
        updatedAt: DateTime.utc(2026, 11, 7),
        source: 'starter:ppl',
      );

      expect(saved.source, 'starter:ppl');
    });
  });
}
