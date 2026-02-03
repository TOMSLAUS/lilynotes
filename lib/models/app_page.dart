import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class AppPage {
  final String id;
  final String name;
  final String content;
  final List<String> widgetIds;
  final int order;
  final DateTime createdAt;
  final DateTime updatedAt;

  AppPage({
    String? id,
    required this.name,
    this.content = '',
    List<String>? widgetIds,
    this.order = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? _uuid.v4(),
        widgetIds = widgetIds ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  AppPage copyWith({
    String? name,
    String? content,
    List<String>? widgetIds,
    int? order,
    DateTime? updatedAt,
  }) {
    return AppPage(
      id: id,
      name: name ?? this.name,
      content: content ?? this.content,
      widgetIds: widgetIds ?? List<String>.from(this.widgetIds),
      order: order ?? this.order,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'content': content,
      'widgetIds': widgetIds,
      'order': order,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory AppPage.fromMap(Map<String, dynamic> map) {
    return AppPage(
      id: map['id'] as String,
      name: map['name'] as String,
      content: map['content'] as String? ?? '',
      widgetIds: List<String>.from(map['widgetIds'] as List? ?? []),
      order: map['order'] as int? ?? 0,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is AppPage && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'AppPage(id: $id, name: $name, widgets: ${widgetIds.length})';
}
