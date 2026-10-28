import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymgym_a/app.dart';
import 'package:gymgym_a/core/router.dart';
import 'package:gymgym_a/data/auth/auth_providers.dart';
import 'package:gymgym_a/data/auth/fake_auth_repository.dart';
import 'package:gymgym_a/data/exercise_catalog.dart';
import 'package:gymgym_a/features/auth/auth_screen.dart';

import '../../helpers/fake_exercises.dart';

Future<ProviderContainer> start(
  WidgetTester tester,
  FakeAuthRepository auth,
) async {
  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(auth),
      exerciseCatalogProvider.overrideWith((ref) async => fakeExercises),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const GymGymApp()),
  );
  await tester.pumpAndSettle();
  return container;
}

Future<void> credentials(
  WidgetTester tester, {
  String password = 'secret123',
}) async {
  await tester.enterText(
    find.byKey(const ValueKey('auth-email')),
    'user@example.com',
  );
  await tester.enterText(find.byKey(const ValueKey('auth-password')), password);
}

void main() {
  testWidgets(
    'signed-out access redirects; registering opens app; logout guards routes',
    (tester) async {
      final auth = FakeAuthRepository();
      final container = await start(tester, auth);
      expect(find.byType(AuthScreen), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      await tester.tap(find.widgetWithText(TextButton, 'Create account'));
      await tester.pumpAndSettle();
      await credentials(tester);
      await tester.enterText(
        find.byKey(const ValueKey('auth-confirm')),
        'secret123',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
      await tester.pumpAndSettle();
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(auth.currentUser, isNotNull);
      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();
      expect(find.byType(AuthScreen), findsOneWidget);
      container.read(appRouterProvider).go(AppRoutes.history);
      await tester.pumpAndSettle();
      expect(find.text('History — coming soon'), findsNothing);
    },
  );

  testWidgets(
    'sign in restores protected deep link and rejects wrong password',
    (tester) async {
      final auth = FakeAuthRepository();
      await auth.register(email: 'user@example.com', password: 'secret123');
      await auth.signOut();
      final container = await start(tester, auth);
      container.read(appRouterProvider).go(AppRoutes.history);
      await tester.pumpAndSettle();
      await credentials(tester, password: 'incorrect');
      await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
      await tester.pumpAndSettle();
      expect(find.text('Email or password is incorrect.'), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      await credentials(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
      await tester.pumpAndSettle();
      expect(find.text('History — coming soon'), findsOneWidget);
    },
  );

  testWidgets(
    'reset password keeps user signed out and uses a neutral message',
    (tester) async {
      final auth = FakeAuthRepository();
      await start(tester, auth);
      await tester.tap(find.text('Forgot password?'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('auth-email')),
        'unknown@example.com',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Reset password'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'If an account exists, a password reset email has been sent.',
        ),
        findsOneWidget,
      );
      expect(auth.currentUser, isNull);
    },
  );

  testWidgets('invalid input and mismatched passwords stay on form', (
    tester,
  ) async {
    final auth = FakeAuthRepository();
    await start(tester, auth);
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid email address.'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Create account'));
    await tester.pumpAndSettle();
    await credentials(tester);
    await tester.enterText(
      find.byKey(const ValueKey('auth-confirm')),
      'different',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
    await tester.pumpAndSettle();
    expect(find.text('Passwords do not match.'), findsOneWidget);
    expect(auth.currentUser, isNull);
  });
}
