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

  void _showSavedMemoSheet() {
    final rootContext = context;
    showModalBottomSheet(
      context: rootContext,
      isScrollControlled: true,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        return FractionallySizedBox(
          heightFactor: 0.65,
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
                          color: const Color(0xFF4C6EF5).withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.bookmarks_outlined,
                          color: Color(0xFF4C6EF5),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '저장된 메모',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '현재 저장된 모든 메모 목록이에요.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child:
                        todoList.isEmpty
                            ? Center(
                              child: Text(
                                '아직 저장된 메모가 없어요.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.outline,
                                ),
                              ),
                            )
                            : ListView.separated(
                              itemCount: todoList.length,
                              separatorBuilder:
                                  (_, __) => const Divider(height: 20),
                              itemBuilder: (context, index) {
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.push_pin_outlined,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        todoList[index],
                                        style: theme.textTheme.bodyLarge,
                                      ),
                                    ),
                                  ],
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
  }

  void _showTaskActionSheet(int index) {
    final rootContext = context;
    showModalBottomSheet(
      context: rootContext,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
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
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4C6EF5).withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.note_alt_outlined,
                        color: Color(0xFF4C6EF5),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '메모 관리',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '수정하거나 삭제할 작업을 선택하세요.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    showModalBottomSheet(
                      context: rootContext,
                      builder: (context) {
                        return Padding(
                          padding: MediaQuery.of(context).viewInsets,
                          child: UpdateTask(
                            currentText: todoList[index],
                            onUpdate: (String todoText) {
                              updateLocalData(
                                index: index,
                                updateText: todoText,
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    backgroundColor: const Color(0xFF4C6EF5),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  icon: const Icon(Icons.edit_rounded),
                  label: const Text(
                    '메모 수정',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
                          content: const Text('정말로 이 메모를 삭제할까요?'),
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
                                backgroundColor: const Color(0xFFFF5C5C),
                              ),
                              child: const Text('삭제'),
                            ),
                          ],
                        );
                      },
                    );

                    if (confirm == true) {
                      final removedItem = todoList[index];
                      setState(() {
                        todoList.removeAt(index);
                      });
                      writeLocalData();
                      Navigator.pop(sheetContext);
                      ScaffoldMessenger.of(rootContext).showSnackBar(
                        SnackBar(content: Text('$removedItem 삭제됨')),
                      );
                    }
                  },
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    backgroundColor: const Color(0xFFFF5C5C),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  icon: const Icon(Icons.delete_forever_rounded),
                  label: const Text(
                    '메모 삭제',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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
                      onTap: () => _showTaskActionSheet(index),
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
                child: CreateTask(createTodo: createTodo),
              );
            },
          );
        },
        backgroundColor: Colors.black,
        child: Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: FilledButton.tonalIcon(
            onPressed: _showSavedMemoSheet,
            icon: const Icon(Icons.bookmarks_outlined),
            label: const Text(
              '저장된 메모 보기',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
