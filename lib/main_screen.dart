import 'dart:io';
import 'package:baromemo/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:baromemo/create_task.dart';
import 'package:baromemo/models/todo_item.dart';
import 'package:baromemo/update_task.dart';
import 'package:baromemo/widgets/important_memo_sheet.dart';
import 'package:baromemo/widgets/info_chip.dart';
import 'package:baromemo/widgets/my_banner_ad_widget.dart';
import 'package:baromemo/widgets/swipe_action_tile.dart';
import 'package:baromemo/viewmodels/todo_view_model.dart';
import 'package:baromemo/main.dart' show quickAddNotifier, openTodoIdNotifier;
import 'package:showcaseview/showcaseview.dart';
import 'package:baromemo/widgets/showcase_keys.dart';
import 'package:baromemo/viewmodels/onboarding_view_model.dart';

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
  @override
  void initState() {
    super.initState();
    // 홈 위젯에서 탭 이벤트 감지 → 메모 추가 시트 자동 팝업
    quickAddNotifier.addListener(_onQuickAddRequested);
    // 홈 위젯에서 특정 메모 탭 이벤트 감지
    openTodoIdNotifier.addListener(_onOpenTodoRequested);
    // 앱이 위젯 탭으로 시작된 경우 즉시 처리
    if (quickAddNotifier.value) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _triggerQuickAdd();
      });
    }
    final initialTodoId = openTodoIdNotifier.value;
    if (initialTodoId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openTodoById(initialTodoId);
      });
    }
  }

  @override
  void dispose() {
    quickAddNotifier.removeListener(_onQuickAddRequested);
    openTodoIdNotifier.removeListener(_onOpenTodoRequested);
    super.dispose();
  }

  void _onQuickAddRequested() {
    if (quickAddNotifier.value) {
      _triggerQuickAdd();
    }
  }

  void _onOpenTodoRequested() {
    final todoId = openTodoIdNotifier.value;
    if (todoId == null) return;
    _openTodoById(todoId);
  }

  void _triggerQuickAdd() {
    quickAddNotifier.value = false; // 재실행 방지
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder:
          (ctx) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: const CreateTask(),
          ),
    );
  }

  void _openTodoById(String todoId) {
    if (!mounted) return;
    final viewModel = context.read<TodoViewModel>();
    TodoItem? target;
    try {
      target = viewModel.visibleTodos.firstWhere((todo) => todo.id == todoId);
    } catch (_) {
      target = null;
    }
    if (target == null) return;
    openTodoIdNotifier.value = null; // 한 번만 처리
    // 위젯에서 열었을 때 뒤에 남아 있는 다른 메모 시트/화면 제거
    Navigator.of(context).popUntil((route) => route.isFirst);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showTaskActionSheet(context, target!);
    });
  }

  void _showImportantMemoSheet(BuildContext rootContext) {
    showModalBottomSheet(
      context: rootContext,
      isScrollControlled: true,
      builder:
          (sheetContext) => ImportantMemoSheetContent(
            rootContext: rootContext,
            onShowTaskActionSheet: _showTaskActionSheet,
          ),
    );
  }

  void _showTaskActionSheet(BuildContext rootContext, TodoItem todo) {
    final theme = Theme.of(rootContext);
    final viewModel = rootContext.read<TodoViewModel>();
    showModalBottomSheet(
      context: rootContext,
      isScrollControlled: true,
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const SizedBox(width: 40),
                      const Spacer(),
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.outlineVariant,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(sheetContext),
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
                  const SizedBox(height: 24),
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: const Icon(Icons.description),
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
                      InfoChip(label: todo.tag, icon: Icons.tag),
                      if (todo.reminder != null)
                        InfoChip(
                          label:
                              '${todo.reminder!.month}/${todo.reminder!.day} ${todo.reminder!.hour.toString().padLeft(2, '0')}:${todo.reminder!.minute.toString().padLeft(2, '0')}',
                          icon: Icons.alarm,
                        ),
                      if (todo.repeatDaily)
                        InfoChip(label: '매일', icon: Icons.autorenew),
                      // 실제로 위젯에 표시 중인 메모만 상태를 보여줍니다.
                      if (viewModel.activeWidgetIds.contains(todo.id))
                        InfoChip(
                          label: '위젯 노출 중',
                          icon: Icons.widgets,
                          color: AppTheme.widgetAlert,
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () async {
                      final success = await viewModel.toggleWidgetVisibility(
                        todo.id,
                      );
                      if (rootContext.mounted) {
                        // 뒤에 남아 있을 수 있는 다른 메모 시트까지 모두 닫고 메인으로
                        Navigator.of(
                          rootContext,
                        ).popUntil((route) => route.isFirst);
                        if (!success) {
                          ScaffoldMessenger.of(rootContext).showSnackBar(
                            const SnackBar(
                              content: Text('위젯 노출은 3개까지만 가능합니다.'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        } else {
                          String message;
                          final isNowOnWidget = !todo.showOnWidget;
                          if (isNowOnWidget) {
                            if (todo.isHighlighted) {
                              await viewModel.reorderTodoToTop(todo.id);
                              message = '중요 메모를 위젯 최상단에 고정했습니다 📌';
                            } else {
                              message = '위젯 고정을 활성화했습니다 📌';
                            }
                          } else {
                            message = '위젯 고정을 해제했습니다.';
                          }
                          ScaffoldMessenger.of(
                            rootContext,
                          ).showSnackBar(SnackBar(content: Text(message)));
                        }
                      }
                    },
                    icon: Icon(
                      todo.showOnWidget
                          ? Icons.push_pin
                          : Icons.push_pin_outlined,
                    ),
                    label: Text(todo.showOnWidget ? '위젯 고정 해제' : '위젯에 고정 📌'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      backgroundColor: theme.colorScheme.tertiaryContainer,
                      foregroundColor: theme.colorScheme.onTertiaryContainer,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      showModalBottomSheet(
                        context: rootContext,
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
                      final confirm = await showDialog<bool>(
                        context: rootContext,
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
                                  backgroundColor: AppTheme.warningRed,
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
                          Navigator.pop(sheetContext);
                          ScaffoldMessenger.of(rootContext).showSnackBar(
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
                      backgroundColor: AppTheme.warningRed,
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
                                                    InfoChip(
                                                      label: todo.tag,
                                                      icon: Icons.tag,
                                                    ),
                                                    if (todo.isHighlighted)
                                                      InfoChip(
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
                                                  final confirm = await showDialog<
                                                    bool
                                                  >(
                                                    context: rootContext,
                                                    builder: (dialogContext) {
                                                      return AlertDialog(
                                                        title: const Text(
                                                          '복구 확인',
                                                        ),
                                                        content: Text(
                                                          '\'${todo.title}\' 메모를 복구할까요?',
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
                                                              '복구',
                                                            ),
                                                          ),
                                                        ],
                                                      );
                                                    },
                                                  );

                                                  if (confirm == true) {
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
                                                  }
                                                },
                                                child: const Text('복구'),
                                              ),
                                              const SizedBox(width: 8),
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.delete_forever,
                                                ),
                                                color: theme.colorScheme.error,
                                                tooltip: '완전 삭제',
                                                onPressed: () async {
                                                  final confirm = await showDialog<
                                                    bool
                                                  >(
                                                    context: rootContext,
                                                    builder: (dialogContext) {
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
                                                            style: FilledButton.styleFrom(
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
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.importantYellow,
                foregroundColor: Colors.white,
              ),
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
    final onToggleTheme = widget.onToggleTheme;
    final isDarkMode = widget.isDarkMode;

    return ShowCaseWidget(
      builder: (context) {
        // 올바른 빌드 컨텍스트(ShowCaseWidget의 하위 컨텍스트)에서 가이드 시작
        final onboardingVM = context.read<OnboardingViewModel>();
        if (onboardingVM.shouldShowGuide) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            // 중복 실행 방지 위해 다시 한 번 확인
            if (onboardingVM.shouldShowGuide) {
              onboardingVM.startGuide(context);
              onboardingVM.completeGuide();
            }
          });
        }
        return Scaffold(
          appBar: AppBar(
            title: const Text('바로메모'),
            centerTitle: true,
            actions: [
              //가이드 버튼
              Showcase(
                key: ShowcaseKeys.trashKey,
                description: '삭제한 메모는 휴지통에서 확인할 수 있어요',
                child: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: '최근 삭제',
                  onPressed: () => _showDeletedMemoSheet(context),
                ),
              ),

              Showcase(
                key: ShowcaseKeys.darkModeKey,
                description: '앱의 테마를 변경할 수 있어요',
                child: IconButton(
                  icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
                  onPressed: onToggleTheme,
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Showcase(
                    key: ShowcaseKeys.searchKey,
                    description: '검색어로 메모를 빠르게 찾을 수 있어요',
                    child: TextField(
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        hintText: '메모 검색',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onChanged: viewModel.setSearchQuery,
                    ),
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
                        Showcase(
                          key: ShowcaseKeys.tagKey,
                          description: '태그별로 메모를 분류해서 볼 수 있어요',
                          child: DropdownButton<String>(
                            value: viewModel.tagFilter,
                            items: const [
                              DropdownMenuItem(
                                value: '전체',
                                child: Text('전체 태그'),
                              ),
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
                                  child: SwipeActionTile(
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
                                    saveColor: AppTheme.importantYellow,
                                    deleteColor: AppTheme.warningRed,
                                    saveLabel: '저장',
                                    deleteLabel: '삭제',
                                    saveIcon: Icons.save,
                                    deleteIcon: Icons.delete,
                                    maxSlideFactor: 0.33,
                                    childBorderRadius: _taskBorderRadius,
                                    isHighlighted: todo.isHighlighted,
                                    child: GestureDetector(
                                      onTap:
                                          () => _showTaskActionSheet(
                                            context,
                                            todo,
                                          ),
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                GestureDetector(
                                                  onTap:
                                                      () => viewModel
                                                          .toggleCompletion(
                                                            todo.id,
                                                          ),
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          right: 12,
                                                          top: 2,
                                                        ),
                                                    child: Icon(
                                                      todo.isCompleted
                                                          ? Icons.check_circle
                                                          : Icons
                                                              .radio_button_unchecked,
                                                      color:
                                                          todo.isCompleted
                                                              ? theme
                                                                  .colorScheme
                                                                  .primary
                                                              : theme
                                                                  .colorScheme
                                                                  .outline,
                                                      size: 24,
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        todo.title,
                                                        style: theme.textTheme.titleMedium?.copyWith(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color:
                                                              todo.isCompleted
                                                                  ? theme
                                                                      .colorScheme
                                                                      .outline
                                                                  : Colors
                                                                      .black87,
                                                          decoration:
                                                              todo.isCompleted
                                                                  ? TextDecoration
                                                                      .lineThrough
                                                                  : null,
                                                          decorationColor:
                                                              theme
                                                                  .colorScheme
                                                                  .outline,
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
                                                      InfoChip(
                                                        label: todo.tag,
                                                        icon: Icons.tag,
                                                      ),
                                                      // 스마트 큐 상태 표시 (완료되지 않은 경우에만 표시)
                                                      if (!todo.isCompleted &&
                                                          todo.showOnWidget)
                                                        InfoChip(
                                                          label: '위젯 노출 중',
                                                          icon: Icons.widgets,
                                                          color: AppTheme.widgetAlert,
                                                        ),
                                                      if (todo.reminder != null)
                                                        InfoChip(
                                                          label:
                                                              '${todo.reminder!.month}/${todo.reminder!.day} ${todo.reminder!.hour.toString().padLeft(2, '0')}:${todo.reminder!.minute.toString().padLeft(2, '0')}',
                                                          icon: Icons.alarm,
                                                        ),
                                                      if (todo.repeatDaily)
                                                        InfoChip(
                                                          label: '매일',
                                                          icon: Icons.autorenew,
                                                        ),
                                                      if (todo.imagePath !=
                                                          null)
                                                        InfoChip(
                                                          label: '',
                                                          icon: Icons.image,
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Align(
                                                  alignment:
                                                      Alignment.bottomCenter,
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      IconButton(
                                                        visualDensity:
                                                            VisualDensity
                                                                .compact,
                                                        icon: Icon(
                                                          todo.isHighlighted
                                                              ? Icons.star
                                                              : Icons
                                                                  .star_border,
                                                        ),
                                                        color: const Color(
                                                          0xFF00796B,
                                                        ), // Deep Teal for better visibility on light background
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
                                                            if (context
                                                                .mounted) {
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
                                                        visualDensity:
                                                            VisualDensity
                                                                .compact,
                                                        icon: Icon(
                                                          todo.showOnWidget
                                                              ? Icons.push_pin
                                                              : Icons
                                                                  .push_pin_outlined,
                                                          color:
                                                              Colors.redAccent,
                                                          size: 20,
                                                        ),
                                                        tooltip: '위젯에 고정',
                                                        onPressed: () async {
                                                          final success =
                                                              await viewModel
                                                                  .toggleWidgetVisibility(
                                                                    todo.id,
                                                                  );
                                                          if (context.mounted) {
                                                            if (!success) {
                                                              ScaffoldMessenger.of(
                                                                context,
                                                              ).showSnackBar(
                                                                const SnackBar(
                                                                  content: Text(
                                                                    '위젯 노출은 3개까지만 가능합니다.',
                                                                  ),
                                                                  duration:
                                                                      Duration(
                                                                        seconds:
                                                                            2,
                                                                      ),
                                                                ),
                                                              );
                                                            } else {
                                                              final isNowOnWidget =
                                                                  !todo
                                                                      .showOnWidget;
                                                              if (isNowOnWidget) {
                                                                String message;
                                                                if (todo
                                                                    .isHighlighted) {
                                                                  await viewModel
                                                                      .reorderTodoToTop(
                                                                        todo.id,
                                                                      );
                                                                  message =
                                                                      '중요 메모를 위젯 최상단에 고정했습니다 📌';
                                                                } else {
                                                                  message =
                                                                      '위젯 고정을 활성화했습니다 📌';
                                                                }
                                                                ScaffoldMessenger.of(
                                                                  context,
                                                                ).showSnackBar(
                                                                  SnackBar(
                                                                    content: Text(
                                                                      message,
                                                                    ),
                                                                  ),
                                                                );
                                                              } else {
                                                                ScaffoldMessenger.of(
                                                                  context,
                                                                ).showSnackBar(
                                                                  const SnackBar(
                                                                    content: Text(
                                                                      '위젯 고정을 해제했습니다.',
                                                                    ),
                                                                  ),
                                                                );
                                                              }
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
                                                          padding:
                                                              EdgeInsets.all(
                                                                4.0,
                                                              ),
                                                          child: Icon(
                                                            Icons
                                                                .drag_indicator,
                                                            color:
                                                                Colors.black87,
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                MyBannerAdWidget(), // 광고 배치
                const SizedBox(height: 5),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Showcase(
                          key: ShowcaseKeys.importantMemoKey,
                          description: '별표 표시한 중요 메모들만 따로 모아볼 수 있어요',
                          child: FilledButton.tonalIcon(
                            onPressed: () => _showImportantMemoSheet(context),
                            icon: const Icon(Icons.star),
                            label: const Text(
                              '중요 메모 보기',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.black87,
                              minimumSize: const Size.fromHeight(52),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Showcase(
                        key: ShowcaseKeys.addMemoKey,
                        description: '새로운 메모를 작성하려면 이 버튼을 누르세요',
                        child: IconButton(
                          icon: const Icon(Icons.add),
                          tooltip: '메모 추가',
                          style: IconButton.styleFrom(
                            backgroundColor: AppTheme.pointGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.all(10),
                          ),
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              builder: (context) {
                                return FractionallySizedBox(
                                  heightFactor: 0.8, //화면높이 80%
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                      bottom:
                                          MediaQuery.of(
                                            context,
                                          ).viewInsets.bottom,
                                    ),
                                    child: const CreateTask(),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
