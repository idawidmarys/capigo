import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../providers/tracking_provider.dart';
import '../providers/user_provider.dart';
import '../services/localization_service.dart';
import '../theme/app_colors.dart';
import 'workout_report_screen.dart';

class ActiveWorkoutScreen extends StatelessWidget {
  const ActiveWorkoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tracking = context.watch<TrackingProvider>();
    final userProvider = context.watch<UserProvider>();
    final lang = userProvider.languageCode;

    final List<LatLng> polylinePoints = tracking.routePoints
        .map((p) => LatLng(p.latitude, p.longitude))
        .toList();

    final LatLng centerPoint = polylinePoints.isNotEmpty
        ? polylinePoints.last
        : const LatLng(52.2297, 21.0122);

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
          // OpenStreetMap Polyline Tracking
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
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: centerPoint,
                    initialZoom: 16.5,
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
                    if (polylinePoints.isNotEmpty)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: polylinePoints.last,
                            width: 26,
                            height: 26,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.forestGreen,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 3),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  )
                                ],
                              ),
                            ),
                          ),
                        ],
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
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 1.0,
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
                fontSize: isLarge ? 32 : 20,
                fontWeight: FontWeight.w800,
                color: valueColor ?? AppColors.textDark,
              ),
            ),
            if (unit.isNotEmpty) ...[
              const SizedBox(width: 3),
              Text(
                unit,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
