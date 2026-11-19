import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:gymgym_a/app.dart';
import 'package:gymgym_a/core/firebase_bootstrap.dart';
import 'package:gymgym_a/core/router.dart';
import 'package:gymgym_a/features/logger/active_workout.dart';
import 'package:gymgym_a/features/logger/workout_draft_store.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'logger restores device inputs and syncs a finished offline workout',
    (tester) async {
      expect(const bool.fromEnvironment('USE_FIREBASE_EMULATORS'), isTrue);
      await initializeFirebase();
      final db = FirebaseFirestore.instance;
      final auth = FirebaseAuth.instance;
      expect(db.settings.host, endsWith(':8080'));
      await auth.createUserWithEmailAndPassword(
        email: 'logger-${DateTime.now().microsecondsSinceEpoch}@example.com',
        password: 'GymGym-test-123!',
      );
      final uid = auth.currentUser!.uid;
      final routine = db.doc('users/$uid/routines/logger-check');
      ProviderContainer? container;
      try {
        await routine.set({
          'id': 'logger-check',
          'name': 'Logger acceptance',
          'order': 0,
          'source': 'custom',
          'updatedAt': Timestamp.now(),
          'items': [
            {'exerciseId': '0025', 'targetSets': 1},
          ],
        });
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
            .go(AppRoutes.routineDetail('logger-check'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('start-workout')));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const ValueKey('weight-0025-0')),
          '60',
        );
        await tester.enterText(find.byKey(const ValueKey('reps-0025-0')), '8');
        await container.read(activeWorkoutProvider(uid).notifier).flush();
        final id = container.read(activeWorkoutProvider(uid)).value!.id;

        // Recreate the whole application container: restore from the real device
        // preferences, not from the previous notifier's in-memory state.
        await tester.pumpWidget(const SizedBox.shrink());
        container.dispose();
        container = ProviderContainer();
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const GymGymApp(),
          ),
        );
        await tester.pumpAndSettle();
        container.read(appRouterProvider).go(AppRoutes.logger);
        await tester.pumpAndSettle();
        expect(find.text('60'), findsOneWidget);
        expect(find.text('8'), findsOneWidget);
        expect(container.read(activeWorkoutProvider(uid)).value!.id, id);

        await db.disableNetwork();
        await tester.ensureVisible(
          find.byKey(const ValueKey('finish-workout')),
        );
        await tester.tap(find.byKey(const ValueKey('finish-workout')));
        await tester.pumpAndSettle();
        final document = db.doc('users/$uid/workouts/$id');
        final cached = await document.get(
          const GetOptions(source: Source.cache),
        );
        expect(cached.data()!['totalVolume'], 480);
        expect(cached.data()!['finishedAt'], isA<Timestamp>());
        expect(find.textContaining('Logger acceptance'), findsWidgets);
        expect(find.text('No completed workouts yet'), findsNothing);

        await db.enableNetwork();
        await db.waitForPendingWrites();
        expect(
          (await document.get(const GetOptions(source: Source.server)))
              .data()!['totalVolume'],
          480,
        );
        await document.delete();
        await routine.delete();
      } finally {
        await db.enableNetwork();
        if (container != null) {
          await container.read(workoutDraftStoreProvider).write(uid, null);
          await tester.pumpWidget(const SizedBox.shrink());
          container.dispose();
        }
        await auth.currentUser?.delete();
        await auth.signOut();
      }
    },
  );
}
