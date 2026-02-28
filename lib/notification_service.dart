import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static const int _dailyReminderNotificationId = 1;
  static String? _lastDailyReminderSignature;

  static Future<void> initialize() async {
    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    final iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      onDidReceiveLocalNotification: (id, title, body, payload) async {},
    );

    final initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) async {
        _handleNotificationTap(response.payload);
      },
    );

    await _requestNotificationPermissions();
  }

  static void _handleNotificationTap(String? payload) {
    if (payload != null) {
      print('Notification tapped with payload: $payload');
    }
  }

  static Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
    int id = 0,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'financial_tracker_channel',
      'Financial Tracker Notifications',
      channelDescription: 'Notifications for financial tracking app',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(id, title, body, details, payload: payload);
  }

  static Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
    required String title,
    required String body,
    int id = _dailyReminderNotificationId,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      'daily_reminder_channel',
      'Daily Reminders',
      channelDescription: 'Daily reminder to log transactions',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> syncDailyTransactionReminder({
    required bool enabled,
    required int hour,
    required int minute,
    required bool hasLoggedTransactionToday,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    final signature =
        '$enabled-$hour-$minute-$hasLoggedTransactionToday-${now.year}-${now.month}-${now.day}';
    if (_lastDailyReminderSignature == signature) {
      return;
    }
    _lastDailyReminderSignature = signature;

    await cancelNotification(_dailyReminderNotificationId);
    if (!enabled) return;

    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    final selectedTimePassed = !scheduledDate.isAfter(now);
    if (hasLoggedTransactionToday || selectedTimePassed) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      'daily_reminder_channel',
      'Daily Reminders',
      channelDescription: 'Daily reminder to log transactions',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      _dailyReminderNotificationId,
      'Daily Transaction Reminder',
      'You have not logged a transaction today. Add one now.',
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  static Future<void> showBudgetAlert({
    required String category,
    required double spent,
    required double budget,
  }) async {
    final percentage = (spent / budget * 100).toStringAsFixed(0);

    await showNotification(
      title: '?? Budget Alert',
      body: 'You\'ve spent $percentage% of your $category budget',
      payload: 'budget_alert_$category',
      id: category.hashCode,
    );
  }

  static Future<void> showTransactionConfirmation({
    required String type,
    required double amount,
    required String category,
  }) async {
    final emoji = type == 'income' ? '??' : '??';
    final action = type == 'income' ? 'received' : 'spent';

    await showNotification(
      title: '$emoji Transaction Recorded',
      body: 'You $action ?${amount.toStringAsFixed(2)} on $category',
      payload: 'transaction_$type',
      id: DateTime.now().millisecondsSinceEpoch % 100000,
    );
  }

  static Future<void> _requestNotificationPermissions() async {
    if (!kIsWeb && Platform.isAndroid) {
      await Permission.notification.request();
    }

    final iosPlugin = _notifications
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    final macPlugin = _notifications
        .resolvePlatformSpecificImplementation<MacOSFlutterLocalNotificationsPlugin>();
    await iosPlugin?.requestPermissions(alert: true, badge: true, sound: true);
    await macPlugin?.requestPermissions(alert: true, badge: true, sound: true);
  }
}
