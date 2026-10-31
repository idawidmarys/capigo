import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/habit_item.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;

  static const String workoutChannelId = 'capigo_workout_tracking';
  static const String workoutChannelName = 'CapiGo - Rejestracja treningu';
  static const int workoutNotificationId = 999;

  static const String habitsChannelId = 'capigo_habits_reminders';
  static const String habitsChannelName = 'CapiGo - Przypomnienia o spacerach';

  static Future<void> initialize({Function(String action)? onNotificationAction}) async {
    if (kIsWeb) {
      _isInitialized = true;
      return;
    }
    if (_isInitialized) return;

    try {
      try {
        tz.initializeTimeZones();
      } catch (_) {}

      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notificationsPlugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          final actionId = response.actionId;
          if (actionId != null && onNotificationAction != null) {
            onNotificationAction(actionId);
          }
        },
      );

      _isInitialized = true;
    } catch (e) {
      debugPrint('NotificationService init error: $e');
    }
  }

  static Future<bool> requestPermissions() async {
    try {
      if (kIsWeb) return false;

      final androidImpl = _notificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        final granted = await androidImpl.requestNotificationsPermission();
        return granted ?? false;
      }

      final iosImpl = _notificationsPlugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (iosImpl != null) {
        final granted = await iosImpl.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }
    } catch (_) {}
    return true;
  }

  // Show or update the live workout notification on lock screen
  static Future<void> updateWorkoutNotification({
    required String duration,
    required double distanceKm,
    required int steps,
    required bool isPaused,
  }) async {
    if (kIsWeb) return;
    if (!_isInitialized) await initialize();

    final String title = isPaused ? 'CapiGo - Trening wstrzymany ⏸️' : 'CapiGo - Spacer w toku 🦫';
    final String body = '${distanceKm.toStringAsFixed(2)} km  •  $duration  •  $steps kroków';

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      workoutChannelId,
      workoutChannelName,
      channelDescription: 'Powiadomienie na zablokowanym ekranie podczas trwania spaceru',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: !isPaused,
      autoCancel: false,
      showWhen: false,
      visibility: NotificationVisibility.public,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          isPaused ? 'resume_action' : 'pause_action',
          isPaused ? 'Wznów' : 'Pauza',
          showsUserInterface: true,
        ),
        const AndroidNotificationAction(
          'stop_action',
          'Zakończ',
          showsUserInterface: true,
          cancelNotification: false,
        ),
      ],
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: false,
      presentBadge: false,
      presentSound: false,
      interruptionLevel: InterruptionLevel.passive,
    );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      id: workoutNotificationId,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
    );
  }

  static Future<void> cancelWorkoutNotification() async {
    if (kIsWeb) return;
    try {
      await _notificationsPlugin.cancel(id: workoutNotificationId);
    } catch (_) {}
  }

  // Schedule daily habit notifications ("Dlaczego warto wyjść na spacer")
  static Future<void> scheduleHabitNotifications(
    List<HabitItem> habits,
    String lang,
  ) async {
    if (kIsWeb) return;
    if (!_isInitialized) await initialize();

    // Cancel all previously scheduled habit notifications (IDs 100 to 150)
    for (int i = 0; i < 50; i++) {
      try {
        await _notificationsPlugin.cancel(id: 100 + i);
      } catch (_) {}
    }

    final now = DateTime.now();

    for (int i = 0; i < habits.length; i++) {
      final habit = habits[i];
      if (!habit.isEnabled || habit.triggerTime == null) continue;

      final hour = habit.triggerTime!.hour;
      final minute = habit.triggerTime!.minute;

      var scheduledDate = DateTime(
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      // If already passed today, schedule for tomorrow
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      final tzDateTime = tz.TZDateTime.from(scheduledDate, tz.local);

      final androidDetails = AndroidNotificationDetails(
        habitsChannelId,
        habitsChannelName,
        channelDescription: 'Codzienne motywujące powiadomienia o spacerze',
        importance: Importance.high,
        priority: Priority.high,
        visibility: NotificationVisibility.public,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      try {
        await _notificationsPlugin.zonedSchedule(
          id: 100 + i,
          title: habit.getLocalizedTitle(lang),
          body: habit.getLocalizedPrompt(lang),
          scheduledDate: tzDateTime,
          notificationDetails: notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      } catch (_) {}
    }
  }
}
