import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:gymgym_a/app.dart';
import 'package:gymgym_a/core/firebase_bootstrap.dart';
import 'package:gymgym_a/data/auth/firebase_auth_repository.dart';
import 'package:gymgym_a/features/auth/auth_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Firebase registration, session guard, reset and offline cache', (
    tester,
  ) async {
    // Never run this test against a real Firebase project.
    expect(const bool.fromEnvironment('USE_FIREBASE_EMULATORS'), isTrue);
    await initializeFirebase();
    expect(Firebase.app().options.projectId, 'demo-gymgym');
    final auth = FirebaseAuth.instance;
    final repository = FirebaseAuthRepository(auth);
    final db = FirebaseFirestore.instance;
    await repository.signOut();
    await tester.pumpWidget(const ProviderScope(child: GymGymApp()));
    await tester.pumpAndSettle();
    expect(find.byType(AuthScreen), findsOneWidget);

    final email =
        'integration-${DateTime.now().microsecondsSinceEpoch}@example.com';
    const password = 'GymGym-test-123!';
    try {
      await repository.register(email: email, password: password);
      await tester.pumpAndSettle();
      expect(find.byType(NavigationBar), findsOneWidget);
      final uid = repository.currentUser!.id;
      final reference = db.doc('users/$uid/routines/offline-check');
      await reference.set({
        'id': 'offline-check',
        'name': 'Offline check',
        'order': 0,
        'source': 'custom',
        'updatedAt': Timestamp.now(),
        'items': [
          {'exerciseId': '0025', 'targetSets': 3},
        ],
      });
      await db.disableNetwork();
      final cached = await reference.get(
        const GetOptions(source: Source.cache),
      );
      expect(cached.data()!['name'], 'Offline check');
      await db.enableNetwork();
      await reference.delete();

      await repository.signOut();
      await tester.pumpAndSettle();
      expect(find.byType(AuthScreen), findsOneWidget);
      await repository.signIn(email: email, password: password);
      await tester.pumpAndSettle();
      expect(repository.currentUser!.id, uid);
      expect(find.byType(NavigationBar), findsOneWidget);
      await repository.resetPassword(email);
    } finally {
      await db.enableNetwork();
      await auth.currentUser?.delete();
      await repository.signOut();
    }
  });
}
