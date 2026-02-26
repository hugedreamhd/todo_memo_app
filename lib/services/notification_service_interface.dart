import 'package:todolist/models/todo_item.dart';

abstract class NotificationServiceInterface {
  /// 알림 서비스를 초기화하고 권한을 요청합니다.
  Future<void> initialize();

  /// [todo]의 reminder가 있으면 알림을 예약(또는 갱신)합니다.
  /// reminder가 없으면 기존 알림을 취소합니다.
  Future<void> scheduleOrUpdate(TodoItem todo);

  /// [todoId]에 해당하는 알림을 취소합니다.
  Future<void> cancel(String todoId);

  /// 모든 예약된 알림을 취소합니다.
  Future<void> cancelAll();
}
