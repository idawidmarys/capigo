import 'package:flutter/foundation.dart';
import '../models/activity_session.dart';
import '../models/habit_item.dart';
import '../models/tempo_config.dart';
import '../models/user_profile.dart';
import '../services/storage_service.dart';

class UserProvider extends ChangeNotifier {
  UserProfile _profile = UserProfile.defaultProfile();
  List<ActivitySession> _allSessions = [];
  bool _isLoading = true;

  UserProfile get profile => _profile;
  String get languageCode => _profile.languageCode;
  List<ActivitySession> get allSessions => List.unmodifiable(_allSessions);
  bool get isLoading => _isLoading;
  bool get isOnboardingCompleted => _profile.isOnboardingCompleted;

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
  }

  // Reload sessions from disk
  Future<void> reloadSessions() async {
    _allSessions = await StorageService.getSessions();
    _profile = await StorageService.checkAndAdvanceStreak(_profile, _allSessions);
    notifyListeners();
  }

  // Total KM in current week
  double get currentWeekKm {
    final now = DateTime.now();
    final startOfWeek = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    return _allSessions
        .where((s) => s.startTime.isAfter(startOfWeek))
        .fold(0.0, (sum, s) => sum + s.distanceKm);
  }

  // Progress 0.0 .. 1.0
  double get weeklyProgress {
    if (_profile.weeklyGoalKm <= 0) return 0.0;
    return (currentWeekKm / _profile.weeklyGoalKm).clamp(0.0, 1.0);
  }

  // Km left to goal
  double get kmLeftToGoal {
    final diff = _profile.weeklyGoalKm - currentWeekKm;
    return diff > 0 ? diff : 0.0;
  }

  // Last 3 sessions for home screen
  List<ActivitySession> get last3Sessions {
    return _allSessions.take(3).toList();
  }

  // Change Language
  Future<void> setLanguage(String code) async {
    if (_profile.languageCode == code) return;
    _profile = _profile.copyWith(languageCode: code);
    await StorageService.saveProfile(_profile);
    notifyListeners();
  }

  // Complete Onboarding
  Future<void> completeOnboarding({
    required String name,
    required double weeklyGoalKm,
    required List<HabitItem> habits,
  }) async {
    _profile = _profile.copyWith(
      name: name.trim().isEmpty ? 'Spacerowicz' : name.trim(),
      weeklyGoalKm: weeklyGoalKm,
      habits: habits,
      isOnboardingCompleted: true,
      streakWeeks: 1,
    );
    await StorageService.saveProfile(_profile);
    notifyListeners();
  }

  // Update Goal
  Future<void> updateGoal({required double newGoalKm, required bool forNextWeek}) async {
    if (forNextWeek) {
      _profile = _profile.copyWith(nextWeekGoalKm: newGoalKm);
    } else {
      _profile = _profile.copyWith(weeklyGoalKm: newGoalKm);
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

  // Pick a congratulation message based on user habits
  String getPersonalizedCongratulations(String lang) {
    final activeHabits = _profile.habits.where((h) => h.isEnabled && h.triggerTime != null).toList();
    if (activeHabits.isNotEmpty) {
      final chosen = (activeHabits..shuffle()).first;
      switch (chosen.id) {
        case 'netflix':
          return lang == 'pl'
              ? 'Gratulacje! Właśnie wykonałeś zdrowy spacer zamiast bezczynnie leżeć przed Netflixem!'
              : 'Congratulations! You chose a healthy walk over Netflix and snacks!';
        case 'tv':
          return lang == 'pl'
              ? 'Brawo! Zamiast siedzieć przed telewizorem, wybrałeś świeże powietrze i energię!'
              : 'Great job! Fresh air and steps instead of sitting before the TV!';
        case 'boredom':
          return lang == 'pl'
              ? 'Świetny krok! Zamiast zamulać w domu, zresetowałeś głowę na świeżym powietrzu!'
              : 'Awesome! You cleared your mind with a great walk instead of feeling sluggish!';
        case 'coffee_tea':
          return lang == 'pl'
              ? 'Wspaniale! Spacer z kawką lub herbatą to najlepsze połączenie relaksu i ruchu!'
              : 'Wonderful! A coffee walk is the best way to combine relaxation and steps!';
        case 'walk_dog':
          return lang == 'pl'
              ? 'Twój pies na pewno merda ogonem! Wspaniały wspólny spacer!'
              : 'Your dog must be so happy! A wonderful walk together!';
        default:
          break;
      }
    }
    return lang == 'pl'
        ? 'Gratulacje! Właśnie wykonałeś zdrowy spacer, budując regularny nawyk!'
        : 'Congratulations! You just finished a healthy walk, keeping your streak alive!';
  }
}
