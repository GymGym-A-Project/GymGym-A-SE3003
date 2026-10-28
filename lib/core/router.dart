import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/analyzer/analyzer_screen.dart';
import '../features/auth/auth_screen.dart';
import '../features/exercises/exercise_detail_screen.dart';
import '../features/exercises/exercises_screen.dart';
import '../features/history/history_screen.dart';
import '../features/logger/logger_screen.dart';
import '../features/routines/routines_screen.dart';
import 'widgets/app_shell.dart';

abstract final class AppRoutes {
  static const auth = '/auth';
  static const exercises = '/exercises';
  static const routines = '/routines';
  static const logger = '/logger';
  static const history = '/history';
  static const analyzer = '/analyzer';

  static String exerciseDetail(String id) => '$exercises/$id';
}

// The signed-out redirect guard is added with WP-02.
final appRouter = GoRouter(
  initialLocation: AppRoutes.exercises,
  routes: [
    GoRoute(
      path: AppRoutes.auth,
      builder: (context, state) => const AuthScreen(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => AppShell(shell: shell),
      branches: [
        _branch(
          AppRoutes.exercises,
          const ExercisesScreen(),
          routes: [
            GoRoute(
              path: ':id',
              builder: (context, state) =>
                  ExerciseDetailScreen(id: state.pathParameters['id']!),
            ),
          ],
        ),
        _branch(AppRoutes.routines, const RoutinesScreen()),
        _branch(AppRoutes.logger, const LoggerScreen()),
        _branch(AppRoutes.history, const HistoryScreen()),
        _branch(AppRoutes.analyzer, const AnalyzerScreen()),
      ],
    ),
  ],
);

StatefulShellBranch _branch(
  String path,
  Widget screen, {
  List<RouteBase> routes = const [],
}) {
  return StatefulShellBranch(
    routes: [
      GoRoute(path: path, builder: (context, state) => screen, routes: routes),
    ],
  );
}
