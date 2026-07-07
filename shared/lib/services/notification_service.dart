import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../utils/wtf_logger.dart';

/// Local notifications (spec §15 stretch): heads-up alerts for new chat
/// messages / call approvals, plus a scheduled 10-min-before-call reminder.
/// Android only, driven by the app's Firestore listeners — no server.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;

  static const _channel = AndroidNotificationChannel(
    'wtf_default',
    'WTF Notifications',
    description: 'Chat messages, call approvals and reminders',
    importance: Importance.high,
  );

  Future<void> init() async {
    if (_ready) return;
    tz.initializeTimeZones();

    const androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(
      const InitializationSettings(android: androidInit),
    );

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(_channel);
    // Android 13+ runtime permission.
    await android?.requestNotificationsPermission();

    _ready = true;
    WtfLog.d(LogTag.auth, 'notifications initialised');
  }

  AndroidNotificationDetails get _details => AndroidNotificationDetails(
        _channel.id,
        _channel.name,
        channelDescription: _channel.description,
        importance: Importance.high,
        priority: Priority.high,
      );

  /// Immediate heads-up notification.
  Future<void> show({
    required int id,
    required String title,
    required String body,
  }) async {
    if (!_ready) await init();
    await _plugin.show(
        id, title, body, NotificationDetails(android: _details));
    WtfLog.d(LogTag.auth, 'notification: $title');
  }

  /// Schedule a reminder at [when] (used for the 10-min-before-call nudge).
  /// Silently skips if [when] is already in the past.
  Future<void> scheduleAt({
    required int id,
    required String title,
    required String body,
    required DateTime when,
  }) async {
    if (!_ready) await init();
    final at = tz.TZDateTime.from(when, tz.local);
    if (at.isBefore(tz.TZDateTime.now(tz.local))) return;
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      at,
      NotificationDetails(android: _details),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
    WtfLog.d(LogTag.schedule, 'reminder scheduled for $when');
  }

  Future<void> cancel(int id) => _plugin.cancel(id);
}
