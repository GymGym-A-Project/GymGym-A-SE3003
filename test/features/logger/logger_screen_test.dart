import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymgym_a/core/router.dart';
import 'package:gymgym_a/data/repositories/fake_routine_repository.dart';
import 'package:gymgym_a/data/repositories/fake_workout_session_repository.dart';
import 'package:gymgym_a/data/repositories/workout_session_providers.dart';
import 'package:gymgym_a/data/repositories/workout_session_repository.dart';
import 'package:gymgym_a/data/models/workout_session.dart';
import 'package:gymgym_a/features/logger/workout_draft_store.dart';

import '../../helpers/memory_workout_draft_store.dart';
import '../../helpers/routine_app.dart';
import 'active_workout_test.dart' show routine;

class RejectOnceRepository extends FakeWorkoutSessionRepository {
  final failures = StreamController<WorkoutWriteFailure>.broadcast();
  bool reject = true;
  @override
  Stream<WorkoutWriteFailure> get writeFailures => failures.stream;
  @override
  Future<void> save(WorkoutSession session) async {
    if (reject) {
      reject = false;
      failures.add(WorkoutWriteFailure(WorkoutWriteOperation.save, session.id));
    } else {
      await super.save(session);
    }
  }

  @override
  void dispose() {
    unawaited(failures.close());
    super.dispose();
  }
}

Future<void> pumpLogger(
  WidgetTester tester, {
  MemoryWorkoutDraftStore? store,
  FakeWorkoutSessionRepository? sessions,
  String location = '/routines/push',
  Size size = const Size(400, 1200),
}) => pumpRoutineApp(
  tester,
  location: location,
  size: size,
  repository: FakeRoutineRepository(routines: [routine(sets: 1)]),
  overrides: [
    workoutDraftStoreProvider.overrideWithValue(
      store ?? MemoryWorkoutDraftStore(),
    ),
    workoutSessionRepositoryProvider.overrideWithValue(
      sessions ?? FakeWorkoutSessionRepository(),
    ),
  ],
);

void main() {
  testWidgets(
    'server rejection is visible and the device copy can be retried',
    (tester) async {
      final sessions = RejectOnceRepository();
      addTearDown(sessions.dispose);
      await pumpLogger(tester, sessions: sessions);
      await tester.tap(find.byKey(const ValueKey('start-workout')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('weight-1-0')), '60');
      await tester.enterText(find.byKey(const ValueKey('reps-1-0')), '8');
      await tester.tap(find.byKey(const ValueKey('finish-workout')));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('The server could not save your workout.'),
        findsOneWidget,
      );
      expect(await sessions.watch().first, isEmpty);
      await tester.tap(find.text('Workout').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Retry saving workout'));
      await tester.pumpAndSettle();
      expect((await sessions.watch().first).single.totalVolume, 480);
    },
  );
  testWidgets('routine starts a workout; valid finish appears in history', (
    tester,
  ) async {
    final sessions = FakeWorkoutSessionRepository();
    await pumpLogger(tester, sessions: sessions);
    await tester.tap(find.byKey(const ValueKey('start-workout')));
    await tester.pumpAndSettle();
    expect(find.text('Push day'), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('weight-1-0')), '60');
    await tester.enterText(find.byKey(const ValueKey('reps-1-0')), '8');
    await tester.tap(find.byKey(const ValueKey('finish-workout')));
    await tester.pumpAndSettle();
    final saved = (await sessions.watch().first).single;
    expect(saved.totalVolume, 480);
    expect(saved.finishedAt, isNotNull);
    expect(find.textContaining('Push day'), findsWidgets);
    expect(find.text('No completed workouts yet'), findsNothing);
  });

  testWidgets('invalid input stays in the logger and no session is saved', (
    tester,
  ) async {
    final sessions = FakeWorkoutSessionRepository();
    await pumpLogger(tester, sessions: sessions);
    await tester.tap(find.byKey(const ValueKey('start-workout')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('weight-1-0')), '-1');
    await tester.enterText(find.byKey(const ValueKey('reps-1-0')), '2.5');
    await tester.tap(find.byKey(const ValueKey('finish-workout')));
    await tester.pumpAndSettle();
    expect(find.text('Enter kg of 0 or more.'), findsOneWidget);
    expect(find.text('Enter a whole number above 0.'), findsOneWidget);
    expect(await sessions.watch().first, isEmpty);
  });

  testWidgets(
    'shared picker adds and removes exercises without changing routine',
    (tester) async {
      await pumpLogger(tester);
      await tester.tap(find.byKey(const ValueKey('start-workout')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add exercises (1/15)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lat Pulldown'));
      await tester.pumpAndSettle();
      expect(find.text('Add exercises (2/15)'), findsOneWidget);
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(find.text('Lat Pulldown'), findsOneWidget);
      await tester.tap(find.byTooltip('Remove exercise').last);
      await tester.pumpAndSettle();
      expect(find.text('Lat Pulldown'), findsNothing);
    },
  );

  testWidgets('restart restores raw input and another start resumes it', (
    tester,
  ) async {
    final store = MemoryWorkoutDraftStore();
    await pumpLogger(tester, store: store);
    await tester.tap(find.byKey(const ValueKey('start-workout')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('weight-1-0')), '22.5');
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
    await pumpLogger(tester, store: store);
    await tester.tap(find.byKey(const ValueKey('start-workout')));
    await tester.pumpAndSettle();
    expect(find.text('Workout already in progress'), findsOneWidget);
    await tester.tap(find.text('Resume'));
    await tester.pumpAndSettle();
    expect(find.text('22.5'), findsOneWidget);
  });

  testWidgets('empty workout tab points to routines', (tester) async {
    await pumpLogger(tester, location: AppRoutes.logger);
    expect(find.text('No active workout'), findsOneWidget);
    await tester.tap(find.text('Choose a routine'));
    await tester.pumpAndSettle();
    expect(find.text('Push day'), findsOneWidget);
  });

  testWidgets('small phone fits validation messages and bodyweight input', (
    tester,
  ) async {
    final sessions = FakeWorkoutSessionRepository();
    await pumpLogger(tester, sessions: sessions, size: const Size(320, 640));
    await tester.tap(find.byKey(const ValueKey('start-workout')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('finish-workout')));
    await tester.tap(find.byKey(const ValueKey('finish-workout')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('weight-1-0')));
    await tester.enterText(find.byKey(const ValueKey('weight-1-0')), '0');
    await tester.enterText(find.byKey(const ValueKey('reps-1-0')), '12');
    tester.testTextInput.hide();
    await tester.ensureVisible(find.byKey(const ValueKey('finish-workout')));
    await tester.tap(find.byKey(const ValueKey('finish-workout')));
    await tester.pumpAndSettle();
    expect(find.text('No completed workouts yet'), findsNothing);
    expect((await sessions.watch().first).single.totalVolume, 0);
    expect(tester.takeException(), isNull);
  });
}
