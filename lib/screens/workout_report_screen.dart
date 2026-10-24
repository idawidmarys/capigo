import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/activity_session.dart';
import '../providers/user_provider.dart';
import '../services/localization_service.dart';
import '../theme/app_colors.dart';

class WorkoutReportScreen extends StatelessWidget {
  final ActivitySession session;

  const WorkoutReportScreen({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<UserProvider>().languageCode;
    final int min = session.durationSeconds ~/ 60;
    final int sec = session.durationSeconds % 60;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(LocalizationService.tr('report_title', lang)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          // Capybara Celebration Banner
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
                        session.congratulationMessage,
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

          // Main Metrics Grid
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
                      value: session.distanceKm.toStringAsFixed(2),
                      unit: 'km',
                      valueColor: AppColors.forestGreen,
                    ),
                    _buildMetricCol(
                      label: LocalizationService.tr('metric_steps', lang),
                      value: session.steps.toString(),
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
                      value: session.avgSpeedKmh.toStringAsFixed(1),
                      unit: 'km/h',
                    ),
                    _buildMetricCol(
                      label: LocalizationService.tr('metric_cadence', lang),
                      value: session.averageCadence.round().toString(),
                      unit: 'kr/min',
                    ),
                    _buildMetricCol(
                      label: LocalizationService.tr('metric_calories', lang),
                      value: session.calories.toString(),
                      unit: 'kcal',
                      valueColor: AppColors.streakOrange,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Tempo tier rating badge & algorithm explanation
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.softGreenTint,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.forestGreen,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Stopień ${session.tempoLevel}/5',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tempo: ${session.tempoName}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Wyliczone algorytmem biorącym najniższy wskaźnik (prędkość / kadencja) dla precyzyjnego spalania kalorii.',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Chart 1: Time vs. Steps
          Text(
            LocalizationService.tr('chart_steps_title', lang),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 12),
          _buildChartContainer(
            child: _buildStepsChart(),
          ),

          const SizedBox(height: 24),

          // Chart 2: Time vs. Distance
          Text(
            LocalizationService.tr('chart_distance_title', lang),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 12),
          _buildChartContainer(
            child: _buildDistanceChart(),
          ),

          const SizedBox(height: 32),

          // Return button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                context.read<UserProvider>().reloadSessions();
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.forestGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: Text(
                LocalizationService.tr('save_and_return', lang),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 20),
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
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 0.8,
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
              ),
            ),
            const SizedBox(width: 3),
            Text(
              unit,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChartContainer({required Widget child}) {
    return Container(
      height: 200,
      padding: const EdgeInsets.only(top: 20, right: 20, left: 12, bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }

  Widget _buildStepsChart() {
    final spots = <FlSpot>[];
    if (session.timeSeries.isEmpty) {
      spots.add(const FlSpot(0, 0));
      spots.add(FlSpot((session.durationSeconds / 60.0), session.steps.toDouble()));
    } else {
      for (var point in session.timeSeries) {
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
    if (session.timeSeries.isEmpty) {
      spots.add(const FlSpot(0, 0));
      spots.add(FlSpot((session.durationSeconds / 60.0), session.distanceKm));
    } else {
      for (var point in session.timeSeries) {
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
