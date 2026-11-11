import 'dart:ui';
import 'package:flutter/foundation.dart';
import '../models/activity_session.dart';
import '../models/activity_type.dart';
import '../models/habit_item.dart';
import '../models/tempo_config.dart';
import '../models/user_profile.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';

class UserProvider extends ChangeNotifier {
  UserProfile _profile = UserProfile.defaultProfile();
  List<ActivitySession> _allSessions = [];
  bool _isLoading = true;
  bool _showAllActivities = false;

  UserProfile get profile => _profile;
  String get languageCode => _profile.languageCode;
  List<ActivitySession> get allSessions => List.unmodifiable(_allSessions);
  bool get isLoading => _isLoading;
  bool get isOnboardingCompleted => _profile.isOnboardingCompleted;
  ActivityType get activeActivityType => _profile.activeActivityType;
  bool get showAllActivities => _showAllActivities;

  void toggleAllActivitiesFilter() {
    _showAllActivities = !_showAllActivities;
    notifyListeners();
  }

  void setShowAllActivities(bool value) {
    if (_showAllActivities != value) {
      _showAllActivities = value;
      notifyListeners();
    }
  }

  // Active mode's weekly goal
  double get currentModeWeeklyGoal => _profile.getGoalForMode(_profile.activeActivityType);

  bool hasGoalForMode(ActivityType type) => _profile.hasGoalForMode(type);

  // Switch mode
  Future<void> setActiveActivityType(ActivityType type) async {
    if (_profile.activeActivityType == type) return;
    _profile = _profile.copyWith(activeActivityType: type);
    await StorageService.saveProfile(_profile);
    _profile = await StorageService.checkAndAdvanceStreak(_profile, _allSessions);
    notifyListeners();
  }

  // Set goal for specific mode
  Future<void> setGoalForMode(ActivityType type, double goalKm) async {
    final Map<String, double> updated = Map.from(_profile.modeWeeklyGoals);
    updated[type.name] = goalKm;

    if (_profile.activeActivityType == type) {
      _profile = _profile.copyWith(
        weeklyGoalKm: goalKm,
        modeWeeklyGoals: updated,
      );
    } else {
      _profile = _profile.copyWith(modeWeeklyGoals: updated);
    }

    await StorageService.saveProfile(_profile);
    _profile = await StorageService.checkAndAdvanceStreak(_profile, _allSessions);
    notifyListeners();
  }

  // Initialize
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    // Detect system locale default
    final systemLocale = PlatformDispatcher.instance.locale.languageCode.toLowerCase();
    final defaultLang = ['pl', 'en', 'de', 'es'].contains(systemLocale) ? systemLocale : 'en';

    _profile = await StorageService.loadProfile(defaultLang: defaultLang);
    _allSessions = await StorageService.getSessions();

    // Check weekly streak logic
    _profile = await StorageService.checkAndAdvanceStreak(_profile, _allSessions);

    _isLoading = false;
    notifyListeners();

