import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:baromemo/models/todo_item.dart';
import 'package:baromemo/repositories/todo_repository_interface.dart';
import 'package:baromemo/services/notification_service_interface.dart';
import 'package:baromemo/services/widget_sync_service.dart';

class TodoViewModel extends ChangeNotifier with WidgetsBindingObserver {
  TodoViewModel(this._repository, this._notificationService) {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // 앱이 다시 포그라운드로 올 때 백그라운드 위젯 변경 사항 화면 반영
      // 위젯 데이터는 이미 최신이므로 불필요한 위젯 동기화를 방지하여 로딩 속도 개선
      initialize(syncWidget: false);
    }
  }

  final TodoRepositoryInterface _repository;
  final NotificationServiceInterface _notificationService;
  final WidgetSyncService _widgetSyncService = WidgetSyncService();
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

  Future<void> initialize({bool syncWidget = true}) async {
    _todos = await _repository.loadTodos();
    _purgeExpiredDeleted();

    _isLoading = false;
    notifyListeners(); // 화면 렌더링에 필요한 데이터 업데이트 즉시 반영

    if (syncWidget) {
      // 위젯 동기화는 앱 렌더링을 멈추지 않도록 백그라운드로 실행
      _syncWidgetDataSafely();
    }
  }

  Future<void> _syncWidgetDataSafely() async {
    try {
      await _widgetSyncService.updateWidgetData(visibleTodos);
    } catch (e) {
      if (kDebugMode) {
        print('Widget sync failed: $e');
      }
    }
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
    try {
      // 홈 위젯을 동기화합니다 (showOnWidget이 true인 항목 위주로 업데이트)
      await _widgetSyncService.updateWidgetData(visibleTodos);
    } catch (e) {
      if (kDebugMode) {
        print('Widget sync failed: $e');
      }
    }
    notifyListeners();
  }

  Future<bool> addTodo(TodoItem todo) async {
    // 제목이나 이미지와 상관없이 항상 새 메모로 추가합니다.
    _todos.insert(0, todo);
    await _saveAndNotify();
    // 알림 예약 (reminder 있을 때만)
    if (todo.reminder != null) {
      await _notificationService.scheduleOrUpdate(todo);
    }
    return true;
  }

  Future<void> updateTodo(TodoItem updated) async {
    final index = _todos.indexWhere((todo) => todo.id == updated.id);
    if (index == -1) return;
    _todos[index] = updated;
    await _saveAndNotify();
    // 알림 갱신 (scheduleOrUpdate 내부에서 취소 후 재등록 또는 취소 처리)
    await _notificationService.scheduleOrUpdate(updated);
  }

  Future<void> deleteTodo(TodoItem todo) async {
    final index = _todos.indexWhere((item) => item.id == todo.id);
    if (index == -1) return;
    _todos[index] = _todos[index].copyWith(
      deletedAt: DateTime.now(),
      overrideDeletedAt: true,
      showOnWidget: false,
    );
    await _saveAndNotify();
    // 삭제 시 알림 취소
    await _notificationService.cancel(todo.id);
  }

  Future<void> restoreTodo(TodoItem todo) async {
    final index = _todos.indexWhere((item) => item.id == todo.id);
    if (index == -1) return;
    _todos[index] = _todos[index].copyWith(
      deletedAt: null,
      overrideDeletedAt: true,
    );
    await _saveAndNotify();
    // 복원 시 reminder 있으면 알림 재예약
    final restored = _todos[index];
    if (restored.reminder != null) {
      await _notificationService.scheduleOrUpdate(restored);
    }
  }

  Future<void> purgeTodo(TodoItem todo) async {
    _todos.removeWhere((item) => item.id == todo.id);
    await _saveAndNotify();
    // 영구 삭제 시 알림 취소
    await _notificationService.cancel(todo.id);
  }

  Future<void> setImportant(TodoItem todo, bool isImportant) async {
    final index = _todos.indexWhere((item) => item.id == todo.id);
    if (index == -1) return;
    _todos[index] = todo.copyWith(isHighlighted: isImportant);
    await _saveAndNotify();
  }

  Future<void> toggleCompletion(String id) async {
    final index = _todos.indexWhere((item) => item.id == id);
    if (index == -1) return;
    _todos[index] = _todos[index].copyWith(
      isCompleted: !_todos[index].isCompleted,
    );
    await _saveAndNotify();
  }

  Future<bool> toggleWidgetVisibility(String id) async {
    final index = _todos.indexWhere((item) => item.id == id);
    if (index == -1) return false;

    final isCurrentlyOnWidget = _todos[index].showOnWidget;

    if (!isCurrentlyOnWidget) {
      final widgetCount =
          visibleTodos.where((item) => item.showOnWidget).length;
      if (widgetCount >= 3) {
        return false; // 3개 제한
      }
    }

    _todos[index] = _todos[index].copyWith(showOnWidget: !isCurrentlyOnWidget);
    await _saveAndNotify();
    return true;
  }

  Future<void> reorderTodoToTop(String id) async {
    final index = _todos.indexWhere((item) => item.id == id);
    if (index <= 0) return; // 이미 맨 위거나 못 찾음

    final item = _todos.removeAt(index);
    _todos.insert(0, item);
    await _saveAndNotify();
  }

  /// 현재 위젯에 실제로 표시되는 메모 ID 집합 (상위 3개)
  Set<String> get activeWidgetIds {
    final active =
        visibleTodos
            .where((t) => t.showOnWidget)
            .take(3)
            .map((t) => t.id)
            .toSet();
    return active;
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
