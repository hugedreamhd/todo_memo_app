import 'dart:convert';

class ChecklistItem {
  final String id;
  final String text;
  final bool isDone;

  const ChecklistItem({
    required this.id,
    required this.text,
    this.isDone = false,
  });

  ChecklistItem copyWith({String? text, bool? isDone}) {
    return ChecklistItem(
      id: id,
      text: text ?? this.text,
      isDone: isDone ?? this.isDone,
    );
  }

  factory ChecklistItem.fromJson(Map<String, dynamic> json) {
    return ChecklistItem(
      id: json['id'] as String,
      text: json['text'] as String? ?? '',
      isDone: json['isDone'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'text': text, 'isDone': isDone};
  }
}

class TodoItem {
  final String id;
  final String title;
  final String tag;
  final String priority;
  final List<ChecklistItem> checklist;
  final DateTime? reminder;
  final bool repeatDaily;
  final bool isHighlighted;
  final DateTime createdAt;
  final String? imagePath;

  TodoItem({
    required this.id,
    required this.title,
    this.tag = '일반',
    this.priority = '보통',
    this.checklist = const [],
    this.reminder,
    this.repeatDaily = false,
    this.isHighlighted = false,
    this.imagePath,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  TodoItem copyWith({
    String? title,
    String? tag,
    String? priority,
    List<ChecklistItem>? checklist,
    DateTime? reminder,
    bool overrideReminder = false,
    bool? repeatDaily,
    bool? isHighlighted,
    String? imagePath,
    bool overrideImagePath = false,
  }) {
    return TodoItem(
      id: id,
      title: title ?? this.title,
      tag: tag ?? this.tag,
      priority: priority ?? this.priority,
      checklist: checklist ?? this.checklist,
      reminder: overrideReminder ? reminder : (reminder ?? this.reminder),
      repeatDaily: repeatDaily ?? this.repeatDaily,
      isHighlighted: isHighlighted ?? this.isHighlighted,
      imagePath:
          overrideImagePath ? imagePath : (imagePath ?? this.imagePath),
      createdAt: createdAt,
    );
  }

  factory TodoItem.fromJson(Map<String, dynamic> json) {
    return TodoItem(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      tag: json['tag'] as String? ?? '일반',
      priority: json['priority'] as String? ?? '보통',
      checklist:
          (json['checklist'] as List<dynamic>? ?? [])
              .map((e) => ChecklistItem.fromJson(e as Map<String, dynamic>))
              .toList(),
      reminder:
          json['reminder'] != null
              ? DateTime.tryParse(json['reminder'] as String)
              : null,
      repeatDaily: json['repeatDaily'] as bool? ?? false,
      isHighlighted: json['isHighlighted'] as bool? ?? false,
      imagePath: json['imagePath'] as String?,
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
      'checklist': checklist.map((e) => e.toJson()).toList(),
      'reminder': reminder?.toIso8601String(),
      'repeatDaily': repeatDaily,
      'isHighlighted': isHighlighted,
      'imagePath': imagePath,
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
