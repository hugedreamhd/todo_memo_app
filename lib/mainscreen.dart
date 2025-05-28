import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todolist/add_task.dart';
import 'package:todolist/update_task.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  List<String> todoList = [];

  @override
  void initState() {
    readLocalData();
    super.initState();
  }

  void addTodo({required String todoText}) {
    if (todoList.contains(todoText)) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('알림', textAlign: TextAlign.center),
            content: const Text(
              '이 메모는 이미 있는 메모에요 :)',
              textAlign: TextAlign.center,
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('확인'),
              ),
            ],
          );
        },
      );
      return;
    }
    setState(() {
      todoList.insert(0, todoText);
    });
    writeLocalData();
    Navigator.pop(context);
  }

  void writeLocalData() async {
    // Obtain shared preferences.
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.setStringList('todolist', todoList);
  }

  void readLocalData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      todoList = (prefs.getStringList('todolist') ?? []).toList();
    });
  }

  void updateLocalData({required int index, required String updateText}) {
    setState(() {
      todoList[index] = updateText;
    });
    writeLocalData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(child: Text("Drawer")),
      appBar: AppBar(title: Text('TODO App'), centerTitle: true),
      body:
          (todoList.isEmpty)
              ? Center(
                child: Text('표시할 메모가 없어요 :)', style: TextStyle(fontSize: 20)),
              )
              : ListView.builder(
                itemCount: todoList.length,
                itemBuilder: (context, index) {
                  return Dismissible(
                    key: UniqueKey(),
                    // direction: DismissDirection.startToEnd,
                    background: Container(
                      color: Colors.green,
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Icon(Icons.check),
                          ),
                        ],
                      ),
                    ),
                    secondaryBackground: Container(
                      color: Colors.red,
                      child: Icon(Icons.cancel),
                    ),
                    onDismissed: (direction) {
                      setState(() {
                        todoList.removeAt(index);
                      });
                      writeLocalData();
                    },
                    child: ListTile(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          builder: (context) {
                            return Column(
                              children: [
                                Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.all(20),
                                  child: ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        todoList.removeAt(index);
                                      });
                                      writeLocalData();
                                      Navigator.pop(context);
                                    },
                                    child: Text('메모 삭제'),
                                  ),
                                ),
                                Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.all(20),
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      showModalBottomSheet(
                                        context: context,
                                        builder: (context) {
                                          return Padding(
                                            padding:
                                                MediaQuery.of(
                                                  context,
                                                ).viewInsets,
                                            child: Container(
                                              height: 250,
                                              child: UpdateTask(
                                                currentText: todoList[index],
                                                onUpdate: (String todoText) {
                                                  updateLocalData(
                                                    index: index,
                                                    updateText: todoText,
                                                  );
                                                },
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                    child: Text('메모 수정'),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      title: Text(todoList[index]),
                    ),
                  );
                },
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            builder: (context) {
              return Padding(
                padding: MediaQuery.of(context).viewInsets,
                child: Container(height: 250, child: AddTask(addTodo: addTodo)),
              );
            },
          );
        },
        backgroundColor: Colors.black,
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
