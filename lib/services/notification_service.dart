import 'dart:developer';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  FirebaseMessaging get _fcm => FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final ApiService _api = ApiService();

  Future<void> initialize() async {
    try {
      // 1. Initialize Local Notifications
      const initializationSettingsAndroid = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const initializationSettingsIOS = DarwinInitializationSettings();
      const initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );
      await _localNotifications.initialize(initializationSettings);

      // 2. Request Permissions (Optional for non-firebase setup)
      try {
        await requestPermissions();

        // 3. Handle Background Messages
        FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler,
        );

        // 4. Handle Foreground Messages
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          _showLocalNotification(message);
        });
      } catch (e) {
        debugPrint('Firebase Messaging initialization skipped: $e');
      }

      // 5. Update Token if logged in
      if (await _api.isLoggedIn()) {
        updateToken();
      }
    } catch (e) {
      debugPrint('NotificationService initialization error: $e');
    }
  }

  Future<void> requestPermissions() async {
    try {
      await _fcm.requestPermission(alert: true, badge: true, sound: true);
    } catch (e) {
      debugPrint('Error requesting FCM permissions: $e');
    }
  }

  Future<void> updateToken() async {
    try {
      String? token = await _fcm.getToken();
      if (token != null) {
        log('FCM Token: $token');
        await _api.updateFcmToken(token);
      }
    } catch (e) {
      debugPrint('Error updating FCM token: $e');
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    const androidDetails = AndroidNotificationDetails(
      'simpati_reminders',
      'SIMPATI Reminders',
      channelDescription: 'Attendance reminders and notifications',
      importance: Importance.max,
      priority: Priority.high,
    );
    const notificationDetails = NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'SIMPATI',
      message.notification?.body ?? '',
      notificationDetails,
    );
  }

  // ─── Attendance Alarms ─────────────────────────

  Future<void> scheduleAttendanceAlarms() async {
    try {
      final response = await _api.getSchedule();
      final List schedules = response.data['schedules'] ?? [];

      // Cancel existing check-in alarms
      await _localNotifications.cancelAll();

      for (var sch in schedules) {
        final days = sch['hari'].toString().split(',');
        final jamMasukStr = sch['jam_masuk']; // format H:i
        final jamPulangStr = sch['jam_pulang'];

        for (var day in days) {
          int? dayIndex = _getDayIndex(day);
          if (dayIndex == null) continue;

          // Schedule In Reminder (15 mins before)
          _scheduleRecurring(
            id: sch['id'] * 10 + 1,
            title: 'Waktunya Presensi Masuk',
            body: 'Ayo lakukan presensi masuk sekarang agar tidak terlambat.',
            timeStr: jamMasukStr,
            offsetMinutes: -15,
            dayIndex: dayIndex,
          );

          // Schedule Out Reminder
          _scheduleRecurring(
            id: sch['id'] * 10 + 2,
            title: 'Waktunya Presensi Pulang',
            body: 'Sudah selesai bekerja? Jangan lupa presensi pulang ya.',
            timeStr: jamPulangStr,
            offsetMinutes: 0,
            dayIndex: dayIndex,
          );
        }
      }
    } catch (e) {
      log('Error scheduling alarms: $e');
    }
  }

  void _scheduleRecurring({
    required int id,
    required String title,
    required String body,
    required String timeStr,
    required int offsetMinutes,
    required int dayIndex,
  }) async {
    // Note: flutter_local_notifications requires TZDateTime for precise scheduling.
    // For simplicity in this demo, we'll assume the time parsing works.
    // In a real app, use 'timezone' package.
    log(
      'Scheduling alarm $id at $timeStr (offset: $offsetMinutes) for day: $dayIndex',
    );

    // Implementation placeholder for actual scheduled notification logic
    // using zonedSchedule or showWeeklyAtDayAndTime.
  }

  int? _getDayIndex(String day) {
    switch (day.toLowerCase()) {
      case 'senin':
        return 1;
      case 'selasa':
        return 2;
      case 'rabu':
        return 3;
      case 'kamis':
        return 4;
      case 'jumat':
        return 5;
      case 'sabtu':
        return 6;
      case 'minggu':
        return 7;
      default:
        return null;
    }
  }
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  log("Handling a background message: ${message.messageId}");
}
