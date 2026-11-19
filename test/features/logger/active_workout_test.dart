import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymgym_a/data/models/routine.dart';
import 'package:gymgym_a/data/models/routine_item.dart';
import 'package:gymgym_a/data/models/workout_session.dart';
import 'package:gymgym_a/data/repositories/fake_workout_session_repository.dart';
import 'package:gymgym_a/features/logger/active_workout.dart';
import 'package:gymgym_a/features/logger/workout_draft.dart';
import 'package:gymgym_a/features/logger/workout_draft_store.dart';

import '../../helpers/memory_workout_draft_store.dart';

Routine routine({int sets = 2}) => Routine(
  id: 'push',
  name: 'Push day',
  order: 0,
  items: [RoutineItem(exerciseId: '1', targetSets: sets)],
  source: 'custom',
  updatedAt: DateTime.utc(2026),
);

class FailingRepository extends FakeWorkoutSessionRepository {
  @override
  Future<void> save(WorkoutSession session) async =>
      throw StateError('Cannot queue workout');
}

void main() {
  late MemoryWorkoutDraftStore store;
  late ProviderContainer container;
  late ActiveWorkout active;
  setUp(() async {
    store = MemoryWorkoutDraftStore();
    container = ProviderContainer(
      overrides: [workoutDraftStoreProvider.overrideWithValue(store)],
    );
    await container.read(activeWorkoutProvider('alice').future);
    active = container.read(activeWorkoutProvider('alice').notifier);
  });
  tearDown(() => container.dispose());

  test(
    'routine order and target sets are copied; empty fields stay empty',
    () async {
      await active.start(routine());
      final draft = container.read(activeWorkoutProvider('alice')).value!;
      expect(draft.exercises.single.sets, hasLength(2));
      expect(draft.exercises.single.sets.first.weight, '');
      expect(draft.isValid, isFalse);
      expect(() => draft.toSession(), throwsStateError);
    },
  );

  test(
    'raw input survives a new provider container and is isolated by uid',
    () async {
      await active.start(routine());
      await active.updateSet('1', '0', weight: '12,5', reps: 'not yet');
      final restored = ProviderContainer(
        overrides: [workoutDraftStoreProvider.overrideWithValue(store)],
      );
      addTearDown(restored.dispose);
      final draft = await restored.read(activeWorkoutProvider('alice').future);
      expect(draft!.exercises.single.sets.first.weight, '12,5');
      expect(draft.exercises.single.sets.first.reps, 'not yet');
      expect(await restored.read(activeWorkoutProvider('bob').future), isNull);
    },
  );

  test(
    'fast edits persist in order, not whichever write completes last',
    () async {
      await active.start(routine());
      await Future.wait([
        active.updateSet('1', '0', weight: '5'),
        active.updateSet('1', '0', weight: '50'),
        active.updateSet('1', '0', reps: '8'),
      ]);
      final set = (await store.read('alice'))!.exercises.single.sets.first;
      expect(set.weight, '50');
      expect(set.reps, '8');
    },
  );

  test(
    'exercise and set changes enforce one to fifteen distinct exercises',
    () async {
      await active.start(routine());
      expect(() => active.toggleExercise('1'), throwsStateError);
      for (var i = 2; i <= 15; i++) {
        await active.toggleExercise('$i');
      }
      expect(() => active.toggleExercise('16'), throwsStateError);
      await active.toggleExercise('15');
      await active.toggleExercise('16');
      await active.addSet('1');
      await active.removeSet('1', '0');
      final draft = container.read(activeWorkoutProvider('alice')).value!;
      expect(draft.exercises, hasLength(15));
      expect(draft.exercises.first.sets, hasLength(2));
      expect(draft.exercises.map((e) => e.exerciseId).toSet(), hasLength(15));
    },
  );

  test(
    'unfinished workout is not overwritten; discard removes persisted state',
    () async {
      await active.start(routine());
      await expectLater(active.start(routine()), throwsStateError);
      await active.discard();
      expect(await store.read('alice'), isNull);
      await active.start(routine());
    },
  );

  test(
    'finish validates all sets and derives volume; retry is idempotent',
    () async {
      final repository = FakeWorkoutSessionRepository();
      await active.start(routine());
      await expectLater(active.finish(repository), throwsStateError);
      await active.updateSet('1', '0', weight: '0', reps: '12');
      await active.updateSet('1', '1', weight: '12,5', reps: '8');
      await active.finish(repository);
      final completed = (await repository.watch().first).single;
      expect(completed.totalVolume, 100);
      expect(completed.finishedAt, isNotNull);
      expect(completed.finishedAt!.isBefore(completed.startedAt), isFalse);
      await active.finish(repository);
      expect(await repository.watch().first, hasLength(1));
      expect(
        (await repository.get(completed.id))!.finishedAt,
        completed.finishedAt,
      );
      expect((await store.read('alice'))!.finishedAt, completed.finishedAt);
      await active.start(
        routine(),
      ); // A completed workout does not block the next.
    },
  );

  test(
    'save failure retains a completed copy that can be retried after restart',
    () async {
      await active.start(routine(sets: 1));
      await active.updateSet('1', '0', weight: '60', reps: '8');
      await expectLater(active.finish(FailingRepository()), throwsStateError);
      final restored = ProviderContainer(
        overrides: [workoutDraftStoreProvider.overrideWithValue(store)],
      );
      addTearDown(restored.dispose);
      final saved = await restored.read(activeWorkoutProvider('alice').future);
      final repository = FakeWorkoutSessionRepository();
      await restored
          .read(activeWorkoutProvider('alice').notifier)
          .finish(repository);
      expect((await repository.get(saved!.id))!.totalVolume, 480);
    },
  );

  test(
    'device storage failure is reported and a subsequent edit can recover',
    () async {
      await active.start(routine());
      store.fail = true;
      await expectLater(
        active.updateSet('1', '0', weight: '20'),
        throwsStateError,
      );
      store.fail = false;
      await active.updateSet('1', '0', reps: '10');
      expect(
        (await store.read('alice'))!.exercises.single.sets.first.weight,
        '20',
      );
    },
  );

  test('kg must be finite/nonnegative and reps positive integers', () {
    for (final weight in ['', '-1', 'NaN', 'Infinity', '1e999']) {
      expect(
        WorkoutSetDraft(id: 's', weight: weight, reps: '8').isValid,
        isFalse,
      );
    }
    for (final reps in ['', '0', '-2', '2.5', 'abc']) {
      expect(
        WorkoutSetDraft(id: 's', weight: '0', reps: reps).isValid,
        isFalse,
      );
    }
    expect(
      const WorkoutSetDraft(id: 's', weight: '0', reps: '12').isValid,
      isTrue,
    );
  });
}
