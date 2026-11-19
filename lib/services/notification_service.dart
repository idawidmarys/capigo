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
  static const String habitsChannelName = 'CapiGo - Przypomnienia o aktywności';

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

  /// Show or update the live workout notification on the lock screen.
  /// [activityName] – localized activity name (e.g. "Spacer", "Walk").
  /// [lang]         – user language code for localized labels.
  static Future<void> updateWorkoutNotification({
    required String duration,
    required double distanceKm,
    required int steps,
    required bool isPaused,
    String lang = 'pl',
    String activityName = '',
  }) async {
    if (kIsWeb) return;
    if (!_isInitialized) await initialize();

    final String pausedLabel = _localizedLabel(lang, 'paused');
    final String inProgressLabel = _localizedLabel(lang, 'in_progress');
    final String stepsLabel = _localizedLabel(lang, 'steps');

    final String displayName = activityName.isNotEmpty ? activityName : 'CapiGo';
    final String title = isPaused
        ? 'CapiGo - $displayName $pausedLabel ⏸️'
        : 'CapiGo - $displayName $inProgressLabel 🦫';
    final String body =
        '${distanceKm.toStringAsFixed(2)} km  •  $duration  •  $steps $stepsLabel';

    final String resumeLabel = _localizedLabel(lang, 'resume');
    final String pauseLabel = _localizedLabel(lang, 'pause');
    final String stopLabel = _localizedLabel(lang, 'stop');

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      workoutChannelId,
      workoutChannelName,
      channelDescription: 'Powiadomienie na zablokowanym ekranie podczas trwania treningu',
      importance: Importance.low,
      priority: Priority.low,
      // Always ongoing while tracking — dismissed ONLY via cancelWorkoutNotification()
      ongoing: true,
      autoCancel: false,
      showWhen: false,
      visibility: NotificationVisibility.public,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          isPaused ? 'resume_action' : 'pause_action',
          isPaused ? resumeLabel : pauseLabel,
          showsUserInterface: true,
        ),
        AndroidNotificationAction(
          'stop_action',
          stopLabel,
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

  /// Schedule daily habit notifications.
  /// Uses already-localized habit titles/prompts (which are mode-aware via [HabitItem.defaultHabitsForMode]).
  static Future<void> scheduleHabitNotifications(
    List<HabitItem> habits,
    String lang,
  ) async {
    if (kIsWeb) return;
    if (!_isInitialized) await initialize();

    // Cancel all previously scheduled habit notifications (IDs 100..149)
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

      var scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      final tzDateTime = tz.TZDateTime.from(scheduledDate, tz.local);

      final androidDetails = AndroidNotificationDetails(
        habitsChannelId,
        habitsChannelName,
        channelDescription: 'Codzienne motywujące powiadomienia o aktywności',
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

  // Helper: returns a localized short label for notification UI text.
  static String _localizedLabel(String lang, String key) {
    const labels = <String, Map<String, String>>{
      'paused': {'pl': 'wstrzymany', 'en': 'paused', 'de': 'pausiert', 'es': 'en pausa'},
      'in_progress': {'pl': 'w toku', 'en': 'in progress', 'de': 'läuft', 'es': 'en curso'},
      'steps': {'pl': 'kroków', 'en': 'steps', 'de': 'Schritte', 'es': 'pasos'},
      'resume': {'pl': 'Wznów', 'en': 'Resume', 'de': 'Fortsetzen', 'es': 'Reanudar'},
      'pause': {'pl': 'Pauza', 'en': 'Pause', 'de': 'Pause', 'es': 'Pausa'},
      'stop': {'pl': 'Zakończ', 'en': 'Finish', 'de': 'Beenden', 'es': 'Terminar'},
    };
    return labels[key]?[lang] ?? labels[key]?['en'] ?? key;
  }
}
