import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/auth/auth_providers.dart';
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

final appRouterProvider = Provider<GoRouter>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  final refresh = _RouterRefresh();
  ref.listen(authStateProvider, (_, _) => refresh.refresh());
  final router = GoRouter(
    initialLocation: AppRoutes.exercises,
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authStateProvider);
      final user = auth.hasError
          ? null
          : auth.hasValue
          ? auth.value
          : repository.currentUser;
      final atAuth = state.matchedLocation == AppRoutes.auth;
      if (user == null && !atAuth) {
        return Uri(
          path: AppRoutes.auth,
          queryParameters: {'from': state.uri.toString()},
        ).toString();
      }
      if (user != null && atAuth) {
        final from = state.uri.queryParameters['from'];
        final destination = from == null ? null : Uri.tryParse(from);
        if (destination != null &&
            !destination.hasScheme &&
            !destination.hasAuthority &&
            destination.path.startsWith('/') &&
            destination.path != AppRoutes.auth) {
          return destination.toString();
        }
        return AppRoutes.exercises;
      }
      return null;
    },
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
  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});

class _RouterRefresh extends ChangeNotifier {
  void refresh() => notifyListeners();
}

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
