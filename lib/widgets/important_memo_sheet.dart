import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:baromemo/models/todo_item.dart';
import 'package:baromemo/viewmodels/todo_view_model.dart';
import 'package:baromemo/widgets/info_chip.dart';
import 'package:baromemo/widgets/swipe_action_tile.dart';

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
                              onShowActionSheet: widget.onShowTaskActionSheet,
                              activeWidgetIds: viewModel.activeWidgetIds,
                            );
                          },
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ImportantTodoTile extends StatelessWidget {
  final TodoItem todo;
  final TodoViewModel viewModel;
  final BuildContext rootContext;
  final Function(BuildContext, TodoItem) onShowActionSheet;
  final Set<String> activeWidgetIds;

  const ImportantTodoTile({
    super.key,
    required this.todo,
    required this.viewModel,
    required this.rootContext,
    required this.onShowActionSheet,
    this.activeWidgetIds = const {},
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(rootContext);
    const double taskCardRadius = 20.0;
    const BorderRadius taskBorderRadius = BorderRadius.all(
      Radius.circular(taskCardRadius),
    );

    return SwipeActionTile(
      onSave: () async {
        final confirm = await showDialog<bool>(
          context: rootContext,
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
          await viewModel.setImportant(todo, false);
          if (rootContext.mounted) {
            Navigator.pop(context);
          }
        }
      },
      onDelete: () async {
        final confirm = await showDialog<bool>(
          context: rootContext,
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
                    backgroundColor: const Color(0xFFFF5C5C),
                    foregroundColor: Colors.white,
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
            ScaffoldMessenger.of(rootContext).showSnackBar(
              SnackBar(content: Text('\'${todo.title}\' 메모가 삭제됐어요')),
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
      childBorderRadius: taskBorderRadius,
      isHighlighted: todo.isHighlighted,
      child: GestureDetector(
        onTap: () {
          Navigator.pop(context);
          onShowActionSheet(rootContext, todo);
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
                    onTap: () => viewModel.toggleCompletion(todo.id),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12, top: 2),
                      child: Icon(
                        todo.isCompleted
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color:
                            todo.isCompleted
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
                          todo.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color:
                                todo.isCompleted
                                    ? theme.colorScheme.outline
                                    : Colors.black87,
                            decoration:
                                todo.isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                            decorationColor: theme.colorScheme.outline,
                          ),
                        ),
                        if (todo.imagePath != null) ...[
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
                  InfoChip(label: todo.tag, icon: Icons.tag),
                  // 스마트 큐 상태 표시 (완료되지 않은 경우에만 표시)
                  if (!todo.isCompleted &&
                      (todo.showOnWidget || todo.isHighlighted)) ...[
                    if (activeWidgetIds.contains(todo.id))
                      InfoChip(
                        label: '위젯 노출 중',
                        icon: Icons.widgets,
                        color: const Color(0xFF1976D2),
                      )
                    else
                      InfoChip(
                        label: '위젯 대기',
                        icon: Icons.hourglass_top,
                        color: const Color(0xFF9E9E9E),
                      ),
                  ],
                  if (todo.reminder != null)
                    InfoChip(
                      label: '${todo.reminder!.month}/${todo.reminder!.day}',
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
                        context: rootContext,
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
                        await viewModel.setImportant(todo, false);
                        if (rootContext.mounted) {
                          ScaffoldMessenger.of(rootContext).showSnackBar(
                            SnackBar(
                              content: Text('\'${todo.title}\'이(가) 메인으로 이동했어요'),
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
                      color: Colors.black87,
                    ), // 블랙 계열로 고정
                    tooltip: '공유하기',
                    onPressed:
                        () => Share.share(viewModel.buildShareText(todo)),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(
                      Icons.drag_indicator,
                      color: Colors.black87,
                    ),
                    tooltip: '메모 수정',
                    onPressed: () {
                      Navigator.pop(context); // 시트 닫기
                      onShowActionSheet(rootContext, todo);
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
