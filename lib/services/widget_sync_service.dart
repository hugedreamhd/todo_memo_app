import 'package:home_widget/home_widget.dart';
import 'package:baromemo/models/todo_item.dart';

class WidgetSyncService {
  static const String androidWidgetName = 'QuickAddWidget';

  Future<void> updateWidgetData(List<TodoItem> allVisibleTodos) async {
    // 스마트 큐: 위젯 고정에 체크된 미완료 상태인 메모 3개
    final widgetMemos =
        allVisibleTodos
            .where((t) => t.showOnWidget && !t.isCompleted)
            .take(3)
            .toList();

    // 위젯에 보여줄 개수 저장
    await HomeWidget.saveWidgetData<int>(
      'widget_memo_count',
      widgetMemos.length,
    );

    // 기존 데이터 초기화 (최대 3개)
    for (int i = 0; i < 3; i++) {
      await HomeWidget.saveWidgetData<String>('widget_memo_${i}_id', null);
      await HomeWidget.saveWidgetData<String>('widget_memo_${i}_title', null);
      await HomeWidget.saveWidgetData<bool>('widget_memo_${i}_completed', null);
      await HomeWidget.saveWidgetData<bool>('widget_memo_${i}_important', null);
      await HomeWidget.saveWidgetData<bool>(
        'widget_memo_${i}_highlighted',
        null,
      );
    }

    // 새 데이터 저장
    for (int i = 0; i < widgetMemos.length; i++) {
      final memo = widgetMemos[i];
      await HomeWidget.saveWidgetData<String>('widget_memo_${i}_id', memo.id);
      await HomeWidget.saveWidgetData<String>(
        'widget_memo_${i}_title',
        memo.title,
      );
      await HomeWidget.saveWidgetData<bool>(
        'widget_memo_${i}_completed',
        memo.isCompleted,
      );
      await HomeWidget.saveWidgetData<bool>(
        'widget_memo_${i}_important',
        memo.isHighlighted,
      );
      // 중요 메모에서 온 경우 위젯에 표시할 별도 플래그
      await HomeWidget.saveWidgetData<bool>(
        'widget_memo_${i}_highlighted',
        memo.isHighlighted,
      );
    }

    // 위젯 갱신 요청
    await HomeWidget.updateWidget(androidName: androidWidgetName);
  }
}
