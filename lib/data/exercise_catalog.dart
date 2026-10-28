import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/exercise.dart';

const exerciseCatalogAsset = 'assets/data/exercises.json';

/// Loads the bundled exercise catalog.
class ExerciseCatalog {
  const ExerciseCatalog({this.bundle});

  /// Defaults to [rootBundle]; tests may inject their own.
  final AssetBundle? bundle;

  Future<List<Exercise>> load() async {
    final raw = await (bundle ?? rootBundle).loadString(exerciseCatalogAsset);
    return parse(raw);
  }

  static List<Exercise> parse(String raw) {
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return (json['exercises'] as List)
        .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }
}

final exerciseCatalogProvider = FutureProvider<List<Exercise>>(
  (ref) => const ExerciseCatalog().load(),
);

/// The catalog entry with [id], or `null` when no exercise has that id.
final exerciseByIdProvider = Provider.family<AsyncValue<Exercise?>, String>(
  (ref, id) => ref
      .watch(exerciseCatalogProvider)
      .whenData((all) => all.where((e) => e.id == id).firstOrNull),
);
