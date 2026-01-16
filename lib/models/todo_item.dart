import 'dart:convert';

class TodoItem {
  final String id;
  final String title;
  final String tag;
  final String priority;
  final DateTime? reminder;
  final bool repeatDaily;
  final bool isHighlighted;
  final DateTime createdAt;
  final String? imagePath;
  final DateTime? deletedAt;

  TodoItem({
    required this.id,
    required this.title,
    this.tag = '일반',
    this.priority = '보통',
    this.reminder,
    this.repeatDaily = false,
    this.isHighlighted = false,
    this.imagePath,
    this.deletedAt,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  TodoItem copyWith({
    String? title,
    String? tag,
    String? priority,
    DateTime? reminder,
    bool overrideReminder = false,
    bool? repeatDaily,
    bool? isHighlighted,
    String? imagePath,
    bool overrideImagePath = false,
    DateTime? deletedAt,
    bool overrideDeletedAt = false,
  }) {
    return TodoItem(
      id: id,
      title: title ?? this.title,
      tag: tag ?? this.tag,
      priority: priority ?? this.priority,
      reminder: overrideReminder ? reminder : (reminder ?? this.reminder),
      repeatDaily: repeatDaily ?? this.repeatDaily,
      isHighlighted: isHighlighted ?? this.isHighlighted,
      imagePath:
          overrideImagePath ? imagePath : (imagePath ?? this.imagePath),
      deletedAt:
          overrideDeletedAt ? deletedAt : (deletedAt ?? this.deletedAt),
      createdAt: createdAt,
    );
  }

  factory TodoItem.fromJson(Map<String, dynamic> json) {
    return TodoItem(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      tag: json['tag'] as String? ?? '일반',
      priority: json['priority'] as String? ?? '보통',
      reminder:
          json['reminder'] != null
              ? DateTime.tryParse(json['reminder'] as String)
              : null,
      repeatDaily: json['repeatDaily'] as bool? ?? false,
      isHighlighted: json['isHighlighted'] as bool? ?? false,
      imagePath: json['imagePath'] as String?,
      deletedAt:
          json['deletedAt'] != null
              ? DateTime.tryParse(json['deletedAt'] as String)
              : null,
      createdAt:
          json['createdAt'] != null
              ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'tag': tag,
      'priority': priority,
      'reminder': reminder?.toIso8601String(),
      'repeatDaily': repeatDaily,
      'isHighlighted': isHighlighted,
      'imagePath': imagePath,
      'deletedAt': deletedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static String encodeList(List<TodoItem> items) {
    return jsonEncode(items.map((e) => e.toJson()).toList());
  }

  static List<TodoItem> decodeList(String raw) {
    final data = jsonDecode(raw) as List<dynamic>;
    return data
        .map((e) => TodoItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
