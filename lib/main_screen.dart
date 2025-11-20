import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todolist/create_task.dart';
import 'package:todolist/update_task.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  List<String> todoList = [];
  int _currentIndex = 1;

  @override
  void initState() {
    readLocalData();
    super.initState();
  }

  void createTodo({required String todoText}) {
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
      appBar: AppBar(title: Text('오늘의 할일'), centerTitle: true),
      body:
          (todoList.isEmpty)
              ? Center(
                child: Text('표시할 메모가 없어요:)', style: TextStyle(fontSize: 20)),
              )
              : ListView.builder(
                itemCount: todoList.length,
                itemBuilder: (context, index) {
                  return Dismissible(
                    key: ValueKey(todoList[index]),
                    // direction: DismissDirection.startToEnd,
                    // 오른쪽 스와이프 (삭제) 배경
                    background: Container(
                      color: Colors.red,
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 20.0),
                            child: Icon(Icons.delete),
                          ),
                        ],
                      ),
                    ),
                    // 왼쪽 스와이프 (삭제) 배경
                    secondaryBackground: Container(
                      color: Colors.blue,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20.0),
                      child: Icon(Icons.save),
                    ),
                    dismissThresholds: const {
                      // 오른쪽으로 50% 드래그
                      DismissDirection.startToEnd: 0.5,
                      // 왼쪽으로 50% 드래그
                      DismissDirection.endToStart: 0.5,
                    },
                    //보류 로직
                    confirmDismiss: (DismissDirection direction) async {
                      if (direction == DismissDirection.startToEnd) {
                        return await showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('삭제 확인'),
                              content: const Text('정말로 이 항목을 삭제하시겠습니까?'),
                              actions: <Widget>[
                                TextButton(
                                  onPressed:
                                      () => Navigator.of(context).pop(false),
                                  child: const Text('취소'),
                                ),
                                TextButton(
                                  onPressed:
                                      () => Navigator.of(context).pop(true),
                                  child: const Text('삭제'),
                                ),
                              ],
                            );
                          },
                        );
                      } else {
                        //여기에 보류 관련 로직 추가
                        print('${todoList[index]}을(를) 보류 처리했습니다');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${todoList[index]} 보류됨')),
                        );
                        //false를 반환하여 아이템이 사라지지 않고 제자리로 돌아가게 함
                        return false;
                      }
                    },
                    //삭제 로직
                    onDismissed: (direction) {
                      if (direction == DismissDirection.startToEnd) {
                        // 삭제될 아이템을 미리 변수에 저장
                        final removeItem = todoList[index];
                        setState(() {
                          todoList.removeAt(index);
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          //삭제될 변수만 따로 삭제되게 하는 코드
                          SnackBar(content: Text('$removeItem 삭제됨')),
                        );
                        writeLocalData();
                      }
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
                child: Container(
                  height: 250,
                  child: CreateTask(createTodo: createTodo),
                ),
              );
            },
          );
        },
        backgroundColor: Colors.black,
        child: Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border_outlined),
            label: 'Saved',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pause_circle_outline),
            label: 'Paused',
          ),
        ],
      ),
    );
  }
}