    // Request notification permissions on app launch / restart and schedule habits
    try {
      await NotificationService.initialize();
      await NotificationService.requestPermissions();
      await NotificationService.scheduleHabitNotifications(_profile.habits, _profile.languageCode);
    } catch (_) {}
  }

  // Reload sessions from disk
  Future<void> reloadSessions() async {
    _allSessions = await StorageService.getSessions();
    _profile = await StorageService.checkAndAdvanceStreak(_profile, _allSessions);
    notifyListeners();
  }

  // Total KM in current week for active mode
  double get currentWeekKm {
    final now = DateTime.now();
    final startOfWeek = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    return _allSessions
        .where((s) => s.startTime.isAfter(startOfWeek) && s.type == _profile.activeActivityType)
        .fold(0.0, (sum, s) => sum + s.distanceKm);
  }

  // Total KM in current week for all activities
  double get allActivitiesWeekKm {
    final now = DateTime.now();
    final startOfWeek = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    return _allSessions
        .where((s) => s.startTime.isAfter(startOfWeek))
        .fold(0.0, (sum, s) => sum + s.distanceKm);
  }

  // Progress 0.0 .. 1.0 for active mode
  double get weeklyProgress {
    final goal = currentModeWeeklyGoal;
    if (goal <= 0) return 0.0;
    return (currentWeekKm / goal).clamp(0.0, 1.0);
  }

  // Km left to goal for active mode
  double get kmLeftToGoal {
    final diff = currentModeWeeklyGoal - currentWeekKm;
    return diff > 0 ? diff : 0.0;
  }

  // Sessions for home screen based on active toggle
  List<ActivitySession> get recentSessions {
    final source = _showAllActivities
        ? _allSessions
        : _allSessions.where((s) => s.type == _profile.activeActivityType).toList();
    return source.take(4).toList();
  }

  // Set Language
  Future<void> setLanguage(String code) async {
    _profile = _profile.copyWith(languageCode: code);
    await StorageService.saveProfile(_profile);
    await NotificationService.scheduleHabitNotifications(_profile.habits, code);
    notifyListeners();
  }

  // Complete Onboarding with mode and goal
  Future<void> completeOnboarding({
    required String name,
    required ActivityType activityType,
    required double weeklyGoalKm,
    required List<HabitItem> habits,
  }) async {
    final Map<String, double> goals = Map.from(_profile.modeWeeklyGoals);
    goals[activityType.name] = weeklyGoalKm;

    _profile = _profile.copyWith(
      name: name,
      activeActivityType: activityType,
      weeklyGoalKm: weeklyGoalKm,
      modeWeeklyGoals: goals,
      habits: habits,
      isOnboardingCompleted: true,
    );
    await StorageService.saveProfile(_profile);
    await NotificationService.requestPermissions();
    await NotificationService.scheduleHabitNotifications(_profile.habits, _profile.languageCode);
    notifyListeners();
  }

  // Update Goal
  Future<void> updateGoal({
    required double newGoalKm,
    bool forNextWeek = true,
  }) async {
    if (forNextWeek) {
      _profile = _profile.copyWith(nextWeekGoalKm: newGoalKm);
    } else {
      await setGoalForMode(_profile.activeActivityType, newGoalKm);
      return;
    }
    await StorageService.saveProfile(_profile);
    notifyListeners();
  }

  // Update Tempo Config
  Future<void> updateTempoConfig(TempoConfig config) async {
    _profile = _profile.copyWith(tempoConfig: config);
    await StorageService.saveProfile(_profile);
    notifyListeners();
  }

  // Update Habits
  Future<void> updateHabits(List<HabitItem> habits) async {
    _profile = _profile.copyWith(habits: habits);
    await StorageService.saveProfile(_profile);
    await NotificationService.scheduleHabitNotifications(_profile.habits, _profile.languageCode);
    notifyListeners();
  }

  // Delete an individual session
  Future<void> deleteSession(String id) async {
    await StorageService.deleteSession(id);
    _allSessions = await StorageService.getSessions();
    _profile = await StorageService.checkAndAdvanceStreak(_profile, _allSessions);
    notifyListeners();
  }

  Future<void> resetApp() async {
    await StorageService.clearAll();
    _allSessions = [];
    _profile = UserProfile.defaultProfile(lang: _profile.languageCode);
    notifyListeners();
  }

  // Pick a congratulation message based on user habits and mode
  String getPersonalizedCongratulations(String lang) {
    final activeHabits = _profile.habits.where((h) => h.isEnabled && h.triggerTime != null).toList();
    if (activeHabits.isNotEmpty) {
      final chosen = (activeHabits..shuffle()).first;
      switch (chosen.id) {
        case 'netflix':
          return lang == 'pl'
              ? 'Gratulacje! Wspaniała aktywność zamiast bezczynnie leżeć przed Netflixem!'
              : 'Congratulations! You chose healthy movement over Netflix!';
        case 'tv':
          return lang == 'pl'
              ? 'Brawo! Zamiast siedzieć przed telewizorem, wybrałeś świeże powietrze i ruch!'
              : 'Great job! Fresh air and active movement instead of TV!';
        case 'boredom':
          return lang == 'pl'
              ? 'Świetny krok! Zamiast zamulać w domu, zresetowałeś głowę na świeżym powietrzu!'
              : 'Awesome! You cleared your mind with outdoor movement!';
        default:
          break;
      }
    }
    return lang == 'pl'
        ? 'Gratulacje! Świetny trening i kolejny krok do regularnego nawyku!'
        : 'Congratulations! Great activity keeping your healthy streak alive!';
  }
}
