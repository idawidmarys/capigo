import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart' hide ActivityType;
import 'package:pedometer/pedometer.dart';
import 'package:uuid/uuid.dart';
import '../models/activity_session.dart';
import '../models/activity_type.dart';
import '../models/route_point.dart';
import '../models/tempo_config.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';

class TrackingProvider extends ChangeNotifier {
  ActivityType _currentType = ActivityType.walk;
  bool _isTracking = false;
  bool _isPaused = false;

  DateTime? _startTime;
  int _accumulatedPausedSeconds = 0;
  DateTime? _pauseStartTime;
  int _elapsedSeconds = 0;

  double _distanceMeters = 0.0;
  double _currentSpeedKmh = 0.0;
  double _currentHeading = 0.0;
  int _steps = 0;
  int _initialPedometerStepCount = -1;
  Position? _lastPosition;

  final List<RoutePoint> _routePoints = [];
  final List<SessionDataPoint> _timeSeries = [];

  Timer? _timer;
  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<StepCount>? _pedometerSubscription;

  TrackingProvider() {
    // Listen for notification action buttons (Pauza / Wznów / Zakończ)
    NotificationService.initialize(onNotificationAction: (action) {
      if (action == 'pause_action') {
        pauseTracking();
      } else if (action == 'resume_action') {
        resumeTracking();
      } else if (action == 'stop_action') {
        pauseTracking();
      }
    });
  }

  // Getters
  ActivityType get currentType => _currentType;
  bool get isTracking => _isTracking;
  bool get isPaused => _isPaused;
  double get currentHeading => _currentHeading;
  Position? get lastPosition => _lastPosition;

  // Real-clock wall time calculation: never freezes even when screen is locked
  int get elapsedSeconds {
    if (_startTime == null) return 0;
    if (_isPaused) {
      return _elapsedSeconds;
    }
    final now = DateTime.now();
    final total = now.difference(_startTime!).inSeconds - _accumulatedPausedSeconds;
    return total >= 0 ? total : 0;
  }

  double get distanceMeters => _distanceMeters;
  double get distanceKm => _distanceMeters / 1000.0;
  double get currentSpeedKmh => _currentSpeedKmh;
  int get steps => _steps;
  List<RoutePoint> get routePoints => List.unmodifiable(_routePoints);
  List<SessionDataPoint> get timeSeries => List.unmodifiable(_timeSeries);

  // Cadence in steps per minute
  double get currentCadence {
    final curElapsed = elapsedSeconds;
    if (curElapsed < 10) return 0.0;
    return (_steps / (curElapsed / 60.0));
  }

  // Average speed in km/h
  double get averageSpeedKmh {
    final curElapsed = elapsedSeconds;
    if (curElapsed < 5) return 0.0;
    return (_distanceMeters / 1000.0) / (curElapsed / 3600.0);
  }

