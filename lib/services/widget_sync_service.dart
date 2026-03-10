import 'package:home_widget/home_widget.dart';
import 'package:baromemo/models/todo_item.dart';

class WidgetSyncService {
  static const String androidWidgetName = 'QuickAddWidget';

  Future<void> updateWidgetData(List<TodoItem> allVisibleTodos) async {
    // 위젯 고정된 메모 3개를 완료 여부와 함께 그대로 동기화합니다.
    final widgetMemos =
        allVisibleTodos
            .where((t) => t.showOnWidget)
            .take(3)
            .toList();

    // 위젯에 보여줄 개수 저장
    await HomeWidget.saveWidgetData<int>(
      'widget_memo_count',
      widgetMemos.length,
    );

    // 단일 패스로 데이터 덮어쓰기 (중간 빈 상태 방지)
    for (int i = 0; i < 3; i++) {
      if (i < widgetMemos.length) {
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
        await HomeWidget.saveWidgetData<bool>(
          'widget_memo_${i}_highlighted',
          memo.isHighlighted,
        );
      } else {
        await HomeWidget.saveWidgetData<String>('widget_memo_${i}_id', null);
        await HomeWidget.saveWidgetData<String>('widget_memo_${i}_title', null);
        await HomeWidget.saveWidgetData<bool>(
          'widget_memo_${i}_completed',
          null,
        );
        await HomeWidget.saveWidgetData<bool>(
          'widget_memo_${i}_important',
          null,
        );
        await HomeWidget.saveWidgetData<bool>(
          'widget_memo_${i}_highlighted',
          null,
        );
      }
    }

    // 위젯 갱신 요청
    await HomeWidget.updateWidget(androidName: androidWidgetName);
  }
}
