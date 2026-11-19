// Paced recording harness, deliberately opt-in; not a performance benchmark.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:gymgym_a/app.dart';
import 'package:gymgym_a/core/firebase_bootstrap.dart';
import 'package:gymgym_a/core/router.dart';
import 'package:gymgym_a/data/models/set_entry.dart';
import 'package:gymgym_a/data/models/workout_session.dart';
import 'package:gymgym_a/data/repositories/firestore_workout_session_repository.dart';
import 'package:gymgym_a/features/logger/active_workout.dart';
import 'package:gymgym_a/features/logger/workout_draft_store.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('M3 Android demo: routine to completed workout and History', (
    tester,
  ) async {
    expect(kDebugMode, isTrue);
    expect(const bool.fromEnvironment('USE_FIREBASE_EMULATORS'), isTrue);
    await initializeFirebase();
    final db = FirebaseFirestore.instance;
    expect(db.settings.host, endsWith(':8080'));
    final auth = FirebaseAuth.instance;
    await auth.createUserWithEmailAndPassword(
      email: 'm3-demo-${DateTime.now().microsecondsSinceEpoch}@example.com',
      password: 'Local-demo-123!',
    );
    final uid = auth.currentUser!.uid;
    final repository = FirestoreWorkoutSessionRepository(db, uid);
    final routine = db.doc('users/$uid/routines/m3-demo');
    final history = db.collection('users/$uid/workouts');
    ProviderContainer? container;
    Future<void> pause(String marker, [int seconds = 4]) async {
      debugPrint('M3_DEMO_$marker');
      await Future<void>.delayed(Duration(seconds: seconds));
    }

    try {
      final previousStart = DateTime.now().toUtc().subtract(
        const Duration(days: 2),
      );
      await repository.save(
        WorkoutSession(
          id: 'previous-demo-session',
          routineId: 'm3-demo',
          startedAt: previousStart,
          finishedAt: previousStart.add(const Duration(minutes: 25)),
          exercises: [
            WorkoutExercise(
              exerciseId: '0025',
              sets: [SetEntry(weightKg: 60, reps: 8)],
            ),
          ],
        ),
      );
      await routine.set({
        'id': 'm3-demo',
        'name': 'M3 Demo Workout',
        'order': 0,
        'source': 'custom',
        'updatedAt': Timestamp.now(),
        'items': [
          {'exerciseId': '0025', 'targetSets': 1},
        ],
      });
      await db.waitForPendingWrites();
      container = ProviderContainer();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const GymGymApp(),
        ),
      );
      await tester.pumpAndSettle();
      container.read(appRouterProvider).go(AppRoutes.routines);
      await tester.pumpAndSettle();
      expect(find.text('M3 Demo Workout'), findsOneWidget);
      await pause('READY', 12); // Allows the host to start adb screenrecord.
      await tester.tap(find.text('M3 Demo Workout'));
      await tester.pumpAndSettle();
      await pause('ROUTINE');
      await tester.tap(find.byKey(const ValueKey('start-workout')));
      await tester.pumpAndSettle();
      final input = tester.widget<TextField>(
        find.descendant(
          of: find.byKey(const ValueKey('weight-0025-0')),
          matching: find.byType(TextField),
        ),
      );
      expect(input.controller!.text, '');
      expect(input.decoration!.hintText, '60');
      await pause('GHOSTS');
      await tester.tap(find.byKey(const ValueKey('complete-0025-0')));
      await tester.pumpAndSettle();
      await container.read(activeWorkoutProvider(uid).notifier).flush();
      expect(container.read(activeWorkoutProvider(uid)).value!.isValid, isTrue);
      await pause('ACCEPTED');
      // Demonstrate local completion while disconnected from Firestore.
      await db.disableNetwork();
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
      expect(find.text('Workout complete'), findsOneWidget);
      expect(find.text('480 kg'), findsOneWidget);
      await pause('SUMMARY', 6);
      await tester.tap(find.text('View history'));
      await tester.pumpAndSettle();
      expect(find.textContaining('M3 Demo Workout'), findsWidgets);
      expect((await repository.getCached()), hasLength(2));
      await pause('HISTORY', 6);
      await db.enableNetwork();
      await db.waitForPendingWrites();
      final savedId = container.read(activeWorkoutProvider(uid)).value!.id;
      final saved = await history
          .doc(savedId)
          .get(const GetOptions(source: Source.server));
      expect(saved.data()!['totalVolume'], 480);
      await pause('FINISHED', 5);
    } finally {
      await db.enableNetwork();
      final documents = await history.get();
      final cleanup = db.batch();
      for (final document in documents.docs) {
        cleanup.delete(document.reference);
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
  }, skip: !const bool.fromEnvironment('RUN_M3_DEMO'));
}
