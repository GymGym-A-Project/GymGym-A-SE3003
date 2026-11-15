import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/workout_session.dart';
import 'workout_session_repository.dart';

/// Workout sessions of one user, stored at `users/{uid}/workouts/{id}`.
///
/// The document layout must match `validWorkout` in `firestore.rules`.
class FirestoreWorkoutSessionRepository implements WorkoutSessionRepository {
  FirestoreWorkoutSessionRepository(FirebaseFirestore firestore, String uid)
    : _workouts = firestore.collection('users').doc(uid).collection('workouts');

  final CollectionReference<Map<String, dynamic>> _workouts;

  @override
  Stream<List<WorkoutSession>> watch() => _workouts
      .orderBy('startedAt', descending: true)
      .snapshots()
      .map((snapshot) {
        final sessions = [
          for (final document in snapshot.docs) _fromDocument(document.data()),
        ];
        // Breaks ties by id here, so the query needs no composite index.
        sessions.sort((a, b) {
          final time = b.startedAt.compareTo(a.startedAt);
          return time == 0 ? a.id.compareTo(b.id) : time;
        });
        return List.unmodifiable(sessions);
      });

  @override
  Future<WorkoutSession?> get(String id) async {
    try {
      final document = await _workouts.doc(id).get();
      final data = document.data();
      return data == null ? null : _fromDocument(data);
    } on FirebaseException catch (error) {
      // Offline and not in the cache, so the session is unknown on this device.
      if (error.code == 'unavailable') return null;
      rethrow;
    }
  }

  @override
  Future<void> save(WorkoutSession session) async =>
      _write(_workouts.doc(session.id).set(_toDocument(session)));

  @override
  Future<void> delete(String id) async => _write(_workouts.doc(id).delete());

  /// Firestore applies a write to the local cache and to [watch] at once, but
  /// its future completes only when the server confirms it. Waiting would block
  /// the UI for as long as the device is offline.
  void _write(Future<void> confirmed) => unawaited(
    confirmed.catchError(
      (Object error) => debugPrint('Workout write rejected: $error'),
    ),
  );

  static Map<String, dynamic> _toDocument(WorkoutSession session) {
    final finishedAt = session.finishedAt;
    return {
      ...session.toJson(),
      'startedAt': Timestamp.fromDate(session.startedAt),
      'finishedAt': finishedAt == null ? null : Timestamp.fromDate(finishedAt),
    };
  }

  static WorkoutSession _fromDocument(Map<String, dynamic> data) {
    String? iso(Object? value) =>
        (value as Timestamp?)?.toDate().toUtc().toIso8601String();
    return WorkoutSession.fromJson({
      ...data,
      'startedAt': iso(data['startedAt']),
      'finishedAt': iso(data['finishedAt']),
    });
  }
}
