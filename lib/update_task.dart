import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todolist/models/todo_item.dart';
import 'package:todolist/viewmodels/todo_view_model.dart';
import 'package:image_picker/image_picker.dart';

class UpdateTask extends StatefulWidget {
  final TodoItem todo;

  const UpdateTask({super.key, required this.todo});

  @override
  State<UpdateTask> createState() => _UpdateTaskState();
}

class _UpdateTaskState extends State<UpdateTask> {
  late TextEditingController _titleController;
  late List<_ChecklistEntry> _checklistEntries;
  late String _selectedTag;
  DateTime? _reminder;
  bool _repeatDaily = false;
  bool _highlight = false;
  String? _errorText;
  String? _imagePath;

  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.todo.title);
    _checklistEntries =
        widget.todo.checklist
            .map(
              (item) => _ChecklistEntry(
                id: item.id,
                controller: TextEditingController(text: item.text),
                isDone: item.isDone,
              ),
            )
            .toList();
    _selectedTag = widget.todo.tag;
    _reminder = widget.todo.reminder;
    _repeatDaily = widget.todo.repeatDaily;
    _highlight = widget.todo.isHighlighted;
    _imagePath = widget.todo.imagePath;
  }

  @override
  void dispose() {
    _titleController.dispose();
    for (final entry in _checklistEntries) {
      entry.controller.dispose();
    }
    super.dispose();
  }

  void _addChecklistEntry() {
    setState(() {
      _checklistEntries.add(
        _ChecklistEntry(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          controller: TextEditingController(),
        ),
      );
    });
  }

  void _removeChecklistEntry(_ChecklistEntry entry) {
    setState(() {
      entry.controller.dispose();
      _checklistEntries.remove(entry);
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
      initialDate: _reminder ?? now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null) return;
    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime:
          _reminder != null
              ? TimeOfDay.fromDateTime(_reminder!)
              : TimeOfDay.fromDateTime(now),
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

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _errorText = '메모를 입력해주세요');
      return;
    }
    final checklist =
        _checklistEntries
            .where((entry) => entry.controller.text.trim().isNotEmpty)
            .map(
              (entry) => ChecklistItem(
                id: entry.id,
                text: entry.controller.text.trim(),
                isDone: entry.isDone,
              ),
            )
            .toList();

    final updated = widget.todo.copyWith(
      title: title,
      tag: _selectedTag,
      checklist: checklist,
      reminder: _reminder,
      overrideReminder: true,
      repeatDaily: _repeatDaily,
      isHighlighted: _highlight,
      imagePath: _imagePath,
      overrideImagePath: true,
    );

    final viewModel = context.read<TodoViewModel>();
    await viewModel.updateTodo(updated);
    if (!mounted) return;
    Navigator.pop(context);
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
                '메모 수정',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '텍스트와 체크리스트, 중요알림을 수정할 수 있어요.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.outline,
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
                        aspectRatio: 4 / 3,
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
              TextField(
                controller: _titleController,
                autofocus: true,
                maxLines: 3,
                textInputAction: TextInputAction.newline,
                onChanged: (_) {
                  if (_errorText != null) {
                    setState(() => _errorText = null);
                  }
                },
                decoration: InputDecoration(
                  labelText: '메모 내용',
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.6),
                  alignLabelWithHint: true,
                  prefixIcon: const Icon(Icons.edit_note_rounded),
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
              const SizedBox(height: 16),
              Text(
                '태그',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children:
                    ['일반', '개인', '업무', '건강', '학습'].map((tag) {
                      return ChoiceChip(
                        label: Text(tag),
                        selected: _selectedTag == tag,
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
                    onPressed: _addChecklistEntry,
                    icon: const Icon(Icons.add_task),
                    label: const Text('항목 추가'),
                  ),
                ],
              ),
              Column(
                children:
                    _checklistEntries.isEmpty
                        ? [
                          Text(
                            '체크리스트가 없어요. 필요한 항목을 추가해보세요.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        ]
                        : _checklistEntries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: entry.isDone,
                                  onChanged: (value) {
                                    setState(() {
                                      entry.isDone = value ?? false;
                                    });
                                  },
                                ),
                                Expanded(
                                  child: TextField(
                                    controller: entry.controller,
                                    decoration: InputDecoration(
                                      hintText: '세부 항목',
                                      border: const OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () => _removeChecklistEntry(entry),
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
                      icon: const Icon(Icons.alarm),
                      label: Text(
                        _reminder == null
                            ? '알림'
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
              if (_reminder != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => setState(() => _reminder = null),
                    child: const Text('중요알림 삭제'),
                  ),
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
                icon: const Icon(Icons.check_circle_rounded),
                label: const Text(
                  '변경 사항 저장',
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

class _ChecklistEntry {
  _ChecklistEntry({
    required this.id,
    required this.controller,
    this.isDone = false,
  });

  final String id;
  final TextEditingController controller;
  bool isDone;
}
