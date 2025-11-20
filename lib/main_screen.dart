import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todolist/create_task.dart';
import 'package:todolist/models/todo_item.dart';
import 'package:todolist/update_task.dart';

const double _taskCardRadius = 20.0;
const BorderRadius _taskBorderRadius = BorderRadius.all(
  Radius.circular(_taskCardRadius),
);

class MainScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final bool isDarkMode;

  const MainScreen({
    super.key,
    required this.onToggleTheme,
    required this.isDarkMode,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<TodoItem> _todoList = [];
  String _searchQuery = '';
  String _tagFilter = '전체';
  String _priorityFilter = '전체';
  bool _highlightOnly = false;

  @override
  void initState() {
    super.initState();
    readLocalData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<TodoItem> get _filteredTodos {
    return _todoList.where((todo) {
      final matchSearch = todo.title.toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
      final matchTag = _tagFilter == '전체' || todo.tag == _tagFilter;
      final matchPriority =
          _priorityFilter == '전체' || todo.priority == _priorityFilter;
      final matchHighlight = !_highlightOnly || todo.isHighlighted;
      return matchSearch && matchTag && matchPriority && matchHighlight;
    }).toList();
  }

  Future<void> createTodo(TodoItem todo) async {
    if (_todoList.any((item) => item.title == todo.title)) {
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('알림'),
            content: const Text('이미 동일한 메모가 있어요. 다른 내용을 입력해 주세요.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('확인'),
              ),
            ],
          );
        },
      );
      return;
    }
    setState(() {
      _todoList.insert(0, todo);
    });
    await writeLocalData();
    if (mounted) Navigator.pop(context);
  }

  Future<void> writeLocalData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('todolist_v2', TodoItem.encodeList(_todoList));
  }

  Future<void> readLocalData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('todolist_v2');
    if (raw != null) {
      setState(() {
        _todoList = TodoItem.decodeList(raw);
      });
      return;
    }
    final legacy = prefs.getStringList('todolist');
    if (legacy != null) {
      final now = DateTime.now();
      setState(() {
        _todoList = List.generate(legacy.length, (index) {
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
      });
      await writeLocalData();
    }
  }

  Future<void> updateLocalData(TodoItem updated) async {
    final index = _todoList.indexWhere((todo) => todo.id == updated.id);
    if (index == -1) return;
    setState(() {
      _todoList[index] = updated;
    });
    await writeLocalData();
  }

  Future<void> _deleteTodo(TodoItem todo) async {
    setState(() {
      _todoList.removeWhere((item) => item.id == todo.id);
    });
    await writeLocalData();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('\'${todo.title}\' 메모가 삭제됐어요')));
  }

  Future<void> _shareTodo(TodoItem todo) async {
    final buffer =
        StringBuffer()
          ..writeln('[${todo.tag}] ${todo.title}')
          ..writeln('우선순위: ${todo.priority}');
    if (todo.checklist.isNotEmpty) {
      for (final item in todo.checklist) {
        buffer.writeln('- [${item.isDone ? 'x' : ' '}] ${item.text}');
      }
    }
    if (todo.reminder != null) {
      buffer.writeln(
        '리마인더: ${todo.reminder!.month}/${todo.reminder!.day} ${todo.reminder!.hour.toString().padLeft(2, '0')}:${todo.reminder!.minute.toString().padLeft(2, '0')}',
      );
    }
    await Share.share(buffer.toString());
  }

  String _generateSummary(TodoItem todo) {
    final checklistDone =
        todo.checklist.where((item) => item.isDone).length.toString();
    final checklistTotal = todo.checklist.length.toString();
    final snippet =
        todo.title.length > 60 ? '${todo.title.substring(0, 60)}…' : todo.title;
    final reminderText =
        todo.reminder != null
            ? ' • ${todo.reminder!.month}/${todo.reminder!.day}'
            : '';
    return '$snippet\n체크리스트: $checklistDone/$checklistTotal$reminderText';
  }

  void _showSavedMemoSheet() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return FractionallySizedBox(
          heightFactor: 0.8,
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.bookmarks_outlined),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '저장된 메모',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '${_todoList.length}개의 메모가 있어요',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.share),
                        onPressed: () async {
                          if (_todoList.isEmpty) return;
                          final summary = _todoList
                              .map((todo) => '- [${todo.tag}] ${todo.title}')
                              .join('\n');
                          await Share.share('저장된 메모 목록\n$summary');
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child:
                        _todoList.isEmpty
                            ? Center(
                              child: Text(
                                '아직 저장된 메모가 없어요.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.outline,
                                ),
                              ),
                            )
                            : ListView.separated(
                              itemCount: _todoList.length,
                              separatorBuilder:
                                  (_, __) => const SizedBox(height: 16),
                              itemBuilder: (context, index) {
                                final todo = _todoList[index];
                                final completed =
                                    todo.checklist
                                        .where((item) => item.isDone)
                                        .length;
                                return Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color:
                                        todo.isHighlighted
                                            ? theme.colorScheme.primaryContainer
                                            : theme
                                                .colorScheme
                                                .surfaceContainerHighest
                                                .withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        todo.title,
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          _InfoChip(
                                            label: todo.tag,
                                            icon: Icons.tag,
                                          ),
                                          _InfoChip(
                                            label: todo.priority,
                                            icon: Icons.flag,
                                          ),
                                          if (todo.reminder != null)
                                            _InfoChip(
                                              label:
                                                  '${todo.reminder!.month}/${todo.reminder!.day}',
                                              icon: Icons.alarm,
                                            ),
                                        ],
                                      ),
                                      if (todo.checklist.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          '체크리스트 $completed/${todo.checklist.length}',
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              },
                            ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showTaskActionSheet(TodoItem todo) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: const Icon(Icons.auto_awesome),
                  ),
                  title: Text(
                    todo.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    _generateSummary(todo),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (context) {
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: MediaQuery.of(context).viewInsets.bottom,
                          ),
                          child: UpdateTask(
                            todo: todo,
                            onUpdate: (updated) => updateLocalData(updated),
                          ),
                        );
                      },
                    );
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('메모 수정'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () async {
                    Navigator.pop(sheetContext);
                    await _shareTodo(todo);
                  },
                  icon: const Icon(Icons.share),
                  label: const Text('공유하기'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    backgroundColor: theme.colorScheme.secondaryContainer,
                    foregroundColor: theme.colorScheme.onSecondaryContainer,
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () async {
                    Navigator.pop(sheetContext);
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (dialogContext) {
                        return AlertDialog(
                          title: const Text('삭제 확인'),
                          content: Text('정말로 "${todo.title}" 메모를 삭제할까요?'),
                          actions: [
                            TextButton(
                              onPressed:
                                  () => Navigator.pop(dialogContext, false),
                              child: const Text('취소'),
                            ),
                            FilledButton(
                              onPressed:
                                  () => Navigator.pop(dialogContext, true),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFFFF5C5C),
                              ),
                              child: const Text('삭제'),
                            ),
                          ],
                        );
                      },
                    );
                    if (confirm == true) {
                      await _deleteTodo(todo);
                    }
                  },
                  icon: const Icon(Icons.delete_forever),
                  label: const Text('메모 삭제'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    backgroundColor: const Color(0xFFFF5C5C),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('오늘의 할 일'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: widget.onToggleTheme,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: '메모 검색',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onChanged:
                    (value) => setState(() => _searchQuery = value.trim()),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    DropdownButton<String>(
                      value: _tagFilter,
                      items: const [
                        DropdownMenuItem(value: '전체', child: Text('전체 태그')),
                        DropdownMenuItem(value: '일반', child: Text('일반')),
                        DropdownMenuItem(value: '개인', child: Text('개인')),
                        DropdownMenuItem(value: '업무', child: Text('업무')),
                        DropdownMenuItem(value: '건강', child: Text('건강')),
                        DropdownMenuItem(value: '학습', child: Text('학습')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _tagFilter = value);
                        }
                      },
                    ),
                    const SizedBox(width: 12),
                    DropdownButton<String>(
                      value: _priorityFilter,
                      items: const [
                        DropdownMenuItem(value: '전체', child: Text('전체 우선순위')),
                        DropdownMenuItem(value: '낮음', child: Text('낮음')),
                        DropdownMenuItem(value: '보통', child: Text('보통')),
                        DropdownMenuItem(value: '높음', child: Text('높음')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _priorityFilter = value);
                        }
                      },
                    ),
                    const SizedBox(width: 12),
                    FilterChip(
                      label: const Text('중요 메모'),
                      selected: _highlightOnly,
                      onSelected:
                          (value) => setState(() => _highlightOnly = value),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child:
                    _filteredTodos.isEmpty
                        ? Center(
                          child: Text(
                            '표시할 메모가 없어요 :)',
                            style: theme.textTheme.titleMedium,
                          ),
                        )
                        : ListView.builder(
                          itemCount: _filteredTodos.length,
                          itemBuilder: (context, index) {
                            final todo = _filteredTodos[index];
                            final completed =
                                todo.checklist
                                    .where((item) => item.isDone)
                                    .length;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: ClipRRect(
                                borderRadius: _taskBorderRadius,
                                child: Dismissible(
                                  key: ValueKey(todo.id),
                                  background: Container(
                                    color: Colors.red.withValues(alpha: 0.9),
                                    alignment: Alignment.centerLeft,
                                    padding: const EdgeInsets.only(left: 20),
                                    child: const Icon(
                                      Icons.delete,
                                      color: Colors.white,
                                    ),
                                  ),
                                  secondaryBackground: Container(
                                    color: theme.colorScheme.primary,
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 20),
                                    child: const Icon(
                                      Icons.save,
                                      color: Colors.white,
                                    ),
                                  ),
                                  confirmDismiss: (direction) async {
                                    if (direction ==
                                        DismissDirection.startToEnd) {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (dialogContext) {
                                          return AlertDialog(
                                            title: const Text('삭제 확인'),
                                            content: const Text(
                                              '정말로 이 메모를 삭제하시겠어요?',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed:
                                                    () => Navigator.pop(
                                                      dialogContext,
                                                      false,
                                                    ),
                                                child: const Text('취소'),
                                              ),
                                              FilledButton(
                                                onPressed:
                                                    () => Navigator.pop(
                                                      dialogContext,
                                                      true,
                                                    ),
                                                child: const Text('삭제'),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                      return confirm == true;
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            '\'${todo.title}\' 저장됨',
                                          ),
                                        ),
                                      );
                                      return false;
                                    }
                                  },
                                  onDismissed: (_) => _deleteTodo(todo),
                                  child: GestureDetector(
                                    onTap: () => _showTaskActionSheet(todo),
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      color:
                                          todo.isHighlighted
                                              ? theme
                                                  .colorScheme
                                                  .primaryContainer
                                              : theme
                                                  .colorScheme
                                                  .surfaceContainerHighest
                                                  .withValues(alpha: 0.6),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  todo.title,
                                                  style: theme
                                                      .textTheme
                                                      .titleMedium
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.share),
                                                onPressed:
                                                    () => _shareTodo(todo),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            children: [
                                              _InfoChip(
                                                label: todo.tag,
                                                icon: Icons.tag,
                                              ),
                                              _InfoChip(
                                                label: todo.priority,
                                                icon: Icons.flag,
                                              ),
                                              if (todo.reminder != null)
                                                _InfoChip(
                                                  label:
                                                      '${todo.reminder!.month}/${todo.reminder!.day} ${todo.reminder!.hour.toString().padLeft(2, '0')}:${todo.reminder!.minute.toString().padLeft(2, '0')}',
                                                  icon: Icons.alarm,
                                                ),
                                              if (todo.repeatDaily)
                                                _InfoChip(
                                                  label: '매일 반복',
                                                  icon: Icons.autorenew,
                                                ),
                                            ],
                                          ),
                                          if (todo.checklist.isNotEmpty) ...[
                                            const SizedBox(height: 12),
                                            LinearProgressIndicator(
                                              value:
                                                  todo.checklist.isEmpty
                                                      ? 0
                                                      : completed /
                                                          todo.checklist.length,
                                              backgroundColor:
                                                  theme.colorScheme.surface,
                                              color: theme.colorScheme.primary,
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              '체크리스트 $completed/${todo.checklist.length}',
                                              style: theme.textTheme.bodySmall,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (context) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: CreateTask(createTodo: createTodo),
              );
            },
          );
        },
        backgroundColor: theme.colorScheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: FilledButton.tonalIcon(
            onPressed: _showSavedMemoSheet,
            icon: const Icon(Icons.bookmarks_outlined),
            label: const Text(
              '저장된 메모 보기',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 16), const SizedBox(width: 4), Text(label)],
      ),
    );
  }
}
