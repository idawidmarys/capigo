import 'dart:io' show File;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/activity_session.dart';
import '../models/activity_type.dart';
import '../providers/user_provider.dart';
import '../services/localization_service.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';

class WorkoutReportScreen extends StatefulWidget {
  final ActivitySession session;

  const WorkoutReportScreen({super.key, required this.session});

  @override
  State<WorkoutReportScreen> createState() => _WorkoutReportScreenState();
}

class _WorkoutReportScreenState extends State<WorkoutReportScreen> {
  late List<String> _photos;

  @override
  void initState() {
    super.initState();
    _photos = List.from(widget.session.photoPaths);
  }

  Future<void> _pickAndAddPhoto() async {
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
                title: const Text('Zrób zdjęcie aparatem', style: TextStyle(fontWeight: FontWeight.bold)),
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
        final XFile? picked = await picker.pickImage(source: source, imageQuality: 85);
        if (picked != null) {
          setState(() {
            _photos.add(picked.path);
          });
          // Update stored session
          final updatedSession = ActivitySession(
            id: widget.session.id,
            type: widget.session.type,
            startTime: widget.session.startTime,
            endTime: widget.session.endTime,
            durationSeconds: widget.session.durationSeconds,
            distanceMeters: widget.session.distanceMeters,
            steps: widget.session.steps,
            averageCadence: widget.session.averageCadence,
            avgSpeedKmh: widget.session.avgSpeedKmh,
            tempoLevel: widget.session.tempoLevel,
            tempoName: widget.session.tempoName,
            calories: widget.session.calories,
            congratulationMessage: widget.session.congratulationMessage,
            route: widget.session.route,
            timeSeries: widget.session.timeSeries,
            photoPaths: List.from(_photos),
          );
          await StorageService.saveSession(updatedSession);
          if (mounted) {
            context.read<UserProvider>().reloadSessions();
          }
        }
      } catch (e) {
        debugPrint('Error picking photo: $e');
      }
    }
  }

  void _openFullScreenPhoto(String path) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          alignment: Alignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: InteractiveViewer(
                child: kIsWeb
                    ? Image.network(path, fit: BoxFit.contain)
                    : Image.file(File(path), fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 22),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<UserProvider>().languageCode;
    final int min = widget.session.durationSeconds ~/ 60;
    final int sec = widget.session.durationSeconds % 60;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('${LocalizationService.tr('report_title', lang)}: ${widget.session.type.displayNamePl}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          // 1. PHOTOS FROM ROUTE (At the very top as requested!)
          _buildPhotosSection(lang),

          const SizedBox(height: 18),

          // 2. Capybara Celebration Banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: AppColors.softGreenTint,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      'assets/images/capigo_logo.png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.pets,
                        size: 40,
                        color: AppColors.forestGreen,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        LocalizationService.tr('report_subtitle', lang),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.forestGreen,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.session.congratulationMessage,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textDark,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 3. Main Metrics Grid
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMetricCol(
                      label: LocalizationService.tr('metric_time', lang),
                      value: '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}',
                      unit: 'min',
                    ),
                    _buildMetricCol(
                      label: LocalizationService.tr('metric_distance', lang),
                      value: widget.session.distanceKm.toStringAsFixed(2),
                      unit: 'km',
                      valueColor: AppColors.forestGreen,
                    ),
                    _buildMetricCol(
                      label: LocalizationService.tr('metric_steps', lang),
                      value: widget.session.steps.toString(),
                      unit: 'kr',
                    ),
                  ],
                ),
                const Divider(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMetricCol(
                      label: LocalizationService.tr('metric_speed', lang),
                      value: widget.session.avgSpeedKmh.toStringAsFixed(1),
                      unit: 'km/h',
                    ),
                    _buildMetricCol(
                      label: LocalizationService.tr('metric_cadence', lang),
                      value: widget.session.averageCadence.round().toString(),
                      unit: 'kr/min',
                    ),
                    _buildMetricCol(
                      label: LocalizationService.tr('metric_calories', lang),
                      value: widget.session.calories.toString(),
                      unit: 'kcal',
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 4. Pace Tier Badge
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.softGreenTint,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: Icon(Icons.speed, color: AppColors.forestGreen, size: 24),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Średnie tempo: ${widget.session.tempoName}',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Średnie tempo: ${widget.session.averagePaceFormatted} min/km',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.softGreenTint,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Poziom ${widget.session.tempoLevel}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.forestGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 5. Chart: Dynamics over time
          if (widget.session.type != ActivityType.bike) ...[
            Text(
              LocalizationService.tr('chart_steps_title', lang),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            const SizedBox(height: 12),
            Container(
              height: 180,
              padding: const EdgeInsets.fromLTRB(10, 16, 20, 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border),
              ),
              child: _buildStepsChart(),
            ),
            const SizedBox(height: 24),
          ],

          // 6. Chart: Distance over time
          Text(
            LocalizationService.tr('chart_distance_title', lang),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
          ),
          const SizedBox(height: 12),
          Container(
            height: 180,
            padding: const EdgeInsets.fromLTRB(10, 16, 20, 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
            ),
            child: _buildDistanceChart(),
          ),

          const SizedBox(height: 32),

          // Save and return button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.forestGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              child: Text(
                LocalizationService.tr('save_and_return', lang),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // Top Photos Section
  Widget _buildPhotosSection(String lang) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.photo_camera_rounded, color: AppColors.forestGreen, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Zdjęcia z trasy (${_photos.length})',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: _pickAndAddPhoto,
                icon: const Icon(Icons.add_a_photo_rounded, size: 16, color: AppColors.forestGreen),
                label: const Text(
                  'Dodaj',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.forestGreen),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (_photos.isEmpty)
            GestureDetector(
              onTap: _pickAndAddPhoto,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: AppColors.softGreenTint.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.softGreenBorder, style: BorderStyle.solid),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.add_photo_alternate_outlined, size: 36, color: AppColors.forestGreen),
                    SizedBox(height: 6),
                    Text(
                      'Brak zdjęć z tej trasy',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Dotknij tutaj, aby dodać pamiątkowe zdjęcie',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            )
          else
            SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _photos.length + 1,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, idx) {
                  if (idx == _photos.length) {
                    // Add more button
                    return GestureDetector(
                      onTap: _pickAndAddPhoto,
                      child: Container(
                        width: 90,
                        decoration: BoxDecoration(
                          color: AppColors.softGreenTint,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.softGreenBorder),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_rounded, size: 28, color: AppColors.forestGreen),
                            SizedBox(height: 4),
                            Text(
                              'Dodaj',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.forestGreen),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final photoPath = _photos[idx];
                  return GestureDetector(
                    onTap: () => _openFullScreenPhoto(photoPath),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: SizedBox(
                            width: 120,
                            height: 120,
                            child: kIsWeb
                                ? Image.network(
                                    photoPath,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => Container(
                                      color: Colors.grey[200],
                                      child: const Icon(Icons.broken_image, color: Colors.grey),
                                    ),
                                  )
                                : Image.file(
                                    File(photoPath),
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => Container(
                                      color: Colors.grey[200],
                                      child: const Icon(Icons.broken_image, color: Colors.grey),
                                    ),
                                  ),
                          ),
                        ),
                        Positioned(
                          bottom: 6,
                          right: 6,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.black45,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 14),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMetricCol({
    required String label,
    required String value,
    required String unit,
    Color? valueColor,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
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
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: valueColor ?? AppColors.textDark,
                letterSpacing: -0.5,
              ),
            ),
            if (unit.isNotEmpty) ...[
              const SizedBox(width: 2),
              Text(
                unit,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildStepsChart() {
    final spots = <FlSpot>[];
    if (widget.session.timeSeries.isEmpty) {
      spots.add(const FlSpot(0, 0));
      spots.add(FlSpot((widget.session.durationSeconds / 60.0), widget.session.steps.toDouble()));
    } else {
      for (var point in widget.session.timeSeries) {
        spots.add(FlSpot(point.second / 60.0, point.steps.toDouble()));
      }
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => const FlLine(color: AppColors.divider, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              getTitlesWidget: (val, meta) => Text(
                '${val.toInt()}m',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
              ),
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (val, meta) => Text(
                val.toInt().toString(),
                style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
              ),
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.forestGreen,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.forestGreen.withValues(alpha: 0.15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistanceChart() {
    final spots = <FlSpot>[];
    if (widget.session.timeSeries.isEmpty) {
      spots.add(const FlSpot(0, 0));
      spots.add(FlSpot((widget.session.durationSeconds / 60.0), widget.session.distanceKm));
    } else {
      for (var point in widget.session.timeSeries) {
        spots.add(FlSpot(point.second / 60.0, point.distanceMeters / 1000.0));
      }
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => const FlLine(color: AppColors.divider, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              getTitlesWidget: (val, meta) => Text(
                '${val.toInt()}m',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
              ),
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (val, meta) => Text(
                '${val.toStringAsFixed(1)}k',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
              ),
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.streakOrange,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.streakOrange.withValues(alpha: 0.15),
            ),
          ),
        ],
      ),
    );
  }
}
