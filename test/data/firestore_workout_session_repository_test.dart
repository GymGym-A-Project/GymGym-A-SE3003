import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymgym_a/data/models/set_entry.dart';
import 'package:gymgym_a/data/models/workout_session.dart';
import 'package:gymgym_a/data/repositories/firestore_workout_session_repository.dart';

final _startedAt = DateTime.utc(2026, 11, 10, 18, 0, 5, 250);
final _finishedAt = DateTime.utc(2026, 11, 10, 19, 2, 30);

WorkoutSession _session(
  String id, {
  DateTime? startedAt,
  DateTime? finishedAt,
  double weightKg = 60,
}) => WorkoutSession(
  id: id,
  routineId: 'push',
  startedAt: startedAt ?? _startedAt,
  finishedAt: finishedAt,
  exercises: [
    WorkoutExercise(
      exerciseId: '0025',
      sets: [
        SetEntry(weightKg: weightKg, reps: 8),
        SetEntry(weightKg: 62.5, reps: 6),
      ],
    ),
    WorkoutExercise(
      exerciseId: '0030',
      sets: [SetEntry(weightKg: 0, reps: 12)],
    ),
  ],
);

void main() {
  late FakeFirebaseFirestore firestore;
  late FirestoreWorkoutSessionRepository repository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = FirestoreWorkoutSessionRepository(firestore, 'user-a');
  });

  test(
    'save and get round trip every field in exercise and set order',
    () async {
      await repository.save(_session('w1', finishedAt: _finishedAt));

      final saved = (await repository.get('w1'))!;
      expect(saved.id, 'w1');
      expect(saved.routineId, 'push');
      expect(saved.startedAt, _startedAt);
      expect(saved.finishedAt, _finishedAt);
      expect(saved.exercises.map((e) => e.exerciseId), ['0025', '0030']);
      expect(saved.exercises.first.sets.map((s) => s.weightKg), [60, 62.5]);
      expect(saved.exercises.first.sets.map((s) => s.reps), [8, 6]);
      expect(saved.totalVolume, 60 * 8 + 62.5 * 6);
    },
  );

  test('an unfinished session keeps a null finishedAt', () async {
    await repository.save(_session('w1'));

    expect((await repository.get('w1'))!.finishedAt, isNull);
  });

  test('get returns null for an unknown id', () async {
    expect(await repository.get('nope'), isNull);
  });

  test('the document has exactly the keys the rules allow', () async {
    await repository.save(_session('w1', finishedAt: _finishedAt));

    final document = await firestore.doc('users/user-a/workouts/w1').get();
    final data = document.data()!;
    expect(data.keys.toSet(), {
      'id',
      'routineId',
      'startedAt',
      'finishedAt',
      'exerciseIds',
      'exercises',
      'totalVolume',
    });
    expect(data['startedAt'], Timestamp.fromDate(_startedAt));
    expect(data['finishedAt'], Timestamp.fromDate(_finishedAt));
    expect(data['exerciseIds'], ['0025', '0030']);
    expect(data['totalVolume'], 855);
  });

  test('timestamps are read back as UTC', () async {
    await repository.save(_session('w1', finishedAt: _finishedAt));

    final saved = (await repository.get('w1'))!;
    expect(saved.startedAt.isUtc, isTrue);
    expect(saved.finishedAt!.isUtc, isTrue);
  });

  test('watch sorts newest first, then by id', () async {
    final early = DateTime.utc(2026, 11, 1);
    final late = DateTime.utc(2026, 11, 9);
    await repository.save(_session('c', startedAt: late));
    await repository.save(_session('a', startedAt: early));
    await repository.save(_session('b', startedAt: late));

    final sessions = await repository.watch().first;
    expect(sessions.map((session) => session.id), ['b', 'c', 'a']);
  });

  test('watch emits later changes', () async {
    final ids = repository.watch().map(
      (sessions) => sessions.map((session) => session.id).toList(),
    );
    final expectation = expectLater(
      ids,
      emitsInOrder([
        <String>[],
        ['w1'],
        <String>[],
      ]),
    );
    await pumpEventQueue();

    await repository.save(_session('w1'));
    await pumpEventQueue();
    await repository.delete('w1');

    await expectation;
  });

  test('save replaces a session with the same id', () async {
    await repository.save(_session('w1'));
    await repository.save(_session('w1', weightKg: 70));

    final saved = (await repository.get('w1'))!;
    expect(saved.exercises.first.sets.first.weightKg, 70);
    expect(await repository.watch().first, hasLength(1));
  });

  test('one user cannot see the sessions of another user', () async {
    final other = FirestoreWorkoutSessionRepository(firestore, 'user-b');
    await repository.save(_session('w1'));

    expect(await other.get('w1'), isNull);
    expect(await other.watch().first, isEmpty);

    await other.delete('w1');
    expect(await repository.get('w1'), isNotNull);
  });
}
