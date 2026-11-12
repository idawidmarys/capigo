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
    if (lang == 'pl') {
      return displayNamePl;
    } else if (lang == 'de') {
      switch (this) {
        case ActivityType.walk:
          return 'Spaziergang';
        case ActivityType.run:
        case ActivityType.jog:
          return 'Laufen';
        case ActivityType.bike:
          return 'Radfahren';
        case ActivityType.nordicWalk:
          return 'Nordic Walking';
      }
    } else if (lang == 'es') {
      switch (this) {
        case ActivityType.walk:
          return 'Paseo';
        case ActivityType.run:
        case ActivityType.jog:
          return 'Carrera';
        case ActivityType.bike:
          return 'Ciclismo';
        case ActivityType.nordicWalk:
          return 'Nordic walking';
      }
    } else {
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
  }

  String getStartButtonText(String lang) {
    if (lang == 'pl') {
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
    } else if (lang == 'de') {
      switch (this) {
        case ActivityType.walk:
          return 'Spaziergang starten';
        case ActivityType.run:
        case ActivityType.jog:
          return 'Lauf starten';
        case ActivityType.bike:
          return 'Radtour starten';
        case ActivityType.nordicWalk:
          return 'Nordic Walking starten';
      }
    } else if (lang == 'es') {
      switch (this) {
        case ActivityType.walk:
          return 'Iniciar paseo';
        case ActivityType.run:
        case ActivityType.jog:
          return 'Iniciar carrera';
        case ActivityType.bike:
          return 'Iniciar ciclismo';
        case ActivityType.nordicWalk:
          return 'Iniciar nordic walking';
      }
    } else {
      switch (this) {
        case ActivityType.walk:
          return 'Start walking';
        case ActivityType.run:
        case ActivityType.jog:
          return 'Start running';
        case ActivityType.bike:
          return 'Start cycling';
        case ActivityType.nordicWalk:
          return 'Start nordic walking';
      }
    }
  }

  String get startButtonTextPl => getStartButtonText('pl');

  String get actionVerbPl {
    switch (this) {
      case ActivityType.walk:
        return 'spacer';
      case ActivityType.run:
      case ActivityType.jog:
        return 'bieg';
      case ActivityType.bike:
        return 'rower';
      case ActivityType.nordicWalk:
        return 'nordic walking';
    }
  }

  String streakText(int weeks, String lang) {
    if (lang == 'pl') {
      switch (this) {
        case ActivityType.walk:
          return '$weeks. Tydzień Regularnego Spacerowania';
        case ActivityType.run:
        case ActivityType.jog:
          return '$weeks. Tydzień Regularnego Biegania';
        case ActivityType.bike:
          return '$weeks. Tydzień Regularnej Jazdy Na Rowerze';
        case ActivityType.nordicWalk:
          return '$weeks. Tydzień Regularnego Nordic Walkingu';
      }
    } else if (lang == 'de') {
      switch (this) {
        case ActivityType.walk:
          return '$weeks. Woche regelmäßiges Spazierengehen';
        case ActivityType.run:
        case ActivityType.jog:
          return '$weeks. Woche regelmäßiges Laufen';
        case ActivityType.bike:
          return '$weeks. Woche regelmäßiges Radfahren';
        case ActivityType.nordicWalk:
          return '$weeks. Woche regelmäßiges Nordic Walking';
      }
    } else if (lang == 'es') {
      switch (this) {
        case ActivityType.walk:
          return '$weeks.ª semana de paseos regulares';
        case ActivityType.run:
        case ActivityType.jog:
          return '$weeks.ª semana de carreras regulares';
        case ActivityType.bike:
          return '$weeks.ª semana de ciclismo regular';
        case ActivityType.nordicWalk:
          return '$weeks.ª semana de nordic walking regular';
      }
    } else {
      switch (this) {
        case ActivityType.walk:
          return 'Week $weeks of regular walking';
        case ActivityType.run:
        case ActivityType.jog:
          return 'Week $weeks of regular running';
        case ActivityType.bike:
          return 'Week $weeks of regular cycling';
        case ActivityType.nordicWalk:
          return 'Week $weeks of regular nordic walking';
      }
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
