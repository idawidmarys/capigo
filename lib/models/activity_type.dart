import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum ActivityType {
  walk,
  jog, // legacy alias for run
  run,
  bike,
  nordicWalk;

  static List<ActivityType> get userSelectableModes => [
        ActivityType.walk,
        ActivityType.run,
        ActivityType.bike,
        ActivityType.nordicWalk,
      ];

  String get displayNamePl {
    switch (this) {
      case ActivityType.walk:
        return 'Spacer';
      case ActivityType.run:
      case ActivityType.jog:
        return 'Bieg';
      case ActivityType.bike:
        return 'Rower';
      case ActivityType.nordicWalk:
        return 'Nordic walking';
    }
  }

  String getLocalizedName(String lang) {
    if (lang == 'pl') return displayNamePl;
    switch (this) {
      case ActivityType.walk:
        return 'Walk';
      case ActivityType.run:
      case ActivityType.jog:
        return 'Run';
      case ActivityType.bike:
        return 'Cycling';
      case ActivityType.nordicWalk:
        return 'Nordic walking';
    }
  }

  String get startButtonTextPl {
    switch (this) {
      case ActivityType.walk:
        return 'Rozpocznij spacer';
      case ActivityType.run:
      case ActivityType.jog:
        return 'Rozpocznij bieg';
      case ActivityType.bike:
        return 'Rozpocznij jazdę na rowerze';
      case ActivityType.nordicWalk:
        return 'Rozpocznij nordic walking';
    }
  }

  String get habitQuestionPl {
    switch (this) {
      case ActivityType.walk:
        return 'Dlaczego warto wyjść na spacer?';
      case ActivityType.run:
      case ActivityType.jog:
        return 'Dlaczego warto pobiegać?';
      case ActivityType.bike:
        return 'Dlaczego warto wyjść na rower?';
      case ActivityType.nordicWalk:
        return 'Dlaczego warto wyjść na nordic walking?';
    }
  }

  IconData get icon {
    switch (this) {
      case ActivityType.walk:
        return Icons.directions_walk_rounded;
      case ActivityType.jog:
      case ActivityType.run:
        return Icons.directions_run_rounded;
      case ActivityType.bike:
        return Icons.directions_bike_rounded;
      case ActivityType.nordicWalk:
        return Icons.hiking_rounded;
    }
  }

  Color get color {
    switch (this) {
      case ActivityType.walk:
        return AppColors.walkColor;
      case ActivityType.jog:
      case ActivityType.run:
        return AppColors.runColor;
      case ActivityType.bike:
        return const Color(0xFF0288D1);
      case ActivityType.nordicWalk:
        return const Color(0xFF689F38);
    }
  }

  double get defaultGoalKm {
    switch (this) {
      case ActivityType.walk:
        return 12.0;
      case ActivityType.run:
      case ActivityType.jog:
        return 15.0;
      case ActivityType.bike:
        return 35.0;
      case ActivityType.nordicWalk:
        return 12.0;
    }
  }

  // Estimated MET (Metabolic Equivalent of Task) for calorie computation
  double get metValue {
    switch (this) {
      case ActivityType.walk:
        return 3.5;
      case ActivityType.jog:
        return 7.0;
      case ActivityType.run:
        return 9.8;
      case ActivityType.bike:
        return 7.5;
      case ActivityType.nordicWalk:
        return 4.8;
    }
  }
}
