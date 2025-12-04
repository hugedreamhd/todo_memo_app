import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:todolist/models/todo_item.dart';
import 'package:todolist/viewmodels/todo_view_model.dart';

class CreateTask extends StatefulWidget {
  const CreateTask({super.key});

  @override
  State<CreateTask> createState() => _CreateTaskState();
}

class _CreateTaskState extends State<CreateTask> {
  final TextEditingController _titleController = TextEditingController();
  final List<TextEditingController> _checklistControllers = [];
  final List<String> _suggestions = [
    '운동 30분',
    '독서 20분',
    '감사 일기 쓰기',
    '집안 정리',
    '물 8잔 마시기',
  ];
  String? _errorText;
  String _selectedTag = '일반';
  DateTime? _reminder;
  bool _repeatDaily = false;
  bool _highlight = false;
  String? _imagePath;

  final ImagePicker _imagePicker = ImagePicker();

  @override
  void dispose() {
    _titleController.dispose();
    for (final controller in _checklistControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addChecklistField({String initial = ''}) {
    final controller = TextEditingController(text: initial);
    setState(() {
      _checklistControllers.add(controller);
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _imagePicker.pickImage(
      source: source,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (picked == null) return;
    setState(() {
      _imagePath = picked.path;
    });
  }

  Future<void> _pickReminder() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null) return;
    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return;
    if (!mounted) return;
    setState(() {
      _reminder = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  String _summaryPreview(String text) {
    if (text.isEmpty &&
        _checklistControllers.every(
          (controller) => controller.text.trim().isEmpty,
        )) {
      return '입력한 내용이 요약으로 표시됩니다.';
    }
    final buffer = StringBuffer();
    if (text.isNotEmpty) {
      buffer.write(text.length > 40 ? '${text.substring(0, 40)}…' : text);
    }
    final nonEmptyChecklist =
        _checklistControllers.where((c) => c.text.trim().isNotEmpty).length;
    if (nonEmptyChecklist > 0) {
      if (buffer.isNotEmpty) buffer.write('\n');
      buffer.write('체크리스트 $nonEmptyChecklist개 포함');
    }
    return buffer.toString();
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _errorText = '메모를 입력해주세요');
      return;
    }
    final checklist =
        _checklistControllers
            .where((controller) => controller.text.trim().isNotEmpty)
            .map(
              (controller) => ChecklistItem(
                id: DateTime.now().microsecondsSinceEpoch.toString(),
                text: controller.text.trim(),
              ),
            )
            .toList();
    final todo = TodoItem(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      tag: _selectedTag,
      checklist: checklist,
      reminder: _reminder,
      repeatDaily: _repeatDaily,
      isHighlighted: _highlight,
      imagePath: _imagePath,
    );
    final viewModel = context.read<TodoViewModel>();
    final success = await viewModel.addTodo(todo);
    if (!success && mounted) {
      showDialog(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('알림'),
            content: const Text('이미 동일한 메모가 있어요. 다른 내용을 입력해 주세요.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('확인'),
              ),
            ],
          );
        },
      );
      return;
    }
    if (!mounted) return;
    Navigator.pop(context);
    setState(() {
      _errorText = null;
      _selectedTag = '일반';
      _reminder = null;
      _repeatDaily = false;
      _highlight = false;
      _imagePath = null;
      _titleController.clear();
      for (final controller in _checklistControllers) {
        controller.dispose();
      }
      _checklistControllers.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '메모 추가',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '오늘 기록하고 싶은 내용을 간단하게 적어보세요.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    _suggestions.map((suggestion) {
                      return ActionChip(
                        label: Text(suggestion),
                        onPressed: () {
                          _titleController.text = suggestion;
                          setState(() => _errorText = null);
                        },
                      );
                    }).toList(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _titleController,
                autofocus: true,
                maxLines: 3,
                textInputAction: TextInputAction.newline,
                onChanged: (_) {
                  if (_errorText != null) {
                    setState(() => _errorText = null);
                  }
                  setState(() {});
                },
                decoration: InputDecoration(
                  labelText: '메모 내용',
                  hintText: '예) 헬스장 등록, 서점 방문, 장보기',
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.6),
                  alignLabelWithHint: true,
                  prefixIcon: const Icon(Icons.edit_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: theme.colorScheme.primary),
                  ),
                  errorText: _errorText,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.5,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _summaryPreview(_titleController.text),
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '사진 추가',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('갤러리에서 선택'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.photo_camera_outlined),
                      label: const Text('카메라로 촬영'),
                    ),
                  ),
                ],
              ),
              if (_imagePath != null) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      AspectRatio(
                        aspectRatio: 1 / 1,
                        child: Image.file(File(_imagePath!), fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.4),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 18,
                            ),
                            onPressed: () {
                              setState(() {
                                _imagePath = null;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Text(
                '태그 선택',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children:
                    ['일반', '개인', '업무', '건강', '학습'].map((tag) {
                      final isSelected = _selectedTag == tag;
                      return ChoiceChip(
                        label: Text(tag),
                        selected: isSelected,
                        onSelected: (_) => setState(() => _selectedTag = tag),
                      );
                    }).toList(),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '체크리스트',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _addChecklistField,
                    icon: const Icon(Icons.add_task),
                    label: const Text('항목 추가'),
                  ),
                ],
              ),
              Column(
                children:
                    _checklistControllers.isEmpty
                        ? [
                          Text(
                            '체크리스트를 추가해 세부 작업을 관리해보세요.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        ]
                        : _checklistControllers.map((controller) {
                          final index = _checklistControllers.indexOf(
                            controller,
                          );
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                const Icon(Icons.drag_indicator, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: controller,
                                    decoration: InputDecoration(
                                      hintText: '항목 ${index + 1}',
                                      border: const OutlineInputBorder(),
                                    ),
                                    onChanged: (_) => setState(() {}),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () {
                                    setState(() {
                                      controller.dispose();
                                      _checklistControllers.remove(controller);
                                    });
                                  },
                                ),
                              ],
                            ),
                          );
                        }).toList(),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickReminder,
                      icon: const Icon(Icons.alarm_add_rounded),
                      label: Text(
                        _reminder == null
                            ? '알림 시간 설정'
                            : '${_reminder!.month}/${_reminder!.day} ${_reminder!.hour.toString().padLeft(2, '0')}:${_reminder!.minute.toString().padLeft(2, '0')}',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SwitchListTile(
                      value: _repeatDaily,
                      onChanged:
                          (value) => setState(() => _repeatDaily = value),
                      title: const Text('매일 반복'),
                    ),
                  ),
                ],
              ),
              SwitchListTile(
                value: _highlight,
                onChanged: (value) => setState(() => _highlight = value),
                title: const Text('중요 메모에 저장'),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _submit,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  backgroundColor: const Color(0xFF4C6EF5),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                icon: const Icon(Icons.check_rounded),
                label: const Text(
                  '메모 저장',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
