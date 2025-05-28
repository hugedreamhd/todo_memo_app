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

  _UpdateTaskState() : _controller = TextEditingController();

  @override
  void initState() {
    _controller.text = widget.currentText;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Text('메모 수정'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: TextField(
              controller: _controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: '메모를 수정해주세요',
                hintStyle: TextStyle(color: Colors.grey),
              ),
            ),
          ),
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              if (_controller.text.isEmpty) {
                showDialog(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        title: Text('알림', textAlign: TextAlign.center),
                        actionsAlignment: MainAxisAlignment.center,
                        content: Text(
                          '메모를 입력해주세요',
                          textAlign: TextAlign.center,
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Text('확인'),
                          ),
                        ],
                      ),
                );
              } else {
                widget.onUpdate(_controller.text);
                Navigator.pop(context);
              }
            },
            child: Text('수정'),
          ),
        ],
      ),
    );
  }
}
