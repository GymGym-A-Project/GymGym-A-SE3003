import '../models/workout_session.dart';

enum WorkoutWriteOperation { save, delete }

class WorkoutWriteFailure {
  const WorkoutWriteFailure(this.operation, this.sessionId);
  final WorkoutWriteOperation operation;
  final String sessionId;
}

/// One user's workout sessions; implementations receive the user at creation.
/// Sets are saved atomically with their parent session, preserving set order.
abstract interface class WorkoutSessionRepository {
  /// Server rejections arrive after an optimistic local write has completed.
  Stream<WorkoutWriteFailure> get writeFailures;
  void dispose();

  /// Current snapshot followed by updates, newest startedAt first, then id.
  Stream<List<WorkoutSession>> watch();
  Future<WorkoutSession?> get(String id);
  Future<void> save(WorkoutSession session);
  Future<void> delete(String id);
}
