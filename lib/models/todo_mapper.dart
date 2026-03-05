import 'dart:convert';
import 'package:baromemo/models/todo_item.dart';

class TodoMapper {
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
