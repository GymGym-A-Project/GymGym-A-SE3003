import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/routine.dart';
import 'routine_repository.dart';

/// Routines of one user, stored at `users/{uid}/routines/{id}`.
///
/// The document layout must match `validRoutine` in `firestore.rules`.
class FirestoreRoutineRepository implements RoutineRepository {
  FirestoreRoutineRepository(FirebaseFirestore firestore, String uid)
    : _routines = firestore.collection('users').doc(uid).collection('routines');

  final CollectionReference<Map<String, dynamic>> _routines;

  @override
  Stream<List<Routine>> watch() => _routines
      .orderBy('order')
      .orderBy(FieldPath.documentId)
      .snapshots()
      .map(
        (snapshot) => List.unmodifiable(
          snapshot.docs.map((document) => _fromDocument(document.data())),
        ),
      );

  @override
  Future<Routine?> get(String id) async {
    try {
      final document = await _routines.doc(id).get();
      final data = document.data();
      return data == null ? null : _fromDocument(data);
    } on FirebaseException catch (error) {
      // Offline and not in the cache, so the routine is unknown on this device.
      if (error.code == 'unavailable') return null;
      rethrow;
    }
  }

  @override
  Future<void> save(Routine routine) async =>
      _write(_routines.doc(routine.id).set(_toDocument(routine)));

  @override
  Future<void> delete(String id) async => _write(_routines.doc(id).delete());

  /// Firestore applies a write to the local cache and to [watch] at once, but
  /// its future completes only when the server confirms it. Waiting would block
  /// the UI for as long as the device is offline.
  void _write(Future<void> confirmed) => unawaited(
    confirmed.catchError(
      (Object error) => debugPrint('Routine write rejected: $error'),
    ),
  );

  static Map<String, dynamic> _toDocument(Routine routine) => {
    ...routine.toJson(),
    'updatedAt': Timestamp.fromDate(routine.updatedAt),
  };

  static Routine _fromDocument(Map<String, dynamic> data) {
    final updatedAt = data['updatedAt'] as Timestamp;
    return Routine.fromJson({
      ...data,
      'updatedAt': updatedAt.toDate().toUtc().toIso8601String(),
    });
  }
}
