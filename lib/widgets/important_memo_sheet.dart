import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:baromemo/models/todo_item.dart';
import 'package:baromemo/viewmodels/todo_view_model.dart';
import 'package:baromemo/widgets/info_chip.dart';
import 'package:baromemo/widgets/swipe_action_tile.dart';
import 'package:baromemo/theme/app_theme.dart';

class ImportantMemoSheetContent extends StatefulWidget {
  final BuildContext rootContext;
  final Function(BuildContext, TodoItem) onShowTaskActionSheet;

  const ImportantMemoSheetContent({
    super.key,
    required this.rootContext,
    required this.onShowTaskActionSheet,
  });

  @override
  State<ImportantMemoSheetContent> createState() =>
      _ImportantMemoSheetContentState();
}

class _ImportantMemoSheetContentState extends State<ImportantMemoSheetContent> {
  String selectedTag = '전체';
  String? _localMessage;

  void _showMessage(String message) {
    setState(() {
      _localMessage = message;
    });
    // 2초 후 메시지 제거
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _localMessage = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewModel = context.watch<TodoViewModel>();
    final filteredImportant = viewModel.getImportantTodos(selectedTag);

    return FractionallySizedBox(
      heightFactor: 0.8,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Stack(
            children: [
              Column(
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
                          final text = viewModel.getImportantSummaryText(
                            selectedTag,
                          );
                          if (text.isNotEmpty) {
                            await Share.share(text);
                          }
                        },
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            size: 20,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final tag in ['전체', '일반', '개인', '업무', '건강', '학습'])
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
                                return ImportantTodoTile(
                                  todo: todo,
                                  viewModel: viewModel,
                                  rootContext: widget.rootContext,
                                  onShowActionSheet:
                                      widget.onShowTaskActionSheet,
                                  onMessage: _showMessage,
                                );
                              },
                            ),
                  ),
                ],
              ),
              // 커머스 스타일의 간단한 로컬 알림
              if (_localMessage != null)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        _localMessage!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class ImportantTodoTile extends StatefulWidget {
  final TodoItem todo;
  final TodoViewModel viewModel;
  final BuildContext rootContext;
  final Function(BuildContext, TodoItem) onShowActionSheet;
  final Function(String) onMessage;

  const ImportantTodoTile({
    super.key,
    required this.todo,
    required this.viewModel,
    required this.rootContext,
    required this.onShowActionSheet,
    required this.onMessage,
  });

  @override
  State<ImportantTodoTile> createState() => _ImportantTodoTileState();
}

