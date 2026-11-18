import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymgym_a/core/firebase_bootstrap.dart';
import 'package:gymgym_a/data/auth/firebase_auth_repository.dart';
import 'package:gymgym_a/data/models/routine.dart';
import 'package:gymgym_a/data/models/routine_item.dart';
import 'package:gymgym_a/data/repositories/firestore_routine_repository.dart';
import 'package:gymgym_a/data/repositories/routine_repository.dart';
import 'package:integration_test/integration_test.dart';

Routine _routine(String name, {String secondExerciseId = '0030'}) => Routine(
  id: 'integration-check',
  name: name,
  order: 0,
  items: [
    RoutineItem(exerciseId: '0025', targetSets: 3),
    RoutineItem(exerciseId: secondExerciseId, targetSets: 5),
  ],
  source: 'custom',
  updatedAt: DateTime.now(),
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('routines pass the rules and save instantly while offline', (
    tester,
  ) async {
    // Never run this test against a real Firebase project.
    expect(const bool.fromEnvironment('USE_FIREBASE_EMULATORS'), isTrue);
    await initializeFirebase();
    final db = FirebaseFirestore.instance;
    expect(db.settings.host, endsWith(':8080'));
    final auth = FirebaseAuthRepository(FirebaseAuth.instance);
    await auth.register(
      email: 'routines-${DateTime.now().microsecondsSinceEpoch}@example.com',
      password: 'GymGym-test-123!',
    );
    final uid = auth.currentUser!.id;
    final repository = FirestoreRoutineRepository(db, uid);
    final document = db.doc('users/$uid/routines/integration-check');
    const server = GetOptions(source: Source.server);
    final failures = <RoutineWriteFailure>[];
    final subscription = repository.writeFailures.listen(failures.add);

    try {
      // Only the server can accept this document, after evaluating the rules.
      await repository.save(_routine('Online'));
      await db.waitForPendingWrites();
      final accepted = await document.get(server);
      expect(accepted.data()!['name'], 'Online');
      expect(accepted.data()!['updatedAt'], isA<Timestamp>());

      final read = (await repository.get('integration-check'))!;
      expect(read.items.map((item) => item.exerciseId), ['0025', '0030']);

      // The model allows an empty exercise id but the rules do not, so the
      // server rejects this save and the cache returns to the accepted one.
      final rejected = repository.writeFailures.first;
      await repository.save(_routine('Rejected', secondExerciseId: ''));
      final failure = await rejected.timeout(const Duration(seconds: 10));
      expect(failure.operation, RoutineWriteOperation.save);
      expect(failure.routineId, 'integration-check');
      expect((await repository.watch().first).single.name, 'Online');
      expect((await document.get(server)).data()!['name'], 'Online');
      expect(failures, hasLength(1));

      await db.disableNetwork();
      final stopwatch = Stopwatch()..start();
      await repository.save(_routine('Offline'));
      final visible = await repository.watch().firstWhere(
        (routines) => routines.single.name == 'Offline',
      );
      stopwatch.stop();
      expect(visible.single.items, hasLength(2));
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));

      await db.enableNetwork();
      await db.waitForPendingWrites();
      expect((await document.get(server)).data()!['name'], 'Offline');
      expect(failures, hasLength(1), reason: 'offline is not a rejection');

      await repository.delete('integration-check');
      await db.waitForPendingWrites();
      expect((await document.get(server)).exists, isFalse);
    } finally {
      await subscription.cancel();
      await db.enableNetwork();
      await FirebaseAuth.instance.currentUser?.delete();
      await auth.signOut();
    }
  });
}
