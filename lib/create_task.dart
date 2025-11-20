import 'package:flutter/material.dart';

class CreateTask extends StatefulWidget {
  final void Function({required String todoText}) createTodo;

  const CreateTask({super.key, required this.createTodo});

  @override
  State<CreateTask> createState() => _CreateTaskState();
}

class _CreateTaskState extends State<CreateTask> {
  var todoText = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    todoText.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    void submit() {
      final text = todoText.text.trim();
      if (text.isEmpty) {
        setState(() {
          _errorText = '메모를 입력해주세요';
        });
        return;
      }
      widget.createTodo(todoText: text);
      setState(() {
        _errorText = null;
      });
      todoText.clear();
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(),
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
            const SizedBox(height: 24),
            TextField(
              controller: todoText,
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
                hintText: '예) 헬스장 등록, 서점 방문, 장보기',
                filled: true,
                fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.6),
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
              icon: const Icon(Icons.check_rounded),
              label: const Text(
                '메모 저장',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