  // Formatted duration 00:00:00
  String get formattedDuration {
    final curElapsed = elapsedSeconds;
    final int hours = curElapsed ~/ 3600;
    final int minutes = (curElapsed % 3600) ~/ 60;
    final int seconds = curElapsed % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // Current pace min/km
  String get currentPaceFormatted {
    final curElapsed = elapsedSeconds;
    if (_distanceMeters < 50 || curElapsed == 0) return "--:--";
    final double minutesPerKm = (curElapsed / 60.0) / (_distanceMeters / 1000.0);
    final int min = minutesPerKm.floor();
    final int sec = ((minutesPerKm - min) * 60).round();
    return "${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}";
  }

  // Start workout
  Future<bool> startTracking(ActivityType type) async {
    try {
      final hasPermission = await LocationService.handlePermission();
      if (!hasPermission) {
        return false;
      }

      _currentType = type;
      _isTracking = true;
      _isPaused = false;
      _accumulatedPausedSeconds = 0;
      _pauseStartTime = null;
      _elapsedSeconds = 0;
      _distanceMeters = 0.0;
      _currentSpeedKmh = 0.0;
      _currentHeading = 0.0;
      _steps = 0;
      _initialPedometerStepCount = -1;
      _routePoints.clear();
      _timeSeries.clear();
      _startTime = DateTime.now();

      // Fetch initial GPS position immediately so map is never on Warsaw
      try {
        final initialPos = await LocationService.getCurrentPosition();
        if (initialPos != null) {
          _lastPosition = initialPos;
          if (initialPos.heading >= 0 && !initialPos.heading.isNaN && initialPos.heading != 0) {
            _currentHeading = initialPos.heading;
          }
          _routePoints.add(RoutePoint(
            latitude: initialPos.latitude,
            longitude: initialPos.longitude,
            timestamp: DateTime.now(),
            speed: initialPos.speed,
            altitude: initialPos.altitude,
          ));
        }
      } catch (_) {}

      _startTimer();
      _startLocationUpdates();
      _startPedometer();

      // Show ongoing notification on lock screen
      try {
        NotificationService.updateWorkoutNotification(
          duration: formattedDuration,
          distanceKm: distanceKm,
          steps: _steps,
          isPaused: false,
        );
      } catch (_) {}

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('startTracking error: $e');
      return true;
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isPaused) {
        _elapsedSeconds = elapsedSeconds;

        // If pedometer sensor is unavailable or not ticking, estimate steps from GPS distance
        if (_initialPedometerStepCount == -1) {
          final estimatedSteps = (_distanceMeters * 1.32).round();
          if (estimatedSteps > _steps) {
            _steps = estimatedSteps;
          }
        }

        // Sample time series every 5 seconds for smooth report charts
        if (_elapsedSeconds % 5 == 0 || _elapsedSeconds == 1) {
          _timeSeries.add(SessionDataPoint(
            second: _elapsedSeconds,
            distanceMeters: _distanceMeters,
            steps: _steps,
            speedKmh: _currentSpeedKmh,
          ));
        }

        // Update lock screen notification every 2 seconds
        if (_elapsedSeconds % 2 == 0) {
          NotificationService.updateWorkoutNotification(
            duration: formattedDuration,
            distanceKm: distanceKm,
            steps: _steps,
            isPaused: false,
          );
        }

        notifyListeners();
      }
    });
  }

  void _startPedometer() {
    if (kIsWeb) return;
    try {
      _pedometerSubscription?.cancel();
      _pedometerSubscription = Pedometer.stepCountStream.listen(
        (StepCount event) {
          if (_initialPedometerStepCount == -1) {
            _initialPedometerStepCount = event.steps;
          } else {
            final delta = event.steps - _initialPedometerStepCount;
            if (delta > 0) {
              _steps = delta;
              notifyListeners();
            }
          }
        },
        onError: (_) {
          // Sensor not available on this platform/emulator, uses GPS-stride fallback
        },
      );
    } catch (_) {
      // Ignored
    }
  }

  void _startLocationUpdates() {
    try {
      _positionSubscription?.cancel();
      _positionSubscription = LocationService.getPositionStream(distanceFilter: 2).listen((Position position) {
      if (_isPaused) return;

      _lastPosition = position;

      // Update heading / bearing
      if (position.heading >= 0 && !position.heading.isNaN && position.heading != 0) {
        _currentHeading = position.heading;
      } else if (_routePoints.length >= 2) {
        final prev = _routePoints.last;
        final dist = LocationService.calculateDistanceMeters(
          prev.latitude,
          prev.longitude,
          position.latitude,
          position.longitude,
        );
        if (dist > 1.2) {
          _currentHeading = _calculateBearing(
            prev.latitude,
            prev.longitude,
            position.latitude,
            position.longitude,
          );
        }
      }

      final newPoint = RoutePoint(
        latitude: position.latitude,
        longitude: position.longitude,
        timestamp: DateTime.now(),
        speed: position.speed,
        altitude: position.altitude,
      );

      if (_routePoints.isNotEmpty) {
        final lastPoint = _routePoints.last;
        final dist = LocationService.calculateDistanceMeters(
          lastPoint.latitude,
          lastPoint.longitude,
          newPoint.latitude,
          newPoint.longitude,
        );

        // Filter unrealistic GPS anomalies
        if (dist > 0.5 && dist < 80) {
          _distanceMeters += dist;
        }
      }

      _routePoints.add(newPoint);
      _currentSpeedKmh = (position.speed * 3.6).clamp(0.0, 99.0);

      // Keep lock screen notification fresh with real GPS meters
      NotificationService.updateWorkoutNotification(
        duration: formattedDuration,
        distanceKm: distanceKm,
        steps: _steps,
        isPaused: false,
      );

      notifyListeners();
    }, onError: (e) { debugPrint('Location stream error: $e'); });
    } catch (e) { debugPrint('startLocationUpdates error: $e'); }
  }

  double _calculateBearing(double lat1, double lon1, double lat2, double lon2) {
    final phi1 = lat1 * pi / 180.0;
    final phi2 = lat2 * pi / 180.0;
    final deltaLambda = (lon2 - lon1) * pi / 180.0;
    final y = sin(deltaLambda) * cos(phi2);
    final x = cos(phi1) * sin(phi2) - sin(phi1) * cos(phi2) * cos(deltaLambda);
    final theta = atan2(y, x);
    return (theta * 180.0 / pi + 360.0) % 360.0;
  }

  void pauseTracking() {
    if (_isPaused) return;
    _isPaused = true;
    _pauseStartTime = DateTime.now();
    _elapsedSeconds = elapsedSeconds;
    _currentSpeedKmh = 0.0;

    NotificationService.updateWorkoutNotification(
      duration: formattedDuration,
      distanceKm: distanceKm,
      steps: _steps,
      isPaused: true,
    );

    notifyListeners();
  }

  void resumeTracking() {
    if (!_isPaused) return;
    _isPaused = false;
    if (_pauseStartTime != null) {
      _accumulatedPausedSeconds += DateTime.now().difference(_pauseStartTime!).inSeconds;
      _pauseStartTime = null;
    }

    NotificationService.updateWorkoutNotification(
      duration: formattedDuration,
      distanceKm: distanceKm,
      steps: _steps,
      isPaused: false,
    );

    notifyListeners();
  }

  Future<ActivitySession?> stopTracking({
    required TempoConfig tempoConfig,
    required String congratulationMessage,
    required String langCode,
  }) async {
    _timer?.cancel();
    _positionSubscription?.cancel();
    _pedometerSubscription?.cancel();
    NotificationService.cancelWorkoutNotification();

    final finalElapsed = elapsedSeconds;
    if (_startTime == null || finalElapsed < 5) {
      _reset();
      notifyListeners();
      return null;
    }

    // Add final sample point if needed
    if (_timeSeries.isEmpty || _timeSeries.last.second != finalElapsed) {
      _timeSeries.add(SessionDataPoint(
        second: finalElapsed,
        distanceMeters: _distanceMeters,
        steps: _steps,
        speedKmh: _currentSpeedKmh,
      ));
    }

    final double avgCadence = currentCadence;
    final double avgSpeed = averageSpeedKmh;
    final tempoTier = tempoConfig.evaluate(avgSpeed, avgCadence);

    final double hours = finalElapsed / 3600.0;
    const double weightKg = 70.0;
    final int calculatedCalories = (tempoTier.met * weightKg * hours).round();

    final session = ActivitySession(
      id: const Uuid().v4(),
      type: _currentType,
      startTime: _startTime!,
      endTime: DateTime.now(),
      durationSeconds: finalElapsed,
      distanceMeters: _distanceMeters,
      steps: _steps,
      averageCadence: avgCadence,
      avgSpeedKmh: avgSpeed,
      tempoLevel: tempoTier.level,
      tempoName: tempoTier.getLocalizedName(langCode),
      calories: calculatedCalories,
      congratulationMessage: congratulationMessage,
      route: List.from(_routePoints),
      timeSeries: List.from(_timeSeries),
    );

    await StorageService.saveSession(session);
    _reset();
    notifyListeners();
    return session;
  }

  void _reset() {
    _isTracking = false;
    _isPaused = false;
    _startTime = null;
    _accumulatedPausedSeconds = 0;
    _pauseStartTime = null;
    _elapsedSeconds = 0;
    _distanceMeters = 0.0;
    _currentSpeedKmh = 0.0;
    _currentHeading = 0.0;
    _steps = 0;
    _initialPedometerStepCount = -1;
    _lastPosition = null;
    _routePoints.clear();
    _timeSeries.clear();
    NotificationService.cancelWorkoutNotification();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _positionSubscription?.cancel();
    _pedometerSubscription?.cancel();
    NotificationService.cancelWorkoutNotification();
    super.dispose();
  }
}
