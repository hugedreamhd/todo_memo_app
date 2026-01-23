import 'package:flutter/foundation.dart';
import 'package:todolist/models/todo_item.dart';
import 'package:todolist/repositories/todo_repository_interface.dart';

class TodoViewModel extends ChangeNotifier {
  TodoViewModel(this._repository);

  final TodoRepositoryInterface _repository;
  List<TodoItem> _todos = [];
  static const Duration _deleteRetention = Duration(days: 3);
  bool _isLoading = true;

  String _searchQuery = '';
  String _tagFilter = '전체';

  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String get tagFilter => _tagFilter;
  List<TodoItem> get todos => List.unmodifiable(_todos);
  List<TodoItem> get visibleTodos =>
      _todos.where((todo) => todo.deletedAt == null).toList();
  List<TodoItem> get deletedTodos {
    final now = DateTime.now();
    return _todos.where((todo) {
      if (todo.deletedAt == null) return false;
      return now.difference(todo.deletedAt!) < _deleteRetention;
    }).toList();
  }

  List<TodoItem> get filteredTodos {
    final query = _searchQuery.toLowerCase();
    return visibleTodos.where((todo) {
      final matchSearch = todo.title.toLowerCase().contains(query);
      final matchTag = _tagFilter == '전체' || todo.tag == _tagFilter;
      final notImportant = !todo.isHighlighted;
      return matchSearch && matchTag && notImportant;
    }).toList();
  }

  Future<void> initialize() async {
    _todos = await _repository.loadTodos();
    _purgeExpiredDeleted();
    _isLoading = false;
    notifyListeners();
  }

  void _purgeExpiredDeleted() {
    final now = DateTime.now();
    _todos.removeWhere(
      (todo) =>
          todo.deletedAt != null &&
          now.difference(todo.deletedAt!) >= _deleteRetention,
    );
  }

  Future<void> _saveAndNotify() async {
    _purgeExpiredDeleted();
    await _repository.saveTodos(_todos);
    notifyListeners();
  }

  Future<bool> addTodo(TodoItem todo) async {
    final exists = _todos.any(
      (item) =>
          item.title.trim().toLowerCase() == todo.title.trim().toLowerCase(),
    );
    if (exists) return false;
    _todos.insert(0, todo);
    await _saveAndNotify();
    return true;
  }

  Future<void> updateTodo(TodoItem updated) async {
    final index = _todos.indexWhere((todo) => todo.id == updated.id);
    if (index == -1) return;
    _todos[index] = updated;
    await _saveAndNotify();
  }

  Future<void> deleteTodo(TodoItem todo) async {
    final index = _todos.indexWhere((item) => item.id == todo.id);
    if (index == -1) return;
    _todos[index] = _todos[index].copyWith(
      deletedAt: DateTime.now(),
      overrideDeletedAt: true,
    );
    await _saveAndNotify();
  }

  Future<void> restoreTodo(TodoItem todo) async {
    final index = _todos.indexWhere((item) => item.id == todo.id);
    if (index == -1) return;
    _todos[index] = _todos[index].copyWith(
      deletedAt: null,
      overrideDeletedAt: true,
    );
    await _saveAndNotify();
  }

  Future<void> purgeTodo(TodoItem todo) async {
    _todos.removeWhere((item) => item.id == todo.id);
    await _saveAndNotify();
  }

  Future<void> setImportant(TodoItem todo, bool isImportant) async {
    final index = _todos.indexWhere((item) => item.id == todo.id);
    if (index == -1) return;
    _todos[index] = todo.copyWith(isHighlighted: isImportant);
    await _saveAndNotify();
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
    final reminderText =
        todo.reminder == null
            ? ''
            : ' • ${todo.reminder!.month}/${todo.reminder!.day}';
    final snippet =
        todo.title.length > 60 ? '${todo.title.substring(0, 60)}…' : todo.title;
    return '$snippet$reminderText';
  }

  String buildShareText(TodoItem todo) {
    final buffer = StringBuffer()..writeln('[${todo.tag}] ${todo.title}');
    if (todo.reminder != null) {
      buffer.writeln(
        '중요알림: ${todo.reminder!.month}/${todo.reminder!.day} '
        '${todo.reminder!.hour.toString().padLeft(2, '0')}:'
        '${todo.reminder!.minute.toString().padLeft(2, '0')}',
      );
    }
    return buffer.toString();
  }

  List<TodoItem> getImportantTodos(String tag) {
    return visibleTodos.where((todo) {
      final matchTag = tag == '전체' || todo.tag == tag;
      return todo.isHighlighted && matchTag;
    }).toList();
  }

  String getImportantSummaryText(String tag) {
    final filtered = getImportantTodos(tag);
    if (filtered.isEmpty) return '';
    final summary = StringBuffer('중요 메모 목록\n');
    for (final todo in filtered) {
      summary.writeln('- [${todo.tag}] ${todo.title}');
    }
    return summary.toString();
  }

  Future<void> reorderVisibleTodos(
    List<TodoItem> visible,
    int oldIndex,
    int newIndex,
  ) async {
    if (oldIndex < 0 || oldIndex >= visible.length) return;
    if (newIndex < 0 || newIndex > visible.length) return;

    // ReorderableListView reports newIndex including the gap; adjust when moving down.
    if (newIndex > oldIndex) newIndex -= 1;

    final visibleIndices =
        visible
            .map((todo) => _todos.indexWhere((t) => t.id == todo.id))
            .toList();
    if (visibleIndices.any((i) => i == -1)) return;

    final movingIndex = visibleIndices[oldIndex];
    final movingItem = _todos.removeAt(movingIndex);

    // Adjust remaining indices after removal
    for (var i = 0; i < visibleIndices.length; i++) {
      if (visibleIndices[i] > movingIndex) {
        visibleIndices[i] -= 1;
      }
    }
    visibleIndices.removeAt(oldIndex);

    final insertIndex =
        newIndex >= visibleIndices.length
            ? (visibleIndices.isEmpty ? _todos.length : visibleIndices.last + 1)
            : visibleIndices[newIndex];

    _todos.insert(insertIndex, movingItem);
    await _saveAndNotify();
  }
}
