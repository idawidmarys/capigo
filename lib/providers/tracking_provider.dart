import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart' hide ActivityType;
import 'package:pedometer/pedometer.dart';
import 'package:uuid/uuid.dart';
import '../models/activity_session.dart';
import '../models/activity_type.dart';
import '../models/route_point.dart';
import '../models/tempo_config.dart';
import '../services/location_service.dart';
import '../services/storage_service.dart';

class TrackingProvider extends ChangeNotifier {
  ActivityType _currentType = ActivityType.walk;
  bool _isTracking = false;
  bool _isPaused = false;

  DateTime? _startTime;
  int _elapsedSeconds = 0;
  double _distanceMeters = 0.0;
  double _currentSpeedKmh = 0.0;
  int _steps = 0;
  int _initialPedometerStepCount = -1;

  final List<RoutePoint> _routePoints = [];
  final List<SessionDataPoint> _timeSeries = [];

  Timer? _timer;
  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<StepCount>? _pedometerSubscription;

  // Getters
  ActivityType get currentType => _currentType;
  bool get isTracking => _isTracking;
  bool get isPaused => _isPaused;
  int get elapsedSeconds => _elapsedSeconds;
  double get distanceMeters => _distanceMeters;
  double get distanceKm => _distanceMeters / 1000.0;
  double get currentSpeedKmh => _currentSpeedKmh;
  int get steps => _steps;
  List<RoutePoint> get routePoints => List.unmodifiable(_routePoints);
  List<SessionDataPoint> get timeSeries => List.unmodifiable(_timeSeries);

  // Cadence in steps per minute
  double get currentCadence {
    if (_elapsedSeconds < 10) return 0.0;
    return (_steps / (_elapsedSeconds / 60.0));
  }

  // Average speed in km/h
  double get averageSpeedKmh {
    if (_elapsedSeconds < 5) return 0.0;
    return (_distanceMeters / 1000.0) / (_elapsedSeconds / 3600.0);
  }

  // Formatted duration 00:00:00
  String get formattedDuration {
    final int hours = _elapsedSeconds ~/ 3600;
    final int minutes = (_elapsedSeconds % 3600) ~/ 60;
    final int seconds = _elapsedSeconds % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // Current pace min/km
  String get currentPaceFormatted {
    if (_distanceMeters < 50 || _elapsedSeconds == 0) return "--:--";
    final double minutesPerKm = (_elapsedSeconds / 60.0) / (_distanceMeters / 1000.0);
    final int min = minutesPerKm.floor();
    final int sec = ((minutesPerKm - min) * 60).round();
    return "${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}";
  }

  // Start workout
  Future<bool> startTracking(ActivityType type) async {
    final hasPermission = await LocationService.handlePermission();
    if (!hasPermission) {
      return false;
    }

    _currentType = type;
    _isTracking = true;
    _isPaused = false;
    _elapsedSeconds = 0;
    _distanceMeters = 0.0;
    _currentSpeedKmh = 0.0;
    _steps = 0;
    _initialPedometerStepCount = -1;
    _routePoints.clear();
    _timeSeries.clear();
    _startTime = DateTime.now();

    _startTimer();
    _startLocationUpdates();
    _startPedometer();

    notifyListeners();
    return true;
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isPaused) {
        _elapsedSeconds++;

        // If pedometer sensor is unavailable or not ticking, simulate realistic step rate
        if (_initialPedometerStepCount == -1) {
          // Average walking stride: ~1.3 steps per meter
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

        notifyListeners();
      }
    });
  }

  void _startPedometer() {
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
          // Sensor not available on this platform/emulator, will use GPS-stride fallback
        },
      );
    } catch (_) {
      // Ignored
    }
  }

  void _startLocationUpdates() {
    _positionSubscription?.cancel();
    _positionSubscription = LocationService.getPositionStream(distanceFilter: 2).listen((Position position) {
      if (_isPaused) return;

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
      notifyListeners();
    });
  }

  void pauseTracking() {
    _isPaused = true;
    _currentSpeedKmh = 0.0;
    notifyListeners();
  }

  void resumeTracking() {
    _isPaused = false;
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

    if (_startTime == null || _elapsedSeconds < 5) {
      _reset();
      notifyListeners();
      return null;
    }

    // Add final sample point if needed
    if (_timeSeries.isEmpty || _timeSeries.last.second != _elapsedSeconds) {
      _timeSeries.add(SessionDataPoint(
        second: _elapsedSeconds,
        distanceMeters: _distanceMeters,
        steps: _steps,
        speedKmh: _currentSpeedKmh,
      ));
    }

    // Cadence & Speed calculations
    final double avgCadence = currentCadence;
    final double avgSpeed = averageSpeedKmh;

    // Evaluate tempo tier using min(speed, cadence) algorithm
    final tempoTier = tempoConfig.evaluate(avgSpeed, avgCadence);

    // Realistic calories computation: MET * 70kg * hours
    final double hours = _elapsedSeconds / 3600.0;
    const double weightKg = 70.0;
    final int calculatedCalories = (tempoTier.met * weightKg * hours).round();

    final session = ActivitySession(
      id: const Uuid().v4(),
      type: _currentType,
      startTime: _startTime!,
      endTime: DateTime.now(),
      durationSeconds: _elapsedSeconds,
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
    _elapsedSeconds = 0;
    _distanceMeters = 0.0;
    _currentSpeedKmh = 0.0;
    _steps = 0;
    _initialPedometerStepCount = -1;
    _routePoints.clear();
    _timeSeries.clear();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _positionSubscription?.cancel();
    _pedometerSubscription?.cancel();
    super.dispose();
  }
}
