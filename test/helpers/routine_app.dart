import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymgym_a/app.dart';
import 'package:gymgym_a/core/router.dart';
import 'package:gymgym_a/data/auth/auth_providers.dart';
import 'package:gymgym_a/data/auth/auth_repository.dart';
import 'package:gymgym_a/data/auth/fake_auth_repository.dart';
import 'package:gymgym_a/data/exercise_catalog.dart';
import 'package:gymgym_a/data/models/exercise.dart';
import 'package:gymgym_a/data/repositories/fake_routine_repository.dart';
import 'package:gymgym_a/data/repositories/routine_providers.dart';
import 'package:gymgym_a/data/repositories/routine_repository.dart';

import 'fake_exercises.dart';

/// Starts the whole app signed in, on [location], with a fake routine store.
Future<void> pumpRoutineApp(
  WidgetTester tester, {
  String location = AppRoutes.routines,
  RoutineRepository? repository,
  List<Exercise>? exercises,
  List<Override> overrides = const [],
  Size size = const Size(400, 1200),
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);

  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(
        FakeAuthRepository(
          user: const AuthUser(id: 'test-user', email: 'test@example.com'),
        ),
      ),
      exerciseCatalogProvider.overrideWith(
        (ref) async => exercises ?? fakeExercises,
      ),
      routineRepositoryProvider.overrideWithValue(
        repository ?? FakeRoutineRepository(),
      ),
      ...overrides,
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const GymGymApp()),
  );
  await tester.pumpAndSettle();
  container.read(appRouterProvider).go(location);
  await tester.pumpAndSettle();
}
