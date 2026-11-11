import 'activity_type.dart';
import 'route_point.dart';

class SessionDataPoint {
  final int second;
  final double distanceMeters;
  final int steps;
  final double speedKmh;

  SessionDataPoint({
    required this.second,
    required this.distanceMeters,
    required this.steps,
    required this.speedKmh,
  });

  Map<String, dynamic> toJson() => {
        'second': second,
        'distanceMeters': distanceMeters,
        'steps': steps,
        'speedKmh': speedKmh,
      };

  factory SessionDataPoint.fromJson(Map<String, dynamic> json) => SessionDataPoint(
        second: json['second'] as int,
        distanceMeters: (json['distanceMeters'] as num).toDouble(),
        steps: json['steps'] as int,
        speedKmh: (json['speedKmh'] as num).toDouble(),
      );
}

class ActivitySession {
  final String id;
  final ActivityType type;
  final DateTime startTime;
  final DateTime endTime;
  final int durationSeconds;
  final double distanceMeters;
  final int steps;
  final double averageCadence; // steps per minute
  final double avgSpeedKmh;
  final int tempoLevel; // 1 to 5
  final String tempoName;
  final int calories;
  final String congratulationMessage;
  final List<RoutePoint> route;
  final List<SessionDataPoint> timeSeries;
  final List<String> photoPaths;

  ActivitySession({
    required this.id,
    required this.type,
    required this.startTime,
    required this.endTime,
    required this.durationSeconds,
    required this.distanceMeters,
    required this.steps,
    required this.averageCadence,
    required this.avgSpeedKmh,
    required this.tempoLevel,
    required this.tempoName,
    required this.calories,
    required this.congratulationMessage,
    required this.route,
    required this.timeSeries,
    this.photoPaths = const [],
  });

  double get distanceKm => distanceMeters / 1000.0;

  // Pace in min/km
  String get averagePaceFormatted {
    if (distanceMeters < 50 || durationSeconds == 0) return "--:--";
    final double minutesPerKm = (durationSeconds / 60.0) / (distanceMeters / 1000.0);
    final int paceMin = minutesPerKm.floor();
    final int paceSec = ((minutesPerKm - paceMin) * 60).round();
    return "${paceMin.toString().padLeft(2, '0')}:${paceSec.toString().padLeft(2, '0')}";
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'durationSeconds': durationSeconds,
      'distanceMeters': distanceMeters,
      'steps': steps,
      'averageCadence': averageCadence,
      'avgSpeedKmh': avgSpeedKmh,
      'tempoLevel': tempoLevel,
      'tempoName': tempoName,
      'calories': calories,
      'congratulationMessage': congratulationMessage,
      'route': route.map((p) => p.toJson()).toList(),
      'timeSeries': timeSeries.map((t) => t.toJson()).toList(),
      'photoPaths': photoPaths,
    };
  }

  factory ActivitySession.fromJson(Map<String, dynamic> json) {
    return ActivitySession(
      id: json['id'] as String,
      type: ActivityType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ActivityType.walk,
      ),
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      durationSeconds: json['durationSeconds'] as int,
      distanceMeters: (json['distanceMeters'] as num).toDouble(),
      steps: json['steps'] as int? ?? 0,
      averageCadence: (json['averageCadence'] as num?)?.toDouble() ?? 0.0,
      avgSpeedKmh: (json['avgSpeedKmh'] as num?)?.toDouble() ?? 0.0,
      tempoLevel: json['tempoLevel'] as int? ?? 2,
      tempoName: json['tempoName'] as String? ?? 'Spokojne',
      calories: json['calories'] as int? ?? 0,
      congratulationMessage: json['congratulationMessage'] as String? ??
          'Gratulacje! Właśnie wykonałeś zdrowy spacer zamiast siedzieć w domu!',
      route: (json['route'] as List<dynamic>? ?? [])
          .map((item) => RoutePoint.fromJson(item as Map<String, dynamic>))
          .toList(),
      timeSeries: (json['timeSeries'] as List<dynamic>? ?? [])
          .map((item) => SessionDataPoint.fromJson(item as Map<String, dynamic>))
          .toList(),
      photoPaths: (json['photoPaths'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
    );
  }
}
