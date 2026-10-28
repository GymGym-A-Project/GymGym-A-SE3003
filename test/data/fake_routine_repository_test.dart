import 'package:flutter_test/flutter_test.dart';
import 'package:gymgym_a/data/models/routine.dart';
import 'package:gymgym_a/data/models/routine_item.dart';
import 'package:gymgym_a/data/repositories/fake_routine_repository.dart';
import 'package:gymgym_a/data/repositories/routine_repository.dart';

Routine routine(String id, {int order = 0, String name = 'Workout'}) => Routine(
  id: id,
  name: name,
  order: order,
  items: [
    RoutineItem(exerciseId: 'z', targetSets: 3),
    RoutineItem(exerciseId: 'a', targetSets: 2),
  ],
  source: 'starter:ppl',
  updatedAt: DateTime.utc(2026, 10, 28),
);

void main() {
  test(
    'watch starts with current state, including saves before listening',
    () async {
      final repository = FakeRoutineRepository();
      final stream = repository.watch();
      await repository.save(routine('a'));
      expect((await stream.first).single.id, 'a');
      expect(await FakeRoutineRepository().watch().first, isEmpty);
    },
  );

  test('get, replace, delete and absent ids follow the contract', () async {
    final RoutineRepository repository = FakeRoutineRepository();
    expect(await repository.get('a'), isNull);
    await repository.save(routine('a'));
    await repository.save(routine('a', name: 'Updated'));
    final saved = (await repository.get('a'))!;
    expect(saved.name, 'Updated');
    expect(saved.items.map((item) => item.exerciseId), ['z', 'a']);
    expect(saved.source, 'starter:ppl');
    expect(saved.updatedAt, DateTime.utc(2026, 10, 28));
    expect(await repository.watch().first, hasLength(1));
    await repository.delete('a');
    await repository.delete('missing');
    expect(await repository.get('a'), isNull);
  });

  test('sorts routines with stable ties and immutable snapshots', () async {
    final repository = FakeRoutineRepository(
      routines: [routine('b', order: 1), routine('a'), routine('c', order: 1)],
    );
    final before = await repository.watch().first;
    expect(before.map((r) => r.id), ['a', 'b', 'c']);
    expect(() => before.clear(), throwsUnsupportedError);
    await repository.save(routine('b', order: 1, name: 'Updated'));
    expect((await repository.watch().first).map((r) => r.id), ['a', 'b', 'c']);
    expect(before[1].name, 'Workout');
  });

  test(
    'each listener receives initial state, save, update and delete',
    () async {
      final repository = FakeRoutineRepository();
      final expected = [
        isEmpty,
        predicate<List<Routine>>((r) => r.single.name == 'Workout'),
        predicate<List<Routine>>((r) => r.single.name == 'Updated'),
        isEmpty,
      ];
      final first = expectLater(
        repository.watch().take(4),
        emitsInOrder(expected),
      );
      final second = expectLater(
        repository.watch().take(4),
        emitsInOrder(expected),
      );
      await repository.save(routine('a'));
      await repository.save(routine('a', name: 'Updated'));
      await repository.delete('a');
      await Future.wait([first, second]);
    },
  );

  test('repository instances have independent user scopes', () async {
    final first = FakeRoutineRepository();
    final second = FakeRoutineRepository();
    await first.save(routine('a'));
    expect(await second.get('a'), isNull);
    expect(await second.watch().first, isEmpty);
  });

  test(
    'changing routine order moves it without reordering exercises',
    () async {
      final repository = FakeRoutineRepository(
        routines: [routine('a'), routine('b', order: 1)],
      );
      await repository.save(routine('b', order: -1));
      final snapshot = await repository.watch().first;
      expect(snapshot.map((r) => r.id), ['b', 'a']);
      expect(snapshot.first.items.map((item) => item.exerciseId), ['z', 'a']);
    },
  );

  test('canceling one listener leaves other listeners active', () async {
    final repository = FakeRoutineRepository();
    final canceled = repository.watch().listen((_) {});
    await canceled.cancel();
    final remaining = expectLater(
      repository.watch().take(2),
      emitsInOrder([isEmpty, hasLength(1)]),
    );
    await repository.save(routine('a'));
    await remaining;
  });
}
