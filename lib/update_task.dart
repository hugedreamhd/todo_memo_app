import 'package:flutter/material.dart';

class UpdateTask extends StatefulWidget {
  final String currentText;
  final void Function(String) onUpdate;

  const UpdateTask({
    super.key,
    required this.currentText,
    required this.onUpdate,
  });

  @override
  State<UpdateTask> createState() => _UpdateTaskState();
}

class _UpdateTaskState extends State<UpdateTask> {
  final TextEditingController _controller;
  String? _errorText;

  _UpdateTaskState() : _controller = TextEditingController();

  @override
  void initState() {
    _controller.text = widget.currentText;
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    void submit() {
      final text = _controller.text.trim();
      if (text.isEmpty) {
        setState(() {
          _errorText = '메모를 입력해주세요';
        });
        return;
      }
      widget.onUpdate(text);
      Navigator.pop(context);
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
              '텍스트를 수정하고 저장을 누르면 바로 반영돼요.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _controller,
              autofocus: true,
              maxLines: 3,
              textInputAction: TextInputAction.newline,
              onSubmitted: (_) => submit(),
              onChanged: (_) {
                if (_errorText != null) {
                  setState(() {
                    _errorText = null;
                  });
                }
              },
              decoration: InputDecoration(
                labelText: '메모 내용',
                hintText: '수정하고 싶은 내용을 입력해주세요',
                filled: true,
                fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.6),
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
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: submit,
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
    );
  }
}
