import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Initialize notification service
  Future<void> init() async {
    if (_isInitialized) return;

    // Android settings
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS settings
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        debugPrint('Notification clicked: ${response.payload}');
      },
    );

    await _createNotificationChannel();

    _isInitialized = true;
    debugPrint('✅ NotificationService initialized');
  }



  /// Create Android notification channel
  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'speaker_cleaner_daily',
      'Daily Reminders',
      description: 'Daily reminder notifications',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    debugPrint('-> Notification channel created');
  }

  /// Notification details configuration
  NotificationDetails _notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'speaker_cleaner_daily',
        'Daily Reminders',
        channelDescription: 'Daily reminder notifications',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  /// Request notification permissions
  Future<bool> requestPermissions() async {
    debugPrint('-> Requesting notification permissions...');

    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    if (androidPlugin != null) {
      final bool? granted = await androidPlugin
          .requestNotificationsPermission();
      debugPrint('Android notification permission: $granted');

      final bool? exactAlarm = await androidPlugin
          .requestExactAlarmsPermission();
      debugPrint('Exact alarm permission: $exactAlarm');
    }

    return true;
  }

  /// Schedule daily notification (triggered on app login)
  /// This will send notifications daily at approximately the same time the user logs in
  Future<void> scheduleDailyNotification({
    int id = 0,
    String? title,
    String? body,
  }) async {
    debugPrint('-> Scheduling daily notification...');

    // Cancel existing notifications first
    await cancelAllNotifications();

    // Schedule daily notification
    await flutterLocalNotificationsPlugin.periodicallyShow(
      id,
      title ?? 'Speaker Cleaner 🔊',
      body ?? 'Keep your speakers clean for the best sound quality!',
      RepeatInterval.daily,
      _notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );

    debugPrint('-> Daily notification scheduled successfully');
  }

  // /// Show instant test notification
  // Future<void> showTestNotification() async {
  //   debugPrint('-> Showing test notification...');

  //   await flutterLocalNotificationsPlugin.show(
  //     999,
  //     'Test Notification ->',
  //     'If you see this, notifications are working!',
  //     _notificationDetails(),
  //   );

  //   debugPrint('-> Test notification sent');
  // }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
    debugPrint('-> All notifications cancelled');
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    if (androidPlugin != null) {
      final bool? enabled = await androidPlugin.areNotificationsEnabled();
      return enabled ?? false;
    }
    return true;
  }

  /// Get pending notifications (for debugging)
  Future<void> checkPendingNotifications() async {
    final List<PendingNotificationRequest> pendingNotifications =
        await flutterLocalNotificationsPlugin.pendingNotificationRequests();

    debugPrint('-> Pending notifications: ${pendingNotifications.length}');
    for (var notification in pendingNotifications) {
      debugPrint('  - ID: ${notification.id}, Title: ${notification.title}');
    }
  }
}
