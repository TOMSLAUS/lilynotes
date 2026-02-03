import 'package:uuid/uuid.dart';
import 'widget_type.dart';

const _uuid = Uuid();

class AppWidget {
  final String id;
  final WidgetType type;
  final String title;
  final Map<String, dynamic> data;
  final int order;
  final DateTime createdAt;
  final DateTime updatedAt;

  AppWidget({
    String? id,
    required this.type,
    required this.title,
    Map<String, dynamic>? data,
    this.order = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? _uuid.v4(),
        data = data ?? {},
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  AppWidget copyWith({
    String? title,
    Map<String, dynamic>? data,
    int? order,
    DateTime? updatedAt,
  }) {
    return AppWidget(
      id: id,
      type: type,
      title: title ?? this.title,
      data: data ?? this.data,
      order: order ?? this.order,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'data': data,
      'order': order,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory AppWidget.fromMap(Map<String, dynamic> map) {
    return AppWidget(
      id: map['id'] as String,
      type: WidgetType.fromString(map['type'] as String),
      title: map['title'] as String,
      data: Map<String, dynamic>.from(map['data'] as Map? ?? {}),
      order: map['order'] as int? ?? 0,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is AppWidget && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'AppWidget(id: $id, type: ${type.name}, title: $title)';
}