class _ImportantTodoTileState extends State<ImportantTodoTile> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(widget.rootContext);
    const double taskCardRadius = 20.0;
    const BorderRadius taskBorderRadius = BorderRadius.all(
      Radius.circular(taskCardRadius),
    );

    return SwipeActionTile(
      onSave: () async {
        final confirm = await showDialog<bool>(
          context: widget.rootContext,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('메인으로 이동'),
              content: const Text('이 메모를 메인 목록으로 이동할까요?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('취소'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                  ),
                  child: const Text('이동'),
                ),
              ],
            );
          },
        );
        if (confirm == true) {
          await widget.viewModel.setImportant(widget.todo, false);
          if (widget.rootContext.mounted) {
            // ignore: use_build_context_synchronously
            Navigator.pop(context);
          }
        }
      },
      onDelete: () async {
        final confirm = await showDialog<bool>(
          context: widget.rootContext,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('정말 삭제'),
              content: const Text('정말로 이 메모를 삭제하시겠어요?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('취소'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.warningRed,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('삭제'),
                ),
              ],
            );
          },
        );
        if (confirm == true) {
          await widget.viewModel.deleteTodo(widget.todo);
          if (widget.rootContext.mounted) {
            // ignore: use_build_context_synchronously
            ScaffoldMessenger.of(widget.rootContext).showSnackBar(
              SnackBar(content: Text('\'${widget.todo.title}\' 메모가 삭제됐어요')),
            );
          }
        }
      },
      saveColor: AppTheme.importantYellow,
      deleteColor: AppTheme.warningRed,
      saveLabel: '이동',
      deleteLabel: '삭제',
      saveIcon: Icons.home,
      deleteIcon: Icons.delete,
      maxSlideFactor: 0.33,
      childBorderRadius: taskBorderRadius,
      isHighlighted: widget.todo.isHighlighted,
      child: GestureDetector(
        onTap: () {
          Navigator.pop(context);
          widget.onShowActionSheet(widget.rootContext, widget.todo);
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap:
                        () => widget.viewModel.toggleCompletion(widget.todo.id),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12, top: 2),
                      child: Icon(
                        widget.todo.isCompleted
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color:
                            widget.todo.isCompleted
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outline,
                        size: 24,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.todo.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color:
                                widget.todo.isCompleted
                                    ? theme.colorScheme.outline
                                    : Colors.black87,
                            decoration:
                                widget.todo.isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                            decorationColor: theme.colorScheme.outline,
                          ),
                        ),
                        if (widget.todo.imagePath != null) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.image,
                                size: 16,
                                color: theme.colorScheme.outline,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '사진 포함',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.outline,
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
                  InfoChip(label: widget.todo.tag, icon: Icons.tag),
                  if (widget.todo.showOnWidget)
                    InfoChip(
                      label: '위젯 노출 중',
                      icon: Icons.widgets,
                      color: AppTheme.widgetAlert,
                    ),
                  if (widget.todo.reminder != null)
                    InfoChip(
                      label:
                          '${widget.todo.reminder!.month}/${widget.todo.reminder!.day}',
                      icon: Icons.alarm,
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.star),
                    tooltip: '메인으로 이동',
                    color: const Color(0xFF00796B),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: widget.rootContext,
                        builder: (dialogContext) {
                          return AlertDialog(
                            title: const Text('메인으로 이동'),
                            content: const Text('이 메모를 메인 목록으로 이동할까요?'),
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
                                  backgroundColor: theme.colorScheme.primary,
                                  foregroundColor: theme.colorScheme.onPrimary,
                                ),
                                child: const Text('이동'),
                              ),
                            ],
                          );
                        },
                      );
                      if (confirm == true) {
                        await widget.viewModel.setImportant(widget.todo, false);
                        if (widget.rootContext.mounted) {
                          // ignore: use_build_context_synchronously
                          ScaffoldMessenger.of(widget.rootContext).showSnackBar(
                            SnackBar(
                              content: Text(
                                '\'${widget.todo.title}\'이(가) 메인으로 이동했어요',
                              ),
                            ),
                          );
                        }
                      }
                    },
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: Icon(
                      widget.todo.showOnWidget
                          ? Icons.push_pin
                          : Icons.push_pin_outlined,
                      color: Colors.redAccent,
                      size: 20,
                    ),
                    tooltip: '위젯에 고정',
                    onPressed: () async {
                      final success = await widget.viewModel
                          .toggleWidgetVisibility(widget.todo.id);
                      if (context.mounted) {
                        if (!success) {
                          widget.onMessage('위젯 노출은 3개까지만 가능합니다.');
                        } else {
                          final isNowOnWidget = !widget.todo.showOnWidget;
                          if (isNowOnWidget) {
                            if (widget.todo.isHighlighted) {
                              await widget.viewModel.reorderTodoToTop(
                                widget.todo.id,
                              );
                              widget.onMessage('중요 메모를 위젯 최상단에 고정했습니다 📌');
                            } else {
                              widget.onMessage('위젯 고정을 활성화했습니다 📌');
                            }
                          } else {
                            widget.onMessage('위젯 고정을 해제했습니다.');
                          }
                        }
                      }
                    },
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.share, color: Colors.black87),
                    tooltip: '공유하기',
                    onPressed:
                        () => Share.share(
                          widget.viewModel.buildShareText(widget.todo),
                        ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(
                      Icons.drag_indicator,
                      color: Colors.black87,
                    ),
                    tooltip: '메모 수정',
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onShowActionSheet(widget.rootContext, widget.todo);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
