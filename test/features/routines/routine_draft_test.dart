import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
}
