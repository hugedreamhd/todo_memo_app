import 'package:home_widget/home_widget.dart';
import 'package:baromemo/models/todo_item.dart';

class WidgetSyncService {
  static const String androidWidgetName =
      'com.belyself.baromemo.QuickAddWidget'; // 전체 경로 사용

  Future<void> updateWidgetData(List<TodoItem> allVisibleTodos) async {
    // 1. showOnWidget이 true인 메모 최대 3개 추출
    final widgetMemos =
        allVisibleTodos.where((t) => t.showOnWidget).take(3).toList();

    // 2. 위젯에 보여줄 개수 저장
    await HomeWidget.saveWidgetData<int>(
      'widget_memo_count',
      widgetMemos.length,
    );

    // 3. 기존에 저장된 데이터 지우기 (최대 3개)
    for (int i = 0; i < 3; i++) {
      await HomeWidget.saveWidgetData<String>('widget_memo_${i}_id', null);
      await HomeWidget.saveWidgetData<String>('widget_memo_${i}_title', null);
      await HomeWidget.saveWidgetData<bool>('widget_memo_${i}_completed', null);
      await HomeWidget.saveWidgetData<bool>('widget_memo_${i}_important', null);
    }

    // 4. 새로운 데이터 저장
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
    }

    // 5. 위젯 업데이트 요청 (안드로이드)
    await HomeWidget.updateWidget(androidName: androidWidgetName);
  }
}
