import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// 本地通知服务：负责待办提醒的调度与取消。
class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    try {
      tz_data.initializeTimeZones();
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Shanghai'));
      } catch (_) {
        // 时区数据异常时使用默认本地时区
      }
      const androidSettings =
          AndroidInitializationSettings('mipmap_ic_launcher');
      await _plugin.initialize(
        const InitializationSettings(android: androidSettings),
      );
      // Android 13+ 需要运行时申请通知权限
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      _initialized = true;
    } catch (_) {
      // 初始化失败不影响应用主体功能，仅提醒不可用
    }
  }

  /// 预约一条待办提醒；时间已过则忽略。
  static Future<void> scheduleTodoReminder(
    int id,
    String title,
    DateTime due,
  ) async {
    if (!_initialized || due.isBefore(DateTime.now())) return;
    try {
      await _plugin.zonedSchedule(
      id,
      '待办提醒',
      '时间到了：$title',
      tz.TZDateTime.from(due, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'todo_reminder',
          '待办提醒',
          channelDescription: '待办事项到期提醒',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {
      // 调度失败静默处理，不影响用户操作
    }
  }

  static Future<void> cancel(int id) async {
    try {
      await _plugin.cancel(id);
    } catch (_) {}
  }
}
