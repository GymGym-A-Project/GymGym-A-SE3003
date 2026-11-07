import 'package:flutter_test/flutter_test.dart';
import 'package:gymgym_a/data/models/routine.dart';
import 'package:gymgym_a/data/models/routine_item.dart';
import 'package:gymgym_a/data/repositories/fake_routine_repository.dart';
import 'package:gymgym_a/features/routines/routine_create_screen.dart';
import 'package:gymgym_a/features/routines/routine_detail_screen.dart';

import '../../helpers/routine_app.dart';

Routine _routine(String id, String name, int order, int exercises) => Routine(
  id: id,
  name: name,
  order: order,
  items: [
    for (var i = 0; i < exercises; i++)
      RoutineItem(exerciseId: '$i', targetSets: 3),
  ],
  source: 'custom',
  updatedAt: DateTime.utc(2026, 11, 5),
);

void main() {
  testWidgets('shows the empty state and a create button', (tester) async {
    await pumpRoutineApp(tester);

    expect(find.text('No routines yet'), findsOneWidget);
    expect(find.text('New routine'), findsOneWidget);
  });

  testWidgets('lists routines with name and exercise count, in order', (
    tester,
  ) async {
    await pumpRoutineApp(
      tester,
      repository: FakeRoutineRepository(
        routines: [_routine('b', 'Pull', 1, 1), _routine('a', 'Push', 0, 2)],
      ),
    );

    expect(find.text('No routines yet'), findsNothing);
    expect(find.text('2 exercises'), findsOneWidget);
    expect(find.text('1 exercise'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Push')).dy,
      lessThan(tester.getTopLeft(find.text('Pull')).dy),
    );
  });

  testWidgets('the create button opens the create screen', (tester) async {
    await pumpRoutineApp(tester);

    await tester.tap(find.text('New routine'));
    await tester.pumpAndSettle();

    expect(find.byType(RoutineCreateScreen), findsOneWidget);
    expect(find.byType(RoutineDetailScreen), findsNothing);
  });

  testWidgets('tapping a routine opens its view', (tester) async {
    await pumpRoutineApp(
      tester,
      repository: FakeRoutineRepository(
        routines: [_routine('a', 'Push', 0, 1)],
      ),
    );

    await tester.tap(find.text('Push'));
    await tester.pumpAndSettle();

    expect(find.byType(RoutineDetailScreen), findsOneWidget);
  });

  testWidgets('dragging a routine updates its order and the display order', (
    tester,
  ) async {
    final repository = FakeRoutineRepository(
      routines: [
        _routine('a', 'Push', 0, 1),
        _routine('b', 'Pull', 1, 1),
        _routine('c', 'Legs', 2, 1),
      ],
    );
    await pumpRoutineApp(tester, repository: repository);

    await dragHandle(tester, 'drag-a', 160);

    final saved = await repository.watch().first;
    expect(saved.map((r) => r.id), ['b', 'c', 'a']);
    expect(saved.map((r) => r.order), [0, 1, 2]);
    final pull = tester.getTopLeft(find.text('Pull')).dy;
    final legs = tester.getTopLeft(find.text('Legs')).dy;
    final push = tester.getTopLeft(find.text('Push')).dy;
    expect(pull, lessThan(legs));
    expect(legs, lessThan(push));
  });

  testWidgets('dropping a routine in place saves nothing', (tester) async {
    final repository = FakeRoutineRepository(
      routines: [_routine('a', 'Push', 0, 1), _routine('b', 'Pull', 1, 1)],
    );
    await pumpRoutineApp(tester, repository: repository);

    await dragHandle(tester, 'drag-a', 2);

    final saved = await repository.watch().first;
    expect(saved.map((r) => r.id), ['a', 'b']);
    expect(saved.first.updatedAt, DateTime.utc(2026, 11, 5));
  });
}
