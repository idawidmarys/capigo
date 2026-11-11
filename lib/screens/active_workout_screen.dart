import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../providers/tracking_provider.dart';
import '../providers/user_provider.dart';
import '../services/localization_service.dart';
import '../theme/app_colors.dart';
import 'workout_report_screen.dart';

class ActiveWorkoutScreen extends StatefulWidget {
  const ActiveWorkoutScreen({super.key});

  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen> {
  final MapController _mapController = MapController();
  bool _isMapReady = false;
  bool _followHeading = true;
  double _currentMapRotation = 0.0;
  double _lastAnimatedHeading = 0.0;
  LatLng? _lastCenteredPoint;

  @override
  Widget build(BuildContext context) {
    final tracking = context.watch<TrackingProvider>();
    final userProvider = context.watch<UserProvider>();
    final lang = userProvider.languageCode;

    final List<LatLng> polylinePoints = tracking.routePoints
        .map((p) => LatLng(p.latitude, p.longitude))
        .toList();

    final LatLng? currentPoint = polylinePoints.isNotEmpty
        ? polylinePoints.last
        : (tracking.lastPosition != null
            ? LatLng(tracking.lastPosition!.latitude, tracking.lastPosition!.longitude)
            : null);

    final LatLng displayCenter = currentPoint ?? const LatLng(52.2297, 21.0122);
    final double heading = tracking.currentHeading;

    // Follow and rotate map when moving (Google Maps navigation style)
    if (_followHeading && currentPoint != null && _isMapReady) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_isMapReady) return;
        final double targetRotation = (360.0 - heading) % 360.0;
        final bool shouldMove = _lastCenteredPoint == null ||
            _lastCenteredPoint!.latitude != currentPoint.latitude ||
            _lastCenteredPoint!.longitude != currentPoint.longitude ||
            (_lastAnimatedHeading - targetRotation).abs() > 2.0;

        if (shouldMove) {
          _lastCenteredPoint = currentPoint;
          _lastAnimatedHeading = targetRotation;
          try {
            _mapController.moveAndRotate(
              currentPoint,
              17.0,
              targetRotation,
            );
          } catch (_) {}
        }
      });
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          LocalizationService.tr('app_title', lang),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: tracking.isPaused ? Colors.amber.withValues(alpha: 0.2) : AppColors.softGreenTint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  tracking.isPaused ? Icons.pause_circle_filled : Icons.fiber_manual_record,
                  size: 14,
                  color: tracking.isPaused ? Colors.amber[800] : AppColors.forestGreen,
                ),
                const SizedBox(width: 4),
                Text(
                  tracking.isPaused ? 'PAUZA' : 'LIVE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: tracking.isPaused ? Colors.amber[800] : AppColors.forestGreen,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
      body: Column(
        children: [
          // OpenStreetMap Polyline Tracking with Heading Rotation
          Expanded(
            flex: 5,
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: displayCenter,
                        initialZoom: 17.0,
                        initialRotation: (360.0 - heading) % 360.0,
                        onMapReady: () {
                          if (mounted) {
                            setState(() {
                              _isMapReady = true;
                              _currentMapRotation = (360.0 - heading) % 360.0;
                            });
                          }
                        },
                        onPositionChanged: (camera, hasGesture) {
                          _currentMapRotation = camera.rotation;
                          if (hasGesture && _followHeading) {
                            setState(() => _followHeading = false);
                          }
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.capigo.weeklywalk',
                        ),
                        if (polylinePoints.length > 1)
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: polylinePoints,
                                strokeWidth: 5.0,
                                color: AppColors.forestGreen,
                              ),
                            ],
                          ),
                        if (currentPoint != null)
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: currentPoint,
                                width: 36,
                                height: 36,
                                child: Transform.rotate(
                                  // If following heading, the map is rotated so user points straight UP (0 rad).
                                  // Otherwise, orient arrow in the direction of heading relative to current map rotation.
                                  angle: _followHeading
                                      ? 0.0
                                      : ((heading + _currentMapRotation) * (pi / 180.0)),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.forestGreen,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 3),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 6,
                                          offset: Offset(0, 2),
                                        )
                                      ],
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.navigation_rounded,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),

                    // Floating Controls: Compass & Follow Bearing (Google Maps style)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Compass button: resets to North
                          GestureDetector(
                            onTap: () {
                              setState(() => _followHeading = false);
                              if (_isMapReady) {
                                try {
                                  _mapController.rotate(0.0);
                                  _currentMapRotation = 0.0;
                                } catch (_) {}
                              }
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 6,
                                    offset: Offset(0, 2),
                                  )
                                ],
                              ),
                              child: Center(
                                child: Transform.rotate(
                                  angle: -(_currentMapRotation * (pi / 180.0)),
                                  child: const Icon(
                                    Icons.explore_rounded,
                                    color: Colors.redAccent,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Follow / Center button
                          GestureDetector(
                            onTap: () {
                              setState(() => _followHeading = true);
                              if (currentPoint != null && _isMapReady) {
                                try {
                                  _mapController.moveAndRotate(
                                    currentPoint,
                                    17.0,
                                    (360.0 - heading) % 360.0,
                                  );
                                } catch (_) {}
                              }
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: _followHeading ? AppColors.forestGreen : Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 6,
                                    offset: Offset(0, 2),
                                  )
                                ],
                              ),
                              child: Center(
                                child: Icon(
                                  _followHeading ? Icons.navigation_rounded : Icons.my_location_rounded,
                                  color: _followHeading ? Colors.white : AppColors.textDark,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Camera button to snap photo from route
                          GestureDetector(
                            onTap: () async {
                              final picker = ImagePicker();
                              final source = await showModalBottomSheet<ImageSource>(
                                context: context,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                                ),
                                builder: (ctx) => SafeArea(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        ListTile(
                                          leading: const Icon(Icons.camera_alt_rounded, color: AppColors.forestGreen),
                                          title: const Text('Zrób zdjęcie na trasie', style: TextStyle(fontWeight: FontWeight.bold)),
                                          onTap: () => Navigator.pop(ctx, ImageSource.camera),
                                        ),
                                        ListTile(
                                          leading: const Icon(Icons.photo_library_rounded, color: AppColors.forestGreen),
                                          title: const Text('Wybierz z galerii', style: TextStyle(fontWeight: FontWeight.bold)),
                                          onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );

                              if (source != null) {
                                try {
                                  final XFile? file = await picker.pickImage(source: source, imageQuality: 85);
                                  if (file != null && mounted) {
                                    context.read<TrackingProvider>().addPhoto(file.path);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('📸 Dodano zdjęcie z trasy!'),
                                        duration: Duration(seconds: 2),
                                        backgroundColor: AppColors.forestGreen,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  debugPrint('Error taking photo: $e');
                                }
                              }
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 6,
                                    offset: Offset(0, 2),
                                  )
                                ],
                              ),
                              child: const Center(
                                child: Icon(Icons.camera_alt_rounded, color: AppColors.forestGreen, size: 20),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Photo count badge at bottom-left of map
                    if (tracking.currentPhotos.isNotEmpty)
                      Positioned(
                        bottom: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.photo_camera_rounded, color: Colors.white, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                '${tracking.currentPhotos.length}',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Loading overlay if waiting for initial GPS lock
                    if (currentPoint == null)
                      Container(
                        color: Colors.black26,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.forestGreen,
                                  ),
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Pobieranie Twojej lokalizacji GPS...',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Metrics Dashboard
          Expanded(
            flex: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Primary Duration & Distance
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMetric(
                        label: LocalizationService.tr('metric_time', lang),
                        value: tracking.formattedDuration,
                        unit: '',
                        isLarge: true,
                      ),
                      _buildMetric(
                        label: LocalizationService.tr('metric_distance', lang),
                        value: tracking.distanceKm.toStringAsFixed(2),
                        unit: 'km',
                        isLarge: true,
                        valueColor: AppColors.forestGreen,
                      ),
                    ],
                  ),
                  const Divider(color: AppColors.divider),
                  // Secondary Metrics (Kroki, Kadencja, Prędkość)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMetric(
                        label: LocalizationService.tr('metric_steps', lang),
                        value: tracking.steps.toString(),
                        unit: 'kr',
                      ),
                      _buildMetric(
                        label: LocalizationService.tr('metric_cadence', lang),
                        value: tracking.currentCadence.round().toString(),
                        unit: 'kr/min',
                      ),
                      _buildMetric(
                        label: LocalizationService.tr('metric_speed', lang),
                        value: tracking.currentSpeedKmh.toStringAsFixed(1),
                        unit: 'km/h',
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Controls: Pauza / Wznów & Stop
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        // Pause / Resume Button
                        Expanded(
                          child: SizedBox(
                            height: 56,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                if (tracking.isPaused) {
                                  tracking.resumeTracking();
                                } else {
                                  tracking.pauseTracking();
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: tracking.isPaused ? AppColors.forestGreen : Colors.amber[800],
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                              ),
                              icon: Icon(
                                tracking.isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                                size: 26,
                              ),
                              label: Text(
                                tracking.isPaused
                                    ? LocalizationService.tr('resume', lang)
                                    : LocalizationService.tr('pause', lang),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Stop Button
                        Expanded(
                          child: SizedBox(
                            height: 56,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final shouldStop = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                    title: Text(LocalizationService.tr('finish_walk_title', lang)),
                                    content: Text(LocalizationService.tr('finish_walk_desc', lang)),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx, false),
                                        child: Text(LocalizationService.tr('cancel', lang)),
                                      ),
                                      ElevatedButton(
                                        onPressed: () => Navigator.pop(ctx, true),
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                                        child: Text(LocalizationService.tr('finish', lang)),
                                      ),
                                    ],
                                  ),
                                );

                                if (shouldStop == true && context.mounted) {
                                  final congratulation = userProvider.getPersonalizedCongratulations(lang);
                                  final session = await tracking.stopTracking(
                                    tempoConfig: userProvider.profile.tempoConfig,
                                    congratulationMessage: congratulation,
                                    langCode: lang,
                                  );

                                  if (context.mounted) {
                                    if (session != null) {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => WorkoutReportScreen(session: session),
                                        ),
                                      );
                                    } else {
                                      Navigator.pop(context);
                                    }
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                              ),
                              icon: const Icon(Icons.stop_rounded, size: 26),
                              label: Text(
                                LocalizationService.tr('stop', lang),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetric({
    required String label,
    required String value,
    required String unit,
    bool isLarge = false,
    Color? valueColor,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: isLarge ? 36 : 22,
                fontWeight: FontWeight.w900,
                color: valueColor ?? AppColors.textDark,
                letterSpacing: -0.5,
              ),
            ),
            if (unit.isNotEmpty) ...[
              const SizedBox(width: 3),
              Text(
                unit,
                style: TextStyle(
                  fontSize: isLarge ? 14 : 12,
                  fontWeight: FontWeight.bold,
                  color: valueColor ?? AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
