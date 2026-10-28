import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gymgym_a/data/models/routine.dart';
import 'package:gymgym_a/data/models/routine_item.dart';

Routine makeRoutine({String name = 'Push', int count = 1}) => Routine(
  id: 'push',
  name: name,
  order: 0,
  items: List.generate(
    count,
    (i) => RoutineItem(exerciseId: 'exercise-$i', targetSets: 3),
  ),
  source: 'custom',
  updatedAt: DateTime.utc(2026, 10, 28),
);

void main() {
  test('accepts 1 and 15 exercises; rejects 0 and 16', () {
    for (final count in [1, 15]) {
      expect(makeRoutine(count: count).items, hasLength(count));
    }
    for (final count in [0, 16]) {
      expect(() => makeRoutine(count: count), throwsArgumentError);
    }
  });

  test('rejects empty and whitespace-only names', () {
    for (final name in ['', ' \t\n']) {
      expect(() => makeRoutine(name: name), throwsArgumentError);
    }
  });

  test('requires positive targetSets', () {
    for (final sets in [0, -1]) {
      expect(
        () => RoutineItem(exerciseId: 'bench', targetSets: sets),
        throwsArgumentError,
      );
    }
    expect(RoutineItem(exerciseId: 'bench', targetSets: 1).targetSets, 1);
  });

  test('copies items and prevents mutation', () {
    final items = [RoutineItem(exerciseId: 'bench', targetSets: 3)];
    final routine = Routine(
      id: 'push',
      name: 'Push',
      order: 0,
      items: items,
      source: 'custom',
      updatedAt: DateTime.utc(2026),
    );
    items.clear();
    expect(routine.items.single.exerciseId, 'bench');
    expect(() => routine.items.clear(), throwsUnsupportedError);
  });

  test('JSON round-trip preserves fields, source, and exercise order', () {
    for (final source in ['custom', 'starter:ppl']) {
      final json = makeRoutine(count: 3).toJson()..['source'] = source;
      final copy = Routine.fromJson(
        jsonDecode(jsonEncode(json)) as Map<String, dynamic>,
      );
      expect(copy.toJson(), json);
      expect(copy.items.map((item) => item.exerciseId), [
        'exercise-0',
        'exercise-1',
        'exercise-2',
      ]);
    }
  });

  test('serializes timestamps as UTC and validates decoded data', () {
    final json = makeRoutine().toJson()
      ..['updatedAt'] = '2026-10-28T12:00:00+03:00';
    expect(
      Routine.fromJson(json).toJson()['updatedAt'],
      '2026-10-28T09:00:00.000Z',
    );
    expect(() => Routine.fromJson({...json, 'name': ' '}), throwsArgumentError);
    expect(() => Routine.fromJson({...json, 'items': []}), throwsArgumentError);
    expect(
      () => RoutineItem.fromJson({'exerciseId': 'bench', 'targetSets': 0}),
      throwsArgumentError,
    );
  });
}
