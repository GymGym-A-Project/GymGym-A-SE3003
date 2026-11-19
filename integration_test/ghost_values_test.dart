import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:gymgym_a/app.dart';
import 'package:gymgym_a/core/firebase_bootstrap.dart';
import 'package:gymgym_a/core/router.dart';
import 'package:gymgym_a/firebase_options.dart';
import 'package:gymgym_a/data/models/set_entry.dart';
import 'package:gymgym_a/data/models/workout_session.dart';
import 'package:gymgym_a/data/repositories/firestore_workout_session_repository.dart';
import 'package:gymgym_a/features/logger/active_workout.dart';
import 'package:gymgym_a/features/logger/ghost_values.dart';
import 'package:gymgym_a/features/logger/workout_draft_store.dart';

/// Production bootstrap deliberately rejects profile emulator builds. This
/// dedicated test may profile native cache reads, but only after explicitly
/// selecting both local services, before any account or document operation.
Future<void> _initializeLocalTest() async {
  expect(const bool.fromEnvironment('USE_FIREBASE_EMULATORS'), isTrue);
  expect(kReleaseMode, isFalse);
  if (!kProfileMode) {
    await initializeFirebase();
    return;
  }
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  const configured = String.fromEnvironment('FIREBASE_EMULATOR_HOST');
  const host = configured == '' ? '10.0.2.2' : configured;
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );
  FirebaseFirestore.instance.useFirestoreEmulator(
    host,
    8080,
    automaticHostMapping: false,
  );
  await FirebaseAuth.instance.useAuthEmulator(
    host,
    9099,
    automaticHostMapping: false,
  );
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('60-session offline ghost lookup and finish summary', (
    tester,
  ) async {
    await _initializeLocalTest();
    final db = FirebaseFirestore.instance;
    final auth = FirebaseAuth.instance;
    expect(db.settings.host, endsWith(':8080'));
    await auth.createUserWithEmailAndPassword(
      email: 'ghost-${DateTime.now().microsecondsSinceEpoch}@example.com',
      password: 'GymGym-test-123!',
    );
    final uid = auth.currentUser!.uid;
    final repository = FirestoreWorkoutSessionRepository(db, uid);
    final before = DateTime.now().toUtc();
    final routine = db.doc('users/$uid/routines/ghost-check');
    ProviderContainer? container;
    String? savedId;
    try {
      for (var i = 0; i < 60; i++) {
        final start = before.subtract(Duration(days: 60 - i));
        await repository.save(
          WorkoutSession(
            id: 'history-$i',
            routineId: 'past',
            startedAt: start,
            finishedAt: start.add(const Duration(minutes: 30)),
            exercises: [
              WorkoutExercise(
                exerciseId: '0025',
                sets: [SetEntry(weightKg: 20 + i.toDouble(), reps: 8)],
              ),
              WorkoutExercise(
                exerciseId: '0030',
                sets: [SetEntry(weightKg: 0, reps: 12)],
              ),
            ],
          ),
        );
      }
      await routine.set({
        'id': 'ghost-check',
        'name': 'Ghost acceptance',
        'order': 0,
        'source': 'custom',
        'updatedAt': Timestamp.now(),
        'items': [
          {'exerciseId': '0025', 'targetSets': 1},
        ],
      });
      await db.waitForPendingWrites();
      await db.disableNetwork();
      final timings = <int>[];
      for (var run = 0; run < 10; run++) {
        final timer = Stopwatch()..start();
        final history = await repository.getCached();
        final hints = previousSets(history, before: before);
        timer.stop();
        expect(history, hasLength(60));
        expect(hints['0025']!.single.weightKg, 79);
        timings.add(timer.elapsedMicroseconds);
      }
      timings.sort();
      final medianUs = (timings[4] + timings[5]) / 2;
      debugPrint(
        'GHOST_NATIVE_TIMING mode=${kProfileMode ? "profile" : "debug"} sessions=60 medianUs=$medianUs samplesUs=$timings',
      );
      expect(medianUs, lessThan(200000));

      container = ProviderContainer();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const GymGymApp(),
        ),
      );
      await tester.pumpAndSettle();
      container
          .read(appRouterProvider)
          .go(AppRoutes.routineDetail('ghost-check'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('start-workout')));
      await tester.pumpAndSettle();
      final weightField = tester.widget<TextField>(
        find.descendant(
          of: find.byKey(const ValueKey('weight-0025-0')),
          matching: find.byType(TextField),
        ),
      );
      expect(weightField.controller!.text, '');
      expect(weightField.decoration!.hintText, '79');
      await tester.tap(find.byKey(const ValueKey('complete-0025-0')));
      await tester.pumpAndSettle();
      expect(container.read(activeWorkoutProvider(uid)).value!.isValid, isTrue);
      await container.read(activeWorkoutProvider(uid).notifier).flush();
      final accepted = container.read(activeWorkoutProvider(uid)).value!;
      expect(accepted.exercises.single.sets.single.weight, '79');
      expect(accepted.exercises.single.sets.single.reps, '8');
      savedId = container.read(activeWorkoutProvider(uid)).value!.id;
      final saveTimer = Stopwatch()..start();
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('finish-workout')),
        150,
        scrollable: find
            .descendant(
              of: find.byKey(const ValueKey('workout-inputs')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.tap(find.byKey(const ValueKey('finish-workout')));
      await container.read(activeWorkoutProvider(uid).notifier).flush();
      await tester.pumpAndSettle();
      saveTimer.stop();
      expect(find.text('Workout complete'), findsOneWidget);
      expect(find.text('632 kg'), findsOneWidget);
      expect(find.text('Total sets'), findsOneWidget);
      debugPrint(
        'GHOST_STRESS_FINISH mode=${kProfileMode ? "profile" : "debug"} uiMs=${saveTimer.elapsedMilliseconds}',
      );
      expect(saveTimer.elapsedMilliseconds, lessThan(1000));
      await tester.tap(find.text('View history'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Ghost acceptance'), findsWidgets);
      expect(await repository.getCached(), hasLength(61));
      await db.enableNetwork();
      await db.waitForPendingWrites();
      expect(
        (await db
                .doc('users/$uid/workouts/$savedId')
                .get(const GetOptions(source: Source.server)))
            .data()!['totalVolume'],
        632,
      );
    } finally {
      await db.enableNetwork();
      final cleanup = db.batch();
      for (var i = 0; i < 60; i++) {
        cleanup.delete(db.doc('users/$uid/workouts/history-$i'));
      }
      if (savedId != null) {
        cleanup.delete(db.doc('users/$uid/workouts/$savedId'));
      }
      cleanup.delete(routine);
      await cleanup.commit();
      if (container != null) {
        await container.read(workoutDraftStoreProvider).write(uid, null);
        await tester.pumpWidget(const SizedBox.shrink());
        container.dispose();
      }
      repository.dispose();
      await auth.currentUser?.delete();
      await auth.signOut();
    }
  });
}
