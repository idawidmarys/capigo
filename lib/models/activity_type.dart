import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum ActivityType {
  walk,
  jog,
  run;

  String get displayNamePl {
    switch (this) {
      case ActivityType.walk:
        return 'Spacer';
      case ActivityType.jog:
        return 'Trucht';
      case ActivityType.run:
        return 'Bieg';
    }
  }

  IconData get icon {
    switch (this) {
      case ActivityType.walk:
        return Icons.directions_walk;
      case ActivityType.jog:
        return Icons.hiking;
      case ActivityType.run:
        return Icons.directions_run;
    }
  }

  Color get color {
    switch (this) {
      case ActivityType.walk:
        return AppColors.walkColor;
      case ActivityType.jog:
        return AppColors.jogColor;
      case ActivityType.run:
        return AppColors.runColor;
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
        return 10.0;
    }
  }
}
