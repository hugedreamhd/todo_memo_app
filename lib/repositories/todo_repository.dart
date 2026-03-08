import 'package:shared_preferences/shared_preferences.dart';
import 'package:baromemo/models/todo_item.dart';
import 'package:baromemo/repositories/todo_repository_interface.dart';

class TodoRepository implements TodoRepositoryInterface {
  static const _storageKey = 'baromemo_v1';
  static const _legacyKey = 'baromemo_legacy';

  @override
  Future<List<TodoItem>> loadTodos() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload(); // 백그라운드 isolate와 포그라운드 앱 간의 캐시 동기화를 위해 필수
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
          id:
              now
                  .add(Duration(milliseconds: index))
                  .microsecondsSinceEpoch
                  .toString(),
          title: text,
        );
      });
      await saveTodos(todos);
      return todos;
    }
    return [];
  }

  @override
  Future<void> saveTodos(List<TodoItem> todos) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, TodoItem.encodeList(todos));
  }
}
