import 'package:shared_preferences/shared_preferences.dart';
import 'package:todolist/models/todo_item.dart';

class TodoRepository {
  static const _storageKey = 'todolist_v2';
  static const _legacyKey = 'todolist';

  Future<List<TodoItem>> loadTodos() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw != null) {
      return TodoItem.decodeList(raw);
    }
    final legacy = prefs.getStringList(_legacyKey);
    if (legacy != null) {
      final now = DateTime.now();
      final todos = List.generate(legacy.length, (index) {
        final text = legacy[index];
        return TodoItem(
          id: now.add(Duration(milliseconds: index)).microsecondsSinceEpoch.toString(),
          title: text,
        );
      });
      await saveTodos(todos);
      return todos;
    }
    return [];
  }

  Future<void> saveTodos(List<TodoItem> todos) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, TodoItem.encodeList(todos));
  }
}



