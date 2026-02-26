import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:todolist/models/todo_item.dart';
import 'package:todolist/services/notification_service_interface.dart';

class LocalNotificationService implements NotificationServiceInterface {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  @override
  Future<void> initialize() async {
    // 1. 타임존 데이터 초기화
    tz.initializeTimeZones();

    // 2. ★ 핵심: 기기의 실제 타임존을 timezone 패키지에 설정
    // DateTime.now().timeZoneName 으로 시스템 타임존 이름(예: "Asia/Seoul")을 가져옴
    // Android/iOS 모두에서 정확한 로컬 타임존을 설정하기 위해 필요
    final String timeZoneName = _getLocalTimeZoneName();
    try {
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (_) {
      // 타임존 이름 파싱 실패 시 UTC 오프셋으로 fallback
      _setLocalByOffset(DateTime.now().timeZoneOffset);
    }

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(initSettings);

    // 3. Android 13+ 알림 권한 요청
    final androidPlugin =
        _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.requestExactAlarmsPermission();
  }

  /// 시스템 타임존 이름 반환.
  /// Android는 TZ 환경변수 또는 /etc/timezone 파일로 읽음.
  String _getLocalTimeZoneName() {
    // Platform.localeName은 로케일이고 타임존이 아님.
    // dart:io DateTime의 timeZoneName이 가장 신뢰할 수 있음.
    // 예: "KST" → 이를 기반으로 IANA 이름(Asia/Seoul)으로 매핑
    final abbreviation = DateTime.now().timeZoneName;
    final offset = DateTime.now().timeZoneOffset;
    return _ianaFromAbbreviation(abbreviation, offset);
  }

  /// 약어(KST, JST, IST 등)와 오프셋으로 IANA 타임존 이름 매핑
  String _ianaFromAbbreviation(String abbreviation, Duration offset) {
    final totalMinutes = offset.inMinutes;
    // 오프셋 기반 매핑 (더 신뢰할 수 있음)
    const offsetToIana = <int, String>{
      -720: 'Pacific/Auckland', // UTC-12
      -660: 'Pacific/Apia', // UTC-11
      -600: 'Pacific/Honolulu', // UTC-10
      -540: 'America/Anchorage', // UTC-9
      -480: 'America/Los_Angeles', // UTC-8
      -420: 'America/Denver', // UTC-7
      -360: 'America/Chicago', // UTC-6
      -300: 'America/New_York', // UTC-5
      -240: 'America/Caracas', // UTC-4
      -180: 'America/Sao_Paulo', // UTC-3
      -120: 'Atlantic/South_Georgia', // UTC-2
      -60: 'Atlantic/Azores', // UTC-1
      0: 'Europe/London', // UTC+0
      60: 'Europe/Paris', // UTC+1
      120: 'Europe/Helsinki', // UTC+2
      180: 'Asia/Riyadh', // UTC+3
      240: 'Asia/Dubai', // UTC+4
      270: 'Asia/Kabul', // UTC+4:30
      300: 'Asia/Karachi', // UTC+5
      330: 'Asia/Kolkata', // UTC+5:30
      360: 'Asia/Dhaka', // UTC+6
      420: 'Asia/Bangkok', // UTC+7
      480: 'Asia/Shanghai', // UTC+8
      540: 'Asia/Seoul', // UTC+9 ← 한국
      570: 'Australia/Darwin', // UTC+9:30
      600: 'Australia/Sydney', // UTC+10
      660: 'Pacific/Noumea', // UTC+11
      720: 'Pacific/Auckland', // UTC+12
    };
    return offsetToIana[totalMinutes] ?? 'UTC';
  }

  /// UTC 오프셋으로 timezone 위치 설정 (fallback)
  void _setLocalByOffset(Duration offset) {
    final locations = tz.timeZoneDatabase.locations;
    for (final loc in locations.values) {
      if (loc.zones.isNotEmpty && loc.zones.last.offset == offset.inSeconds) {
        tz.setLocalLocation(loc);
        return;
      }
    }
  }

  /// todo.id 의 hashCode를 알림 ID로 사용 (Int 범위 보장)
  int _notifId(String todoId) => todoId.hashCode.abs() % 0x7FFFFFFF;

  AndroidNotificationDetails get _androidDetails =>
      const AndroidNotificationDetails(
        'todo_reminder_channel',
        '할 일 알림',
        channelDescription: '설정한 시각에 할 일을 알려드립니다.',
        importance: Importance.max,
        priority: Priority.high,
      );

  DarwinNotificationDetails get _iosDetails => const DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );

  NotificationDetails get _notifDetails =>
      NotificationDetails(android: _androidDetails, iOS: _iosDetails);

  @override
  Future<void> scheduleOrUpdate(TodoItem todo) async {
    if (todo.reminder == null) {
      await cancel(todo.id);
      return;
    }

    final id = _notifId(todo.id);
    final reminderTime = todo.reminder!;

    // 기존 알림 먼저 취소 (갱신 시 중복 방지)
    await _plugin.cancel(id);

    if (todo.repeatDaily) {
      // 매일 반복: DateTimeComponents.time 으로 매일 동일 시각에 발동
      await _plugin.zonedSchedule(
        id,
        '📌 ${todo.title}',
        '오늘의 할 일을 확인하세요!',
        _nextInstanceOfTime(reminderTime.hour, reminderTime.minute),
        _notifDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } else {
      // 1회 지정 시각 알림
      final scheduledTime = tz.TZDateTime.from(reminderTime, tz.local);

      if (scheduledTime.isBefore(tz.TZDateTime.now(tz.local))) {
        return;
      }

      await _plugin.zonedSchedule(
        id,
        '📌 ${todo.title}',
        '설정한 알림 시각이 되었습니다.',
        scheduledTime,
        _notifDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  @override
  Future<void> cancel(String todoId) async {
    await _plugin.cancel(_notifId(todoId));
  }

  @override
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  /// 오늘(또는 내일) [hour]:[minute]:00 에 해당하는 TZDateTime 반환
  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
      0, // second 명시적 0
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
