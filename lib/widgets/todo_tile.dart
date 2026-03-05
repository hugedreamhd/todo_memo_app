import 'package:flutter/material.dart';
import 'package:baromemo/models/todo_item.dart';
import 'package:baromemo/widgets/info_chip.dart';
import 'package:baromemo/widgets/swipe_action_tile.dart';

class TodoTile extends StatelessWidget {
  final TodoItem todo;
  final VoidCallback onTap;
  final VoidCallback onToggleCompletion;
  final VoidCallback onSave;
  final VoidCallback onDelete;
  final VoidCallback onShare;
  final VoidCallback onEdit;
  final VoidCallback onToggleHighlight;
  final Color saveColor;
  final String saveLabel;
  final IconData saveIcon;
  final BorderRadius borderRadius;
  final Widget? trailing;

  const TodoTile({
    super.key,
    required this.todo,
    required this.onTap,
    required this.onToggleCompletion,
    required this.onSave,
    required this.onDelete,
    required this.onShare,
    required this.onEdit,
    required this.onToggleHighlight,
    this.saveColor = const Color(0xFFFFD54F),
    this.saveLabel = '저장',
    this.saveIcon = Icons.save,
    this.borderRadius = const BorderRadius.all(Radius.circular(20.0)),
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SwipeActionTile(
      onSave: onSave,
      onDelete: onDelete,
      saveColor: saveColor,
      deleteColor: const Color(0xFFFF5C5C),
      saveLabel: saveLabel,
      deleteLabel: '삭제',
      saveIcon: saveIcon,
      deleteIcon: Icons.delete,
      maxSlideFactor: 0.33,
      childBorderRadius: borderRadius,
      isHighlighted: todo.isHighlighted,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: onToggleCompletion,
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
                        InfoChip(label: todo.tag, icon: Icons.tag),
                        if (todo.showOnWidget)
                          InfoChip(label: '고정', icon: Icons.push_pin),
                        if (todo.reminder != null)
                          InfoChip(
                            label:
                                '${todo.reminder!.month}/${todo.reminder!.day} ${todo.reminder!.hour.toString().padLeft(2, '0')}:${todo.reminder!.minute.toString().padLeft(2, '0')}',
                            icon: Icons.alarm,
                          ),
                        if (todo.repeatDaily)
                          InfoChip(label: '매일', icon: Icons.autorenew),
                        if (todo.imagePath != null)
                          InfoChip(label: '', icon: Icons.image),
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
                          visualDensity: VisualDensity.compact,
                          icon: Icon(
                            todo.isHighlighted ? Icons.star : Icons.star_border,
                          ),
                          color: const Color(0xFF00796B),
                          tooltip:
                              todo.isHighlighted ? '일반 메모로 이동' : '중요 메모로 이동',
                          onPressed: onToggleHighlight,
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.share, color: Colors.black87),
                          tooltip: '공유하기',
                          onPressed: onShare,
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.edit, color: Colors.black87),
                          tooltip: '메모 수정',
                          onPressed: onEdit,
                        ),
                        if (trailing != null) ...[
                          const SizedBox(width: 4),
                          trailing!,
                        ],
                      ],
                    ),
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
