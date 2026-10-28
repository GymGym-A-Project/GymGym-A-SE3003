import '../models/workout_session.dart';

/// One user's workout sessions; implementations receive the user at creation.
/// Sets are saved atomically with their parent session, preserving set order.
abstract interface class WorkoutSessionRepository {
  /// Current snapshot followed by updates, newest startedAt first, then id.
  Stream<List<WorkoutSession>> watch();
  Future<WorkoutSession?> get(String id);
  Future<void> save(WorkoutSession session);
  Future<void> delete(String id);
}
