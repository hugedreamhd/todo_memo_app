import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:baromemo/models/todo_item.dart';
import 'package:baromemo/widgets/my_banner_ad_widget.dart';

class TaskForm extends StatefulWidget {
  final TodoItem? initialTodo;
  final String submitLabel;
  final IconData submitIcon;
  final Function(
    String title,
    String tag,
    DateTime? reminder,
    bool repeatDaily,
    bool highlight,
    String? imagePath,
  )
  onSubmit;
  final List<String> suggestions;
  final bool showAd;

  const TaskForm({
    super.key,
    this.initialTodo,
    required this.submitLabel,
    required this.submitIcon,
    required this.onSubmit,
    this.suggestions = const [],
    this.showAd = false,
  });

  @override
  State<TaskForm> createState() => _TaskFormState();
}

class _TaskFormState extends State<TaskForm> {
  late TextEditingController _titleController;
  late String _selectedTag;
  DateTime? _reminder;
  bool _repeatDaily = false;
  bool _highlight = false;
  String? _imagePath;
  String? _errorText;

  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.initialTodo?.title ?? '',
    );
    _selectedTag = widget.initialTodo?.tag ?? '일반';
    _reminder = widget.initialTodo?.reminder;
    _repeatDaily = widget.initialTodo?.repeatDaily ?? false;
    _highlight = widget.initialTodo?.isHighlighted ?? false;
    _imagePath = widget.initialTodo?.imagePath;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
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
              : TimeOfDay.now(),
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

  void _showReminderAlert() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('알림'),
          content: const Text('매일 반복을 사용하려면 먼저 알림 시간을 설정해주세요.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
  }

  void _preSubmit() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _errorText = '메모를 입력해주세요');
      return;
    }
    if (_repeatDaily && _reminder == null) {
      setState(() => _errorText = '매일 반복을 사용하려면 알림 시간을 설정해주세요');
      return;
    }
    widget.onSubmit(
      title,
      _selectedTag,
      _reminder,
      _repeatDaily,
      _highlight,
      _imagePath,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.suggestions.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                widget.suggestions.map((suggestion) {
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
        ],
        TextField(
          controller: _titleController,
          autofocus: true,
          maxLines: 3,
          textInputAction: TextInputAction.newline,
          onChanged: (_) {
            if (_errorText != null) setState(() => _errorText = null);
            setState(() {});
          },
          decoration: InputDecoration(
            labelText: '메모 내용',
            hintText: '할 일, 서점 방문, 장보기',
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.6,
            ),
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
        if (widget.showAd) const MyBannerAdWidget(),
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
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined),
                label: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('갤러리에서 선택', maxLines: 1),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.photo_camera_outlined),
                label: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('카메라로 촬영', maxLines: 1),
                ),
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
                      onPressed: () => setState(() => _imagePath = null),
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
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _pickReminder,
                icon: const Icon(Icons.alarm_add_rounded),
                label: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    _reminder == null
                        ? '알림 시간 설정'
                        : '${_reminder!.month}/${_reminder!.day} ${_reminder!.hour.toString().padLeft(2, '0')}:${_reminder!.minute.toString().padLeft(2, '0')}',
                    maxLines: 1,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: () {
                  if (!_repeatDaily && _reminder == null) {
                    _showReminderAlert();
                  } else {
                    setState(() => _repeatDaily = !_repeatDaily);
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Text('매일 반복'),
                    const SizedBox(width: 4),
                    Switch(
                      value: _repeatDaily,
                      onChanged: (value) {
                        if (value && _reminder == null) {
                          _showReminderAlert();
                        } else {
                          setState(() => _repeatDaily = value);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => setState(() => _highlight = !_highlight),
          borderRadius: BorderRadius.circular(12),
          child: Row(
            children: [
              const Expanded(child: Text('중요 메모로 지정')),
              Switch(
                value: _highlight,
                onChanged: (value) => setState(() => _highlight = value),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _preSubmit,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            backgroundColor: const Color(0xFF4C6EF5),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          icon: Icon(widget.submitIcon),
          label: Text(
            widget.submitLabel,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
