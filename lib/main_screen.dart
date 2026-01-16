import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:todolist/create_task.dart';
import 'package:todolist/models/todo_item.dart';
import 'package:todolist/update_task.dart';
import 'package:todolist/viewmodels/todo_view_model.dart';

const double _taskCardRadius = 20.0;
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
                viewModel.visibleTodos
                    .where((todo) => todo.isHighlighted)
                    .toList();
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

                                    return _SwipeActionTile(
                                      onSave: () async {
                                        final confirm = await showDialog<bool>(
                                          context: rootContext,
                                          builder: (dialogContext) {
                                            return AlertDialog(
                                              title: const Text('메인으로 이동'),
                                              content: const Text(
                                                '이 메모를 메인 목록으로 이동할까요?',
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
                                            false,
                                          );
                                          if (rootContext.mounted) {
                                            Navigator.pop(sheetContext);
                                          }
                                        }
                                      },
                                      onDelete: () async {
                                        final confirm = await showDialog<bool>(
                                          context: rootContext,
                                          builder: (dialogContext) {
                                            return AlertDialog(
                                              title: const Text('정말 삭제'),
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
                                        if (confirm == true) {
                                          await viewModel.deleteTodo(todo);
                                          if (rootContext.mounted) {
                                            ScaffoldMessenger.of(
                                              rootContext,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  '\'${todo.title}\' 메모가 삭제됐어요',
                                                ),
                                              ),
                                            );
                                          }
                                        }
                                      },
                                      saveColor: const Color(0xFFFFD54F),
                                      deleteColor: const Color(0xFFFF5C5C),
                                      saveLabel: '이동',
                                      deleteLabel: '삭제',
                                      saveIcon: Icons.home,
                                      deleteIcon: Icons.delete,
                                      maxSlideFactor: 0.33,
                                      childBorderRadius: BorderRadius.circular(
                                        16,
                                      ),
                                      child: GestureDetector(
                                        onTap: () {
                                          Navigator.pop(sheetContext);
                                          _showTaskActionSheet(
                                            rootContext,
                                            todo,
                                          );
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(16),
                                          color:
                                              todo.isHighlighted
                                                  ? theme
                                                      .colorScheme
                                                      .primaryContainer
                                                  : theme
                                                      .colorScheme
                                                      .surfaceContainerHighest,
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
                                                            height: 6,
                                                          ),
                                                          Row(
                                                            children: [
                                                              Icon(
                                                                Icons.image,
                                                                size: 16,
                                                                color:
                                                                    theme
                                                                        .colorScheme
                                                                        .outline,
                                                              ),
                                                              const SizedBox(
                                                                width: 4,
                                                              ),
                                                              Text(
                                                                '사진 포함',
                                                                style: theme
                                                                    .textTheme
                                                                    .bodySmall
                                                                    ?.copyWith(
                                                                      color:
                                                                          theme
                                                                              .colorScheme
                                                                              .outline,
                                                                    ),
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      ],
                                                    ),
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
                                              const SizedBox(height: 6),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.end,
                                                children: [
                                                  IconButton(
                                                    visualDensity:
                                                        VisualDensity.compact,
                                                    icon: const Icon(Icons.star),
                                                    tooltip: '메인으로 이동',
                                                    color:
                                                        theme
                                                            .colorScheme
                                                            .primary,
                                                    onPressed: () async {
                                                      final confirm =
                                                          await showDialog<
                                                            bool
                                                          >(
                                                            context:
                                                                rootContext,
                                                            builder: (
                                                              dialogContext,
                                                            ) {
                                                              return AlertDialog(
                                                                title: const Text(
                                                                  '메인으로 이동',
                                                                ),
                                                                content: const Text(
                                                                  '이 메모를 메인 목록으로 이동할까요?',
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
                                                              false,
                                                            );
                                                        if (rootContext.mounted) {
                                                          ScaffoldMessenger.of(
                                                            rootContext,
                                                          ).showSnackBar(
                                                            SnackBar(
                                                              content: Text(
                                                                '\'${todo.title}\'이(가) 메인으로 이동했어요',
                                                              ),
                                                            ),
                                                          );
                                                        }
                                                      }
                                                    },
                                                  ),
                                                  const SizedBox(width: 4),
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.share,
                                                    ),
                                                    tooltip: '공유하기',
                                                    onPressed:
                                                        () => Share.share(
                                                          viewModel
                                                              .buildShareText(
                                                                todo,
                                                              ),
                                                        ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.edit,
                                                    ),
                                                    tooltip: '메모 수정',
                                                    onPressed: () {
                                                      Navigator.pop(
                                                        sheetContext,
                                                      );
                                                      showModalBottomSheet(
                                                        context: rootContext,
                                                        isScrollControlled:
                                                            true,
                                                        builder: (context) {
                                                          return Padding(
                                                            padding:
                                                                EdgeInsets.only(
                                                              bottom: MediaQuery.of(
                                                                context,
                                                              ).viewInsets.bottom,
                                                            ),
                                                            child: UpdateTask(
                                                              todo: todo,
                                                            ),
                                                          );
                                                        },
                                                      );
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ],
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
            child: SingleChildScrollView(
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
                  if (todo.imagePath != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: AspectRatio(
                        aspectRatio: 4 / 3,
                        child: Image.file(
                          File(todo.imagePath!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
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
                        _InfoChip(label: '매일', icon: Icons.autorenew),
                    ],
                  ),

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
          ),
        );
      },
    );
  }

  void _showDeletedMemoSheet(BuildContext rootContext) {
    final theme = Theme.of(rootContext);
    showModalBottomSheet(
      context: rootContext,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            final viewModel = context.watch<TodoViewModel>();
            final deleted = viewModel.deletedTodos;
            return FractionallySizedBox(
              heightFactor: 0.7,
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
                              color: theme.colorScheme.errorContainer,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.delete_outline),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '최근 삭제',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                '삭제 후 3일 내 복구할 수 있어요',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.outline,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child:
                            deleted.isEmpty
                                ? Center(
                                  child: Text(
                                    '최근 삭제된 메모가 없어요.',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.outline,
                                    ),
                                  ),
                                )
                                : ListView.separated(
                                  itemCount: deleted.length,
                                  separatorBuilder:
                                      (_, __) => const SizedBox(height: 12),
                                  itemBuilder: (itemContext, index) {
                                    final todo = deleted[index];
                                    return Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color:
                                            theme
                                                .colorScheme
                                                .surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Row(
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
                                                const SizedBox(height: 6),
                                                Wrap(
                                                  spacing: 8,
                                                  children: [
                                                    _InfoChip(
                                                      label: todo.tag,
                                                      icon: Icons.tag,
                                                    ),
                                                    if (todo.isHighlighted)
                                                      _InfoChip(
                                                        label: '중요',
                                                        icon: Icons.star,
                                                      ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              FilledButton(
                                                onPressed: () async {
                                                  await viewModel.restoreTodo(
                                                    todo,
                                                  );
                                                  if (sheetContext.mounted) {
                                                    ScaffoldMessenger.of(
                                                      rootContext,
                                                    ).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          '\'${todo.title}\' 복구했어요',
                                                        ),
                                                      ),
                                                    );
                                                  }
                                                },
                                                child: const Text('복구'),
                                              ),
                                              const SizedBox(width: 8),
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.delete_forever,
                                                ),
                                                color:
                                                    theme.colorScheme.error,
                                                tooltip: '완전 삭제',
                                                onPressed: () async {
                                                  final confirm =
                                                      await showDialog<bool>(
                                                    context: rootContext,
                                                    builder: (
                                                      dialogContext,
                                                    ) {
                                                      return AlertDialog(
                                                        title: const Text(
                                                          '완전 삭제',
                                                        ),
                                                        content: const Text(
                                                          '이 메모를 완전히 삭제할까요?',
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
                                                            style: FilledButton
                                                                .styleFrom(
                                                              backgroundColor:
                                                                  theme
                                                                      .colorScheme
                                                                      .error,
                                                            ),
                                                            child: const Text(
                                                              '삭제',
                                                            ),
                                                          ),
                                                        ],
                                                      );
                                                    },
                                                  );
                                                  if (confirm == true) {
                                                    await viewModel.purgeTodo(
                                                      todo,
                                                    );
                                                    if (sheetContext.mounted) {
                                                      ScaffoldMessenger.of(
                                                        rootContext,
                                                      ).showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                            '\'${todo.title}\' 완전히 삭제했어요',
                                                          ),
                                                        ),
                                                      );
                                                    }
                                                  }
                                                },
                                              ),
                                            ],
                                          ),
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
      },
    );
  }

  Future<void> _handleSaveTodo(
    BuildContext context,
    TodoViewModel viewModel,
    TodoItem todo,
  ) async {
    if (todo.isHighlighted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('이미 중요 메모로 저장되어 있어요')));
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('중요 메모로 이동'),
          content: const Text('이 메모를 중요 메모로 저장할까요?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('저장'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await viewModel.setImportant(todo, true);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('\'${todo.title}\'이(가) 중요 메모로 저장됐어요')),
        );
      }
    }
  }

  Future<void> _handleDeleteTodo(
    BuildContext context,
    TodoViewModel viewModel,
    TodoItem todo,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('삭제 확인'),
          content: const Text('정말로 이 메모를 삭제하시겠어요?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('삭제'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await viewModel.deleteTodo(todo);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('\'${todo.title}\' 메모가 삭제됐어요')));
      }
    }
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
            icon: const Icon(Icons.delete_outline),
            tooltip: '최근 삭제',
            onPressed: () => _showDeletedMemoSheet(context),
          ),
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
                '메모를 오른쪽에서 왼쪽으로 스와이프해 저장/삭제를 할 수 있어요.',
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
                        : ReorderableListView.builder(
                          padding: const EdgeInsets.only(bottom: 80),
                          buildDefaultDragHandles: false,
                          onReorder:
                              (oldIndex, newIndex) =>
                                  viewModel.reorderVisibleTodos(
                                    filteredTodos,
                                    oldIndex,
                                    newIndex,
                                  ),
                          itemCount: filteredTodos.length,
                          itemBuilder: (context, index) {
                            final todo = filteredTodos[index];

                            return Padding(
                              key: ValueKey(todo.id),
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _SwipeActionTile(
                                onSave:
                                    () => _handleSaveTodo(
                                      context,
                                      viewModel,
                                      todo,
                                    ),
                                onDelete:
                                    () => _handleDeleteTodo(
                                      context,
                                      viewModel,
                                      todo,
                                    ),
                                saveColor: const Color(0xFFFFD54F),
                                deleteColor: const Color(0xFFFF5C5C),
                                saveLabel: '저장',
                                deleteLabel: '삭제',
                                saveIcon: Icons.save,
                                deleteIcon: Icons.delete,
                                maxSlideFactor: 0.33,
                                childBorderRadius: _taskBorderRadius,
                                child: GestureDetector(
                                  onTap:
                                      () => _showTaskActionSheet(context, todo),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    color:
                                        todo.isHighlighted
                                            ? theme.colorScheme.primaryContainer
                                            : theme
                                                .colorScheme
                                                .surfaceContainerHighest,
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
                                                    const SizedBox(height: 6),
                                                    Row(children: [
                                                        
                                                      ],
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Wrap(
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
                                                      label: '매일',
                                                      icon: Icons.autorenew,
                                                    ),
                                                  if (todo.imagePath != null)
                                                    _InfoChip(
                                                      label: '',
                                                      icon: Icons.image,
                                                    ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Align(
                                              alignment: Alignment.bottomCenter,
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  IconButton(
                                                    visualDensity:
                                                        VisualDensity.compact,
                                                    icon: Icon(
                                                      todo.isHighlighted
                                                          ? Icons.star
                                                          : Icons.star_border,
                                                    ),
                                                    color:
                                                        theme
                                                            .colorScheme
                                                            .primary,
                                                    tooltip:
                                                        todo.isHighlighted
                                                            ? '일반 메모로 이동'
                                                            : '중요 메모로 이동',
                                                    onPressed: () async {
                                                      final confirm = await showDialog<
                                                        bool
                                                      >(
                                                        context: context,
                                                        builder: (
                                                          dialogContext,
                                                        ) {
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
                                                              !todo
                                                                  .isHighlighted,
                                                            );
                                                        if (context.mounted) {
                                                          ScaffoldMessenger.of(
                                                            context,
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
                                                  const SizedBox(width: 4),
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
                                                  const SizedBox(width: 4),
                                                  ReorderableDelayedDragStartListener(
                                                    index: index,
                                                    child: const Padding(
                                                      padding: EdgeInsets.all(
                                                        4.0,
                                                      ),
                                                      child: Icon(
                                                        Icons.drag_indicator,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
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

class _SwipeActionTile extends StatefulWidget {
  const _SwipeActionTile({
    required this.child,
    required this.onSave,
    required this.onDelete,
    required this.saveColor,
    required this.deleteColor,
    required this.saveLabel,
    required this.deleteLabel,
    required this.saveIcon,
    required this.deleteIcon,
    required this.childBorderRadius,
    this.maxSlideFactor = 0.33,
  });

  final Widget child;
  final VoidCallback onSave;
  final VoidCallback onDelete;
  final Color saveColor;
  final Color deleteColor;
  final String saveLabel;
  final String deleteLabel;
  final IconData saveIcon;
  final IconData deleteIcon;
  final BorderRadius childBorderRadius;
  final double maxSlideFactor;

  @override
  State<_SwipeActionTile> createState() => _SwipeActionTileState();
}

class _SwipeActionTileState extends State<_SwipeActionTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Animation<double>? _animation;
  double _offsetX = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    )..addListener(() {
      if (_animation == null) return;
      setState(() {
        _offsetX = _animation!.value;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _animateTo(double target) {
    _controller.stop();
    _animation = Tween<double>(
      begin: _offsetX,
      end: target,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxSlide = constraints.maxWidth * widget.maxSlideFactor;
        final dragProgress = (-_offsetX / maxSlide).clamp(0.0, 1.0);
        final radiusProgress = ((dragProgress - 0.7) / 0.25).clamp(0.0, 1.0);
        final easedProgress = Curves.easeOut.transform(radiusProgress);
        final leftOnlyRadius = BorderRadius.only(
          topLeft: widget.childBorderRadius.topLeft,
          bottomLeft: widget.childBorderRadius.bottomLeft,
        );
        final rightOnlyRadius = const BorderRadius.horizontal(
          right: Radius.circular(_taskCardRadius),
        );
        final childRadius = BorderRadius.lerp(
          widget.childBorderRadius,
          leftOnlyRadius,
          easedProgress,
        )!;
        final backgroundRadius = BorderRadius.lerp(
          _taskBorderRadius,
          rightOnlyRadius,
          easedProgress,
        )!;

        return GestureDetector(
          onHorizontalDragUpdate: (details) {
            _controller.stop();
            final nextOffset = (_offsetX + details.delta.dx).clamp(
              -maxSlide,
              0.0,
            );
            if (nextOffset != _offsetX) {
              setState(() {
                _offsetX = nextOffset;
              });
            }
          },
          onHorizontalDragEnd: (_) {
            final shouldOpen = _offsetX.abs() >= maxSlide * 0.6;
            _animateTo(shouldOpen ? -maxSlide : 0.0);
          },
          child: Stack(
            children: [
              Positioned.fill(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: ClipRRect(
                    borderRadius: backgroundRadius,
                    child: SizedBox(
                      width: maxSlide,
                      child: Row(
                        children: [
                          Expanded(
                            child: _SwipeActionButton(
                              color: widget.saveColor,
                              icon: widget.saveIcon,
                              label: widget.saveLabel,
                              onTap: () {
                                _animateTo(0.0);
                                widget.onSave();
                              },
                            ),
                          ),
                          Expanded(
                            child: _SwipeActionButton(
                              color: widget.deleteColor,
                              icon: widget.deleteIcon,
                              label: widget.deleteLabel,
                              onTap: () {
                                _animateTo(0.0);
                                widget.onDelete();
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Transform.translate(
                offset: Offset(_offsetX, 0),
                child: ClipRRect(
                  borderRadius: childRadius,
                  child: widget.child,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SwipeActionButton extends StatelessWidget {
  const _SwipeActionButton({
    required this.color,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final Color color;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
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
