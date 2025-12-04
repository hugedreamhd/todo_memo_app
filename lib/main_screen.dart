import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:todolist/create_task.dart';
import 'package:todolist/models/todo_item.dart';
import 'package:todolist/update_task.dart';
import 'package:todolist/viewmodels/todo_view_model.dart';

const double _taskCardRadius = 20.0;
const double _thumbnailHeight = 140;
const BorderRadius _taskBorderRadius = BorderRadius.all(
  Radius.circular(_taskCardRadius),
);

class MainScreen extends StatelessWidget {
  final VoidCallback onToggleTheme;
  final bool isDarkMode;

  const MainScreen({
    super.key,
    required this.onToggleTheme,
    required this.isDarkMode,
  });

  void _showImportantMemoSheet(BuildContext rootContext) {
    final theme = Theme.of(rootContext);
    String selectedTag = '전체';
    showModalBottomSheet(
      context: rootContext,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            final viewModel = context.watch<TodoViewModel>();
            final importantAll =
                viewModel.todos.where((todo) => todo.isHighlighted).toList();
            final filteredImportant =
                importantAll
                    .where(
                      (todo) => selectedTag == '전체' || todo.tag == selectedTag,
                    )
                    .toList();

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
                                '중요 메모',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                '${filteredImportant.length}개의 중요 메모가 있어요',
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
                              if (filteredImportant.isEmpty) return;
                              final summary = StringBuffer('중요 메모 목록\n');
                              for (final todo in filteredImportant) {
                                summary.writeln(
                                  '- [${todo.tag}] ${todo.title}',
                                );
                              }
                              if (summary.isEmpty) return;
                              await Share.share(summary.toString());
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (final tag in [
                              '전체',
                              '일반',
                              '개인',
                              '업무',
                              '건강',
                              '학습',
                            ])
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(tag),
                                  selected: selectedTag == tag,
                                  onSelected: (_) {
                                    setState(() {
                                      selectedTag = tag;
                                    });
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child:
                            filteredImportant.isEmpty
                                ? Center(
                                  child: Text(
                                    '아직 선택한 태그의 중요 메모가 없어요.',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.outline,
                                    ),
                                  ),
                                )
                                : ListView.separated(
                                  itemCount: filteredImportant.length,
                                  separatorBuilder:
                                      (_, __) => const SizedBox(height: 16),
                                  itemBuilder: (itemContext, index) {
                                    final todo = filteredImportant[index];
                                    final completed =
                                        todo.checklist
                                            .where((item) => item.isDone)
                                            .length;
                                    return GestureDetector(
                                      onTap: () {
                                        Navigator.pop(sheetContext);
                                        _showTaskActionSheet(rootContext, todo);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color:
                                              todo.isHighlighted
                                                  ? theme
                                                      .colorScheme
                                                      .primaryContainer
                                                  : theme
                                                      .colorScheme
                                                      .surfaceContainerHighest
                                                      .withValues(alpha: 0.6),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        todo.title,
                                                        style: theme
                                                            .textTheme
                                                            .titleMedium
                                                            ?.copyWith(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                      ),
                                                      if (todo.imagePath !=
                                                          null) ...[
                                                        const SizedBox(
                                                          height: 8,
                                                        ),
                                                        ClipRRect(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                12,
                                                              ),
                                                          child: SizedBox(
                                                            height:
                                                                _thumbnailHeight,
                                                            width:
                                                                double.infinity,
                                                            child: Image.file(
                                                              File(
                                                                todo.imagePath!,
                                                              ),
                                                              fit: BoxFit.cover,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: Icon(
                                                    todo.isHighlighted
                                                        ? Icons.star
                                                        : Icons.star_border,
                                                  ),
                                                  color:
                                                      theme.colorScheme.primary,
                                                  tooltip:
                                                      todo.isHighlighted
                                                          ? '일반 메모로 이동'
                                                          : '중요 메모로 이동',
                                                  onPressed: () async {
                                                    final confirm = await showDialog<
                                                      bool
                                                    >(
                                                      context: rootContext,
                                                      builder: (dialogContext) {
                                                        return AlertDialog(
                                                          title: Text(
                                                            todo.isHighlighted
                                                                ? '일반 메모로 이동'
                                                                : '중요 메모로 이동',
                                                          ),
                                                          content: Text(
                                                            todo.isHighlighted
                                                                ? '이 메모를 일반 메모로 이동할까요?'
                                                                : '이 메모를 중요 메모로 이동할까요?',
                                                          ),
                                                          actions: [
                                                            TextButton(
                                                              onPressed:
                                                                  () => Navigator.pop(
                                                                    dialogContext,
                                                                    false,
                                                                  ),
                                                              child: const Text(
                                                                '취소',
                                                              ),
                                                            ),
                                                            FilledButton(
                                                              onPressed:
                                                                  () => Navigator.pop(
                                                                    dialogContext,
                                                                    true,
                                                                  ),
                                                              child: const Text(
                                                                '이동',
                                                              ),
                                                            ),
                                                          ],
                                                        );
                                                      },
                                                    );

                                                    if (confirm == true) {
                                                      await viewModel
                                                          .setImportant(
                                                            todo,
                                                            !todo.isHighlighted,
                                                          );
                                                      if (rootContext.mounted) {
                                                        ScaffoldMessenger.of(
                                                          rootContext,
                                                        ).showSnackBar(
                                                          SnackBar(
                                                            content: Text(
                                                              todo.isHighlighted
                                                                  ? '\'${todo.title}\'이(가) 일반 메모로 이동했어요'
                                                                  : '\'${todo.title}\'이(가) 중요 메모로 이동했어요',
                                                            ),
                                                          ),
                                                        );
                                                      }
                                                    }
                                                  },
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
      },
    );
  }

  void _showTaskActionSheet(BuildContext context, TodoItem todo) {
    final theme = Theme.of(context);
    final viewModel = context.read<TodoViewModel>();
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
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _InfoChip(label: todo.tag, icon: Icons.tag),
                    if (todo.reminder != null)
                      _InfoChip(
                        label:
                            '${todo.reminder!.month}/${todo.reminder!.day} ${todo.reminder!.hour.toString().padLeft(2, '0')}:${todo.reminder!.minute.toString().padLeft(2, '0')}',
                        icon: Icons.alarm,
                      ),
                    if (todo.repeatDaily)
                      _InfoChip(label: '매일 반복', icon: Icons.autorenew),
                  ],
                ),
                if (todo.checklist.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    '체크리스트 ${todo.checklist.where((item) => item.isDone).length}/${todo.checklist.length}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 16),
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
                          child: UpdateTask(todo: todo),
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
                    await Share.share(viewModel.buildShareText(todo));
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
                      await viewModel.deleteTodo(todo);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('\'${todo.title}\' 메모가 삭제됐어요'),
                          ),
                        );
                      }
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
    final viewModel = context.watch<TodoViewModel>();
    final filteredTodos = viewModel.filteredTodos;

    return Scaffold(
      appBar: AppBar(
        title: const Text('오늘의 할 일'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: onToggleTheme,
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
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: '메모 검색',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onChanged: viewModel.setSearchQuery,
              ),
              const SizedBox(height: 12),
              Text(
                '메모를 왼쪽/오른쪽으로 스와이프해서 삭제하거나 중요 메모로 이동할 수 있어요.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    DropdownButton<String>(
                      value: viewModel.tagFilter,
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
                          viewModel.setTagFilter(value);
                        }
                      },
                    ),
                    const SizedBox(width: 12),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child:
                    filteredTodos.isEmpty
                        ? Center(
                          child: Text(
                            '표시할 메모가 없어요 :)',
                            style: theme.textTheme.titleMedium,
                          ),
                        )
                        : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 80),
                          itemCount: filteredTodos.length,
                          itemBuilder: (context, index) {
                            final todo = filteredTodos[index];
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
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (dialogContext) {
                                          return AlertDialog(
                                            title: const Text('중요 메모로 이동'),
                                            content: const Text(
                                              '이 메모를 중요 메모로 이동할까요?',
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
                                                child: const Text('이동'),
                                              ),
                                            ],
                                          );
                                        },
                                      );

                                      if (confirm == true) {
                                        await viewModel.setImportant(
                                          todo,
                                          true,
                                        );
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                '\'${todo.title}\'이(가) 중요 메모로 이동했어요',
                                              ),
                                            ),
                                          );
                                        }
                                        return true;
                                      }

                                      return false;
                                    }
                                  },
                                  onDismissed: (direction) {
                                    if (direction ==
                                        DismissDirection.startToEnd) {
                                      viewModel.deleteTodo(todo);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            '\'${todo.title}\' 메모가 삭제됐어요',
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  child: GestureDetector(
                                    onTap:
                                        () =>
                                            _showTaskActionSheet(context, todo),
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
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      todo.title,
                                                      style: theme
                                                          .textTheme
                                                          .titleMedium
                                                          ?.copyWith(
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                    ),
                                                    if (todo.imagePath !=
                                                        null) ...[
                                                      const SizedBox(height: 8),
                                                      ClipRRect(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12,
                                                            ),
                                                        child: SizedBox(
                                                          height:
                                                              _thumbnailHeight,
                                                          width:
                                                              double.infinity,
                                                          child: Image.file(
                                                            File(
                                                              todo.imagePath!,
                                                            ),
                                                            fit: BoxFit.contain,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.star_border,
                                                    ),
                                                    color:
                                                        theme
                                                            .colorScheme
                                                            .primary,
                                                    tooltip: '중요 메모로 이동',
                                                    onPressed: () async {
                                                      final confirm = await showDialog<
                                                        bool
                                                      >(
                                                        context: context,
                                                        builder: (
                                                          dialogContext,
                                                        ) {
                                                          return AlertDialog(
                                                            title: const Text(
                                                              '중요 메모로 이동',
                                                            ),
                                                            content: const Text(
                                                              '이 메모를 중요 메모로 이동할까요?',
                                                            ),
                                                            actions: [
                                                              TextButton(
                                                                onPressed:
                                                                    () => Navigator.pop(
                                                                      dialogContext,
                                                                      false,
                                                                    ),
                                                                child:
                                                                    const Text(
                                                                      '취소',
                                                                    ),
                                                              ),
                                                              FilledButton(
                                                                onPressed:
                                                                    () => Navigator.pop(
                                                                      dialogContext,
                                                                      true,
                                                                    ),
                                                                child:
                                                                    const Text(
                                                                      '이동',
                                                                    ),
                                                              ),
                                                            ],
                                                          );
                                                        },
                                                      );
                                                      if (confirm == true) {
                                                        await viewModel
                                                            .setImportant(
                                                              todo,
                                                              true,
                                                            );
                                                        if (context.mounted) {
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            SnackBar(
                                                              content: Text(
                                                                '\'${todo.title}\'이(가) 중요 메모로 이동했어요',
                                                              ),
                                                            ),
                                                          );
                                                        }
                                                      }
                                                    },
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.share,
                                                    ),
                                                    onPressed:
                                                        () => Share.share(
                                                          viewModel
                                                              .buildShareText(
                                                                todo,
                                                              ),
                                                        ),
                                                  ),
                                                ],
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
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: () => _showImportantMemoSheet(context),
                  icon: const Icon(Icons.star),
                  label: const Text(
                    '중요 메모 보기',
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
              const SizedBox(width: 15),
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: '메모 추가',
                style: IconButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(10),
                ),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (context) {
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).viewInsets.bottom,
                        ),
                        child: const CreateTask(),
                      );
                    },
                  );
                },
              ),
            ],
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
