import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolocator/geolocator.dart';

class LocationService {
  // Check and request permission
  static Future<bool> handlePermission() async {
    try {
      if (kIsWeb) {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        return permission == LocationPermission.always || permission == LocationPermission.whileInUse;
      }

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return false;
      }

      return true;
    } catch (_) {
      return true;
    }
  }

  // Get current one-time position quickly
  static Future<Position?> getCurrentPosition() async {
    try {
      final hasPerm = await handlePermission();
      if (!hasPerm) return null;

      try {
        final last = await Geolocator.getLastKnownPosition();
        if (last != null && DateTime.now().difference(last.timestamp).inMinutes < 5) {
          return last;
        }
      } catch (_) {}

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 4),
        ),
      );
    } catch (_) {
      try {
        return await Geolocator.getLastKnownPosition();
      } catch (_) {
        return null;
      }
    }
  }

  // Position stream for tracking with background support
  static Stream<Position> getPositionStream({int distanceFilter = 2}) {
    LocationSettings settings;

    try {
      if (!kIsWeb && Platform.isIOS) {
        settings = AppleSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          activityType: ActivityType.fitness,
          distanceFilter: distanceFilter,
          pauseLocationUpdatesAutomatically: false,
          showBackgroundLocationIndicator: true,
          allowBackgroundLocationUpdates: true,
        );
      } else if (!kIsWeb && Platform.isAndroid) {
        settings = AndroidSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: distanceFilter,
          intervalDuration: const Duration(seconds: 1),
          foregroundNotificationConfig: const ForegroundNotificationConfig(
            notificationTitle: "CapiGo - Spacer w toku 🦫",
            notificationText: "Zapisywanie trasy i parametrów spaceru...",
            enableWakeLock: true,
          ),
        );
      } else {
        settings = LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: distanceFilter,
        );
      }

      return Geolocator.getPositionStream(locationSettings: settings);
    } catch (_) {
      return Geolocator.getPositionStream(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: distanceFilter,
        ),
      );
    }
  }

  // Calculate distance in meters between two lat/lng points
  static double calculateDistanceMeters(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }
}
