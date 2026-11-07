import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymgym_a/data/models/routine.dart';
import 'package:gymgym_a/data/models/routine_item.dart';
import 'package:gymgym_a/data/repositories/firestore_routine_repository.dart';

final _updatedAt = DateTime.utc(2026, 11, 7, 12, 30, 15, 250);

Routine _routine(String id, {int order = 0, String name = 'Push'}) => Routine(
  id: id,
  name: name,
  order: order,
  items: [
    RoutineItem(exerciseId: '0025', targetSets: 3),
    RoutineItem(exerciseId: '0030', targetSets: 5),
  ],
  source: 'custom',
  updatedAt: _updatedAt,
);

void main() {
  late FakeFirebaseFirestore firestore;
  late FirestoreRoutineRepository repository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = FirestoreRoutineRepository(firestore, 'user-a');
  });

  test('save and get round trip every field in item order', () async {
    await repository.save(_routine('r1', order: 2));

    final saved = (await repository.get('r1'))!;
    expect(saved.id, 'r1');
    expect(saved.name, 'Push');
    expect(saved.order, 2);
    expect(saved.source, 'custom');
    expect(saved.updatedAt, _updatedAt);
    expect(saved.items.map((item) => item.exerciseId), ['0025', '0030']);
    expect(saved.items.map((item) => item.targetSets), [3, 5]);
  });

  test('get returns null for an unknown id', () async {
    expect(await repository.get('nope'), isNull);
  });

  test('save replaces a routine with the same id', () async {
    await repository.save(_routine('r1'));
    await repository.save(_routine('r1', name: 'Heavy push'));

    expect((await repository.get('r1'))!.name, 'Heavy push');
    expect(await repository.watch().first, hasLength(1));
  });

  test('the document has exactly the keys the rules allow', () async {
    await repository.save(_routine('r1'));

    final document = await firestore.doc('users/user-a/routines/r1').get();
    final data = document.data()!;
    expect(data.keys.toSet(), {
      'id',
      'name',
      'order',
      'items',
      'source',
      'updatedAt',
    });
    expect(data['id'], 'r1');
    expect(data['order'], isA<int>());
    expect(data['items'], [
      {'exerciseId': '0025', 'targetSets': 3},
      {'exerciseId': '0030', 'targetSets': 5},
    ]);
  });

  test('updatedAt is stored as a Timestamp and read back as UTC', () async {
    await repository.save(_routine('r1'));

    final document = await firestore.doc('users/user-a/routines/r1').get();
    expect(document.data()!['updatedAt'], Timestamp.fromDate(_updatedAt));
    expect((await repository.get('r1'))!.updatedAt.isUtc, isTrue);
  });

  test('watch sorts by order, then by id', () async {
    await repository.save(_routine('c', order: 1));
    await repository.save(_routine('b', order: 1));
    await repository.save(_routine('a', order: 2));
    await repository.save(_routine('d', order: 0));

    final routines = await repository.watch().first;
    expect(routines.map((routine) => routine.id), ['d', 'b', 'c', 'a']);
  });

  test('watch emits later changes', () async {
    final snapshots = repository.watch().map(
      (routines) => routines.map((routine) => routine.id).toList(),
    );
    final expectation = expectLater(
      snapshots,
      emitsInOrder([
        <String>[],
        ['r1'],
        <String>[],
      ]),
    );
    await pumpEventQueue();

    await repository.save(_routine('r1'));
    await pumpEventQueue();
    await repository.delete('r1');

    await expectation;
  });

  test('delete removes the routine and ignores an absent id', () async {
    await repository.save(_routine('r1'));

    await repository.delete('r1');
    await repository.delete('nope');

    expect(await repository.get('r1'), isNull);
    expect(await repository.watch().first, isEmpty);
  });

  test('one user cannot see the routines of another user', () async {
    final other = FirestoreRoutineRepository(firestore, 'user-b');
    await repository.save(_routine('r1'));

    expect(await other.get('r1'), isNull);
    expect(await other.watch().first, isEmpty);

    await other.delete('r1');
    expect(await repository.get('r1'), isNotNull);
  });
}
