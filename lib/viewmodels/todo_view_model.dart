import 'package:flutter/foundation.dart';
import 'package:todolist/models/todo_item.dart';
import 'package:todolist/repositories/todo_repository.dart';

class TodoViewModel extends ChangeNotifier {
  TodoViewModel(this._repository);

  final TodoRepository _repository;
  List<TodoItem> _todos = [];
  bool _isLoading = true;

  String _searchQuery = '';
  String _tagFilter = '전체';

  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String get tagFilter => _tagFilter;
  List<TodoItem> get todos => List.unmodifiable(_todos);

  List<TodoItem> get filteredTodos {
    final query = _searchQuery.toLowerCase();
    return _todos.where((todo) {
      final matchSearch = todo.title.toLowerCase().contains(query);
      final matchTag = _tagFilter == '전체' || todo.tag == _tagFilter;
      final notImportant = !todo.isHighlighted;
      return matchSearch && matchTag && notImportant;
    }).toList();
  }

  Future<void> initialize() async {
    _todos = await _repository.loadTodos();
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addTodo(TodoItem todo) async {
    final exists = _todos.any(
      (item) =>
          item.title.trim().toLowerCase() == todo.title.trim().toLowerCase(),
    );
    if (exists) return false;
    _todos.insert(0, todo);
    await _repository.saveTodos(_todos);
    notifyListeners();
    return true;
  }

  Future<void> updateTodo(TodoItem updated) async {
    final index = _todos.indexWhere((todo) => todo.id == updated.id);
    if (index == -1) return;
    _todos[index] = updated;
    await _repository.saveTodos(_todos);
    notifyListeners();
  }

  Future<void> deleteTodo(TodoItem todo) async {
    _todos.removeWhere((item) => item.id == todo.id);
    await _repository.saveTodos(_todos);
    notifyListeners();
  }

  Future<void> setImportant(TodoItem todo, bool isImportant) async {
    final index = _todos.indexWhere((item) => item.id == todo.id);
    if (index == -1) return;
    _todos[index] = todo.copyWith(isHighlighted: isImportant);
    await _repository.saveTodos(_todos);
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setTagFilter(String tag) {
    _tagFilter = tag;
    notifyListeners();
  }

  String buildSummary(TodoItem todo) {
    final checklistDone = todo.checklist.where((item) => item.isDone).length;
    final reminderText =
        todo.reminder == null
            ? ''
            : ' • ${todo.reminder!.month}/${todo.reminder!.day}';
    final snippet =
        todo.title.length > 60 ? '${todo.title.substring(0, 60)}…' : todo.title;
    return '$snippet\n체크리스트: $checklistDone/${todo.checklist.length}$reminderText';
  }

  String buildShareText(TodoItem todo) {
    final buffer =
        StringBuffer()
          ..writeln('[${todo.tag}] ${todo.title}');
    if (todo.checklist.isNotEmpty) {
      for (final item in todo.checklist) {
        buffer.writeln('- [${item.isDone ? 'x' : ' '}] ${item.text}');
      }
    }
    if (todo.reminder != null) {
      buffer.writeln(
        '중요알림: ${todo.reminder!.month}/${todo.reminder!.day} '
        '${todo.reminder!.hour.toString().padLeft(2, '0')}:'
        '${todo.reminder!.minute.toString().padLeft(2, '0')}',
      );
    }
    return buffer.toString();
  }
}
