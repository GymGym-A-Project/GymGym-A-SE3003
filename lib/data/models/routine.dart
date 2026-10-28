import 'routine_item.dart';

/// A routine whose items retain their explicitly selected order.
class Routine {
  Routine({
    required this.id,
    required this.name,
    required this.order,
    required List<RoutineItem> items,
    required this.source,
    required this.updatedAt,
  }) : items = List.unmodifiable(items) {
    if (name.trim().isEmpty) {
      throw ArgumentError.value(name, 'name', 'Must not be blank');
    }
    if (this.items.isEmpty || this.items.length > 15) {
      throw ArgumentError.value(
        items.length,
        'items',
        'Must contain 1–15 items',
      );
    }
  }

  factory Routine.fromJson(Map<String, dynamic> json) => Routine(
    id: json['id'] as String,
    name: json['name'] as String,
    order: json['order'] as int,
    items: (json['items'] as List)
        .map((item) => RoutineItem.fromJson(item as Map<String, dynamic>))
        .toList(),
    source: json['source'] as String,
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );

  final String id;
  final String name;
  final int order;
  final List<RoutineItem> items;

  /// Origin identifier, for example `custom` or `starter:ppl`.
  final String source;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'order': order,
    'items': items.map((item) => item.toJson()).toList(),
    'source': source,
    'updatedAt': updatedAt.toUtc().toIso8601String(),
  };
}
