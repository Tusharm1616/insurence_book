import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings(
          '@mipmap/ic_launcher',
        );

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint('Notification clicked: ${details.payload}');
      },
    );
  }

  Future<void> scheduleDailyReminder() async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, 9, 0);
    
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'daily_reminders',
      'Daily Reminders',
      channelDescription: 'Daily at 9:00 AM for Birthdays and Anniversaries',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _notificationsPlugin.zonedSchedule(
      id: 0,
      title: 'Check Today\'s Reminders',
      body: 'You may have upcoming birthdays or anniversaries to wish today!',
      scheduledDate: scheduledDate,
      notificationDetails: platformDetails,
      androidScheduleMode: AndroidScheduleMode.exact,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Schedule a local notification at 9 AM on a specific follow-up date
  Future<void> scheduleFollowupNotification({
    required int leadId,
    required String leadName,
    required DateTime followupDate,
  }) async {
    // Schedule at 9 AM on the follow-up date
    final scheduledDate = tz.TZDateTime(
      tz.local,
      followupDate.year,
      followupDate.month,
      followupDate.day,
      9, 0, // 9:00 AM
    );

    // Don't schedule if it's in the past
    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) return;

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'lead_followups',
      'Lead Follow-ups',
      channelDescription: 'Notifications for scheduled lead follow-ups',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    // Use lead ID + 1000 offset to avoid conflicts with other notification IDs
    await _notificationsPlugin.zonedSchedule(
      id: leadId + 1000,
      title: 'Follow-up Reminder',
      body: 'Follow-up scheduled with $leadName today.',
      scheduledDate: scheduledDate,
      notificationDetails: platformDetails,
      androidScheduleMode: AndroidScheduleMode.exact,
      payload: 'lead_followup_$leadId',
    );

    debugPrint('Scheduled follow-up notification for $leadName on $scheduledDate');
  }

  /// Cancel a follow-up notification
  Future<void> cancelFollowupNotification(int leadId) async {
    await _notificationsPlugin.cancel(id: leadId + 1000);
  }
}
