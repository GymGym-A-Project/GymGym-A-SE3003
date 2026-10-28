import 'dart:async';

import '../models/workout_session.dart';
import 'workout_session_repository.dart';

class FakeWorkoutSessionRepository implements WorkoutSessionRepository {
  FakeWorkoutSessionRepository({Iterable<WorkoutSession> sessions = const []}) {
    for (final session in sessions) {
      _sessions[session.id] = session;
    }
  }

  final Map<String, WorkoutSession> _sessions = {};
  final Set<StreamController<List<WorkoutSession>>> _listeners = {};

  List<WorkoutSession> _snapshot() {
    final sessions = _sessions.values.toList()
      ..sort((a, b) {
        final time = b.startedAt.compareTo(a.startedAt);
        return time == 0 ? a.id.compareTo(b.id) : time;
      });
    return List.unmodifiable(sessions);
  }

  @override
  Stream<List<WorkoutSession>> watch() {
    late final StreamController<List<WorkoutSession>> controller;
    controller = StreamController<List<WorkoutSession>>(
      onListen: () {
        _listeners.add(controller);
        controller.add(_snapshot());
      },
      onCancel: () {
        _listeners.remove(controller);
      },
    );
    return controller.stream;
  }

  void _publish() {
    final snapshot = _snapshot();
    for (final listener in _listeners) {
      listener.add(snapshot);
    }
  }

  @override
  Future<WorkoutSession?> get(String id) async => _sessions[id];

  @override
  Future<void> save(WorkoutSession session) async {
    _sessions[session.id] = session;
    _publish();
  }

  @override
  Future<void> delete(String id) async {
    if (_sessions.remove(id) != null) _publish();
  }
}
