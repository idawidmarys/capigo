import 'activity_type.dart';
import 'habit_item.dart';
import 'tempo_config.dart';

class UserProfile {
  final String name;
  final double weeklyGoalKm;
  final double? nextWeekGoalKm;
  final int streakWeeks; // Licznik regularnych tygodni
  final int lastActiveWeekYear; // week number + year for streak evaluation
  final String languageCode;
  final bool isOnboardingCompleted;
  final List<HabitItem> habits;
  final TempoConfig tempoConfig;
  final ActivityType activeActivityType;
  final Map<String, double> modeWeeklyGoals;

  UserProfile({
    required this.name,
    required this.weeklyGoalKm,
    this.nextWeekGoalKm,
    this.streakWeeks = 1,
    required this.lastActiveWeekYear,
    this.languageCode = 'pl',
    this.isOnboardingCompleted = false,
    required this.habits,
    required this.tempoConfig,
    this.activeActivityType = ActivityType.walk,
    this.modeWeeklyGoals = const {},
  });

  double getGoalForMode(ActivityType type) {
    if (modeWeeklyGoals.containsKey(type.name)) {
      return modeWeeklyGoals[type.name]!;
    }
    if (type == activeActivityType) {
      return weeklyGoalKm;
    }
    return type.defaultGoalKm;
  }

  bool hasGoalForMode(ActivityType type) {
    return modeWeeklyGoals.containsKey(type.name);
  }

  UserProfile copyWith({
    String? name,
    double? weeklyGoalKm,
    double? nextWeekGoalKm,
    int? streakWeeks,
    int? lastActiveWeekYear,
    String? languageCode,
    bool? isOnboardingCompleted,
    List<HabitItem>? habits,
    TempoConfig? tempoConfig,
    ActivityType? activeActivityType,
    Map<String, double>? modeWeeklyGoals,
  }) {
    return UserProfile(
      name: name ?? this.name,
      weeklyGoalKm: weeklyGoalKm ?? this.weeklyGoalKm,
      nextWeekGoalKm: nextWeekGoalKm ?? this.nextWeekGoalKm,
      streakWeeks: streakWeeks ?? this.streakWeeks,
      lastActiveWeekYear: lastActiveWeekYear ?? this.lastActiveWeekYear,
      languageCode: languageCode ?? this.languageCode,
      isOnboardingCompleted: isOnboardingCompleted ?? this.isOnboardingCompleted,
      habits: habits ?? this.habits,
      tempoConfig: tempoConfig ?? this.tempoConfig,
      activeActivityType: activeActivityType ?? this.activeActivityType,
      modeWeeklyGoals: modeWeeklyGoals ?? this.modeWeeklyGoals,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'weeklyGoalKm': weeklyGoalKm,
        'nextWeekGoalKm': nextWeekGoalKm,
        'streakWeeks': streakWeeks,
        'lastActiveWeekYear': lastActiveWeekYear,
        'languageCode': languageCode,
        'isOnboardingCompleted': isOnboardingCompleted,
        'habits': habits.map((h) => h.toJson()).toList(),
        'tempoConfig': tempoConfig.toJson(),
        'activeActivityType': activeActivityType.name,
        'modeWeeklyGoals': modeWeeklyGoals,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final modeName = json['activeActivityType'] as String? ?? 'walk';
    ActivityType resolvedMode = ActivityType.walk;
    try {
      resolvedMode = ActivityType.values.firstWhere(
        (e) => e.name == modeName,
        orElse: () => ActivityType.walk,
      );
    } catch (_) {}

    Map<String, double> goals = {};
    if (json['modeWeeklyGoals'] is Map) {
      (json['modeWeeklyGoals'] as Map).forEach((k, v) {
        if (v is num) {
          goals[k.toString()] = v.toDouble();
        }
      });
    }

    final double baseWeeklyGoal = (json['weeklyGoalKm'] as num?)?.toDouble() ?? 12.0;
    if (!goals.containsKey(resolvedMode.name)) {
      goals[resolvedMode.name] = baseWeeklyGoal;
    }

    return UserProfile(
      name: json['name'] as String? ?? 'Spacerowicz',
      weeklyGoalKm: baseWeeklyGoal,
      nextWeekGoalKm: (json['nextWeekGoalKm'] as num?)?.toDouble(),
      streakWeeks: json['streakWeeks'] as int? ?? 1,
      lastActiveWeekYear: json['lastActiveWeekYear'] as int? ?? 0,
      languageCode: json['languageCode'] as String? ?? 'pl',
      isOnboardingCompleted: json['isOnboardingCompleted'] as bool? ?? false,
      habits: (json['habits'] as List<dynamic>? ?? [])
          .map((h) => HabitItem.fromJson(h as Map<String, dynamic>))
          .toList(),
      tempoConfig: json['tempoConfig'] != null
          ? TempoConfig.fromJson(json['tempoConfig'] as Map<String, dynamic>)
          : TempoConfig.defaultPreset(),
      activeActivityType: resolvedMode,
      modeWeeklyGoals: goals,
    );
  }

  static UserProfile defaultProfile({String lang = 'pl'}) {
    return UserProfile(
      name: 'Maja',
      weeklyGoalKm: 12.0,
      nextWeekGoalKm: null,
      streakWeeks: 1,
      lastActiveWeekYear: 0,
      languageCode: lang,
      isOnboardingCompleted: false,
      habits: HabitItem.defaultHabits(),
      tempoConfig: TempoConfig.defaultPreset(),
      activeActivityType: ActivityType.walk,
      modeWeeklyGoals: {'walk': 12.0},
    );
  }
}
