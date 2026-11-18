import '../models/routine.dart';

/// Persistence for routines in one user scope.
///
/// Implementations receive their user identity through construction, keeping
/// authentication and storage-specific types outside this contract.
abstract interface class RoutineRepository {
  /// Emits the current snapshot and subsequent changes, sorted by routine order.
  /// Equal orders retain a stable implementation-defined ordering.
  Stream<List<Routine>> watch();

  /// Returns null when the routine does not exist in this scope.
  Future<Routine?> get(String id);

  /// Creates or replaces a routine by id, preserving its item order and metadata.
  Future<void> save(Routine routine);

  /// Deleting an absent id succeeds without changing the snapshot.
  Future<void> delete(String id);

  /// Writes the server rejected after [save] or [delete] had already returned.
  ///
  /// The rejected change is undone in [watch]. Writes that only wait for the
  /// network are not reported.
  Stream<RoutineWriteFailure> get writeFailures;
}

enum RoutineWriteOperation { save, delete }

/// A [save] or [delete] of the routine [routineId] the server rejected.
class RoutineWriteFailure {
  const RoutineWriteFailure(this.operation, this.routineId);

  final RoutineWriteOperation operation;
  final String routineId;

  @override
  String toString() => 'RoutineWriteFailure(${operation.name}, $routineId)';
}
