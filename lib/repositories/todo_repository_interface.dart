import 'package:baromemo/models/todo_item.dart';

abstract class TodoRepositoryInterface {
  Future<List<TodoItem>> loadTodos();
  Future<void> saveTodos(List<TodoItem> todos);
}
