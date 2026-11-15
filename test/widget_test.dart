import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymgym_a/app.dart';
import 'package:gymgym_a/data/exercise_catalog.dart';
import 'package:gymgym_a/data/auth/auth_providers.dart';
import 'package:gymgym_a/data/auth/auth_repository.dart';
import 'package:gymgym_a/data/auth/fake_auth_repository.dart';
import 'package:gymgym_a/data/repositories/fake_workout_session_repository.dart';
import 'package:gymgym_a/data/repositories/workout_session_providers.dart';
import 'package:gymgym_a/features/history/history_screen.dart';

import 'helpers/fake_exercises.dart';

void main() {
  testWidgets('app starts with bottom navigation', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            FakeAuthRepository(
              user: const AuthUser(id: 'test-user', email: 'test@example.com'),
            ),
          ),
          exerciseCatalogProvider.overrideWith((ref) async => fakeExercises),
          workoutSessionRepositoryProvider.overrideWithValue(
            FakeWorkoutSessionRepository(),
          ),
        ],
        child: const GymGymApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    // The Exercises tab opens first and shows the library.
    expect(find.text('Bench Press'), findsOneWidget);
    expect(find.text(fakeAttribution), findsOneWidget);

    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    expect(find.byType(HistoryScreen), findsOneWidget);
  });
}
