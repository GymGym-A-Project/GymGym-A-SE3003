import 'package:flutter_test/flutter_test.dart';
import 'package:gymgym_a/data/models/routine.dart';
import 'package:gymgym_a/data/models/routine_item.dart';
import 'package:gymgym_a/features/routines/routine_order.dart';

final _old = DateTime.utc(2026, 11, 5);
final _now = DateTime.utc(2026, 11, 7);

Routine _routine(String id, int order) => Routine(
  id: id,
  name: id,
  order: order,
  items: [RoutineItem(exerciseId: '1', targetSets: 3)],
  source: 'starter:ppl',
  updatedAt: _old,
);

void main() {
  group('nextRoutineOrder', () {
    test('starts at 0', () {
      expect(nextRoutineOrder([]), 0);
    });

    test('does not collide after a routine was deleted', () {
      expect(nextRoutineOrder([_routine('b', 1), _routine('c', 2)]), 3);
    });
  });

  group('reorderRoutines', () {
    final routines = [_routine('a', 0), _routine('b', 1), _routine('c', 2)];

    test('moves down and numbers the list by position', () {
      final moved = reorderRoutines(routines, 0, 2, updatedAt: _now);

      expect(moved.map((r) => r.id), ['b', 'c', 'a']);
      expect(moved.map((r) => r.order), [0, 1, 2]);
    });

    test('moves up', () {
      final moved = reorderRoutines(routines, 2, 0, updatedAt: _now);

      expect(moved.map((r) => r.id), ['c', 'a', 'b']);
    });

    test('keeps untouched routines and only stamps the changed ones', () {
      final moved = reorderRoutines(routines, 1, 2, updatedAt: _now);

      expect(moved.first, same(routines.first));
      expect(moved[1].updatedAt, _now);
      expect(moved[2].updatedAt, _now);
    });

    test('keeps the other fields of a changed routine', () {
      final moved = reorderRoutines(routines, 0, 1, updatedAt: _now);

      expect(moved[1].id, 'a');
      expect(moved[1].source, 'starter:ppl');
      expect(moved[1].items.single.exerciseId, '1');
    });

    test('closes gaps left by a deleted routine', () {
      final gaps = [_routine('b', 1), _routine('c', 2), _routine('d', 3)];

      final moved = reorderRoutines(gaps, 2, 0, updatedAt: _now);

      expect(moved.map((r) => r.order), [0, 1, 2]);
    });
  });
}
