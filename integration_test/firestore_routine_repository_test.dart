import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymgym_a/core/firebase_bootstrap.dart';
import 'package:gymgym_a/data/auth/firebase_auth_repository.dart';
import 'package:gymgym_a/data/models/routine.dart';
import 'package:gymgym_a/data/models/routine_item.dart';
import 'package:gymgym_a/data/repositories/firestore_routine_repository.dart';
import 'package:integration_test/integration_test.dart';

Routine _routine(String name) => Routine(
  id: 'integration-check',
  name: name,
  order: 0,
  items: [
    RoutineItem(exerciseId: '0025', targetSets: 3),
    RoutineItem(exerciseId: '0030', targetSets: 5),
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

    try {
      // Only the server can accept this document, after evaluating the rules.
      await repository.save(_routine('Online'));
      await db.waitForPendingWrites();
      final accepted = await document.get(server);
      expect(accepted.data()!['name'], 'Online');
      expect(accepted.data()!['updatedAt'], isA<Timestamp>());

      final read = (await repository.get('integration-check'))!;
      expect(read.items.map((item) => item.exerciseId), ['0025', '0030']);

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

      await repository.delete('integration-check');
      await db.waitForPendingWrites();
      expect((await document.get(server)).exists, isFalse);
    } finally {
      await db.enableNetwork();
      await FirebaseAuth.instance.currentUser?.delete();
      await auth.signOut();
    }
  });
}
