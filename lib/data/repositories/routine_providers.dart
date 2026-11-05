import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_providers.dart';
import '../models/routine.dart';
import 'fake_routine_repository.dart';
import 'routine_repository.dart';

/// One in-memory store per uid. Not auto-disposed, so a user's routines survive
/// signing out and back in until the app is closed.
final _sessionRoutineRepositoryProvider =
    Provider.family<RoutineRepository, String>(
      (ref, uid) => FakeRoutineRepository(),
    );

/// Routines of the signed-in user, or null while nobody is signed in.
///
/// Follows the same rule as the router: an auth error counts as signed out.
// TODO(#18): replace with FirestoreRoutineRepository
final routineRepositoryProvider = Provider<RoutineRepository?>((ref) {
  final uid = ref.watch(
    authStateProvider.select((auth) => auth.hasError ? null : auth.value?.id),
  );
  return uid == null ? null : ref.watch(_sessionRoutineRepositoryProvider(uid));
});

/// Live routine list of the signed-in user, sorted by routine order.
///
/// Stays loading while nobody is signed in; the router leaves these screens.
final routineListProvider = StreamProvider<List<Routine>>((ref) {
  final repository = ref.watch(routineRepositoryProvider);
  return repository?.watch() ?? const Stream.empty();
});

/// The routine with [id], or `null` when this user has no such routine.
final routineByIdProvider = Provider.family<AsyncValue<Routine?>, String>(
  (ref, id) => ref
      .watch(routineListProvider)
      .whenData((all) => all.where((r) => r.id == id).firstOrNull),
);
