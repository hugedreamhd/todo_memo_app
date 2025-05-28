import 'package:flutter/material.dart';

class CreateTask extends StatefulWidget {
  final void Function({required String todoText}) createTodo;

  const CreateTask({super.key, required this.createTodo});

  @override
  State<CreateTask> createState() => _CreateTaskState();
}

class _CreateTaskState extends State<CreateTask> {
  var todoText = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Text('메모 추가'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: TextField(
              autofocus: true,
              onSubmitted: (value) {
                if (todoText.text.isEmpty) {
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
                  // ScaffoldMessenger.of(context).showSnackBar(
                  //   SnackBar(
                  //     content: Text(
                  //       '메모를 입력해주세요',
                  //       textAlign: TextAlign.center,
                  //       style: TextStyle(color: Colors.red),
                  //     ),
                  //     duration: Duration(seconds: 1),
                  //     behavior: SnackBarBehavior.floating,
                  //     margin: EdgeInsets.only(bottom: 250, left: 10, right: 10),
                  //     backgroundColor: Colors.white,
                  //     elevation: 6,
                  //   ),
                  // );
                } else {
                  widget.createTodo(todoText: todoText.text);
                  todoText.clear();
                }
              },
              controller: todoText,
              decoration: InputDecoration(
                hintText: '메모를 넣어주세요',
                hintStyle: TextStyle(color: Colors.grey),
              ),
            ),
          ),
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              if (todoText.text.isEmpty) {
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
                // ScaffoldMessenger.of(context).showSnackBar(
                //   SnackBar(
                //     content: Text(
                //       '메모를 입력해주세요',
                //       textAlign: TextAlign.center,
                //       style: TextStyle(color: Colors.white),
                //     ),
                //     duration: Duration(seconds: 1),
                //     behavior: SnackBarBehavior.floating,
                //     margin: EdgeInsets.only(bottom: 250, left: 10, right: 10),
                //   ),
                // );
              } else {
                widget.createTodo(todoText: todoText.text);
                todoText.clear();
              }
            },
            child: Text('추가'),
          ),
        ],
      ),
    );
  }
}
