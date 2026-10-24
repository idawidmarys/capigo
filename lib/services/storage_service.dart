import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/activity_session.dart';
import '../models/user_profile.dart';

class StorageService {
  static const String _profileKey = 'capigo_user_profile';
  static const String _sessionsKey = 'capigo_activity_sessions';

  // Load UserProfile
  static Future<UserProfile> loadProfile({String defaultLang = 'pl'}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_profileKey);
    if (raw == null || raw.isEmpty) {
      return UserProfile.defaultProfile(lang: defaultLang);
    }
    try {
      final Map<String, dynamic> json = jsonDecode(raw) as Map<String, dynamic>;
      final profile = UserProfile.fromJson(json);
      return profile;
    } catch (_) {
      return UserProfile.defaultProfile(lang: defaultLang);
    }
  }

  // Save UserProfile
  static Future<void> saveProfile(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(profile.toJson());
    await prefs.setString(_profileKey, encoded);
  }

  // Clear all data (app restart / reset)
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_profileKey);
    await prefs.remove(_sessionsKey);
  }

  // Save an activity session
  static Future<void> saveSession(ActivitySession session) async {
    final prefs = await SharedPreferences.getInstance();
    final List<ActivitySession> sessions = await getSessions();
    sessions.insert(0, session); // Newest first

    final String encoded = jsonEncode(sessions.map((s) => s.toJson()).toList());
    await prefs.setString(_sessionsKey, encoded);
  }

  // Retrieve all sessions
  static Future<List<ActivitySession>> getSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_sessionsKey);
    if (raw == null || raw.isEmpty) return [];

    try {
      final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
      return list.map((item) => ActivitySession.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  // Delete an activity session by ID
  static Future<void> deleteSession(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final List<ActivitySession> sessions = await getSessions();
    sessions.removeWhere((s) => s.id == id);
    final String encoded = jsonEncode(sessions.map((s) => s.toJson()).toList());
    await prefs.setString(_sessionsKey, encoded);
  }

  // Get current week sessions (Monday 00:00 to now)
  static Future<List<ActivitySession>> getThisWeekSessions() async {
    final sessions = await getSessions();
    final now = DateTime.now();
    final startOfWeek = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    return sessions.where((s) => s.startTime.isAfter(startOfWeek)).toList();
  }

  // Helper: check weekly streak advancement
  static Future<UserProfile> checkAndAdvanceStreak(UserProfile profile, List<ActivitySession> sessions) async {
    final now = DateTime.now();
    // Calculate simple week number of year
    final int currentWeekOfYear = ((now.difference(DateTime(now.year, 1, 1)).inDays) / 7).floor() + 1;
    final int currentWeekTag = now.year * 100 + currentWeekOfYear;

    if (profile.lastActiveWeekYear != currentWeekTag) {
      // It's a new week or first time initialization
      if (profile.lastActiveWeekYear != 0) {
        // Evaluate previous week total km
        final previousWeekStart = DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: now.weekday - 1 + 7));
        final previousWeekEnd = DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: now.weekday - 1));

        final prevWeekKm = sessions
            .where((s) => s.startTime.isAfter(previousWeekStart) && s.startTime.isBefore(previousWeekEnd))
            .fold(0.0, (sum, s) => sum + s.distanceKm);

        int updatedStreak = profile.streakWeeks;
        if (prevWeekKm >= profile.weeklyGoalKm) {
          updatedStreak++;
        }

        double newGoal = profile.weeklyGoalKm;
        if (profile.nextWeekGoalKm != null) {
          newGoal = profile.nextWeekGoalKm!;
        }

        final updatedProfile = profile.copyWith(
          streakWeeks: updatedStreak,
          weeklyGoalKm: newGoal,
          nextWeekGoalKm: null,
          lastActiveWeekYear: currentWeekTag,
        );
        await saveProfile(updatedProfile);
        return updatedProfile;
      } else {
        final updatedProfile = profile.copyWith(lastActiveWeekYear: currentWeekTag);
        await saveProfile(updatedProfile);
        return updatedProfile;
      }
    }
    return profile;
  }
}
