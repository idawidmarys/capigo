import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/activity_session.dart';
import '../providers/user_provider.dart';
import '../services/localization_service.dart';
import '../theme/app_colors.dart';
import 'workout_report_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
  }

  void _prevMonth() {
    final now = DateTime.now();
    final oneYearAgo = DateTime(now.year - 1, now.month);
    final prev = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    if (prev.isAfter(oneYearAgo) || prev.isAtSameMomentAs(oneYearAgo)) {
      setState(() => _selectedMonth = prev);
    }
  }

  void _nextMonth() {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);
    final next = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    if (next.isBefore(currentMonth) || next.isAtSameMomentAs(currentMonth)) {
      setState(() => _selectedMonth = next);
    }
  }

  String _formatGap(DateTime current, DateTime? previous) {
    if (previous == null) return '';
    final diff = current.difference(previous).abs();
    if (diff.inDays > 0) {
      final hours = diff.inHours % 24;
      return '${diff.inDays}d ${hours}h odstępu';
    } else if (diff.inHours > 0) {
      final mins = diff.inMinutes % 60;
      return '${diff.inHours}h ${mins}m odstępu';
    } else {
      return '${diff.inMinutes}m odstępu';
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final lang = userProvider.languageCode;
    final allSessions = userProvider.allSessions;

    // Filter sessions for selected month
    final monthSessions = allSessions.where((s) {
      return s.startTime.year == _selectedMonth.year && s.startTime.month == _selectedMonth.month;
    }).toList();

    // Monthly aggregates
    final double totalKm = monthSessions.fold(0.0, (sum, s) => sum + s.distanceKm);
    final int totalSeconds = monthSessions.fold(0, (sum, s) => sum + s.durationSeconds);
    final int totalHours = totalSeconds ~/ 3600;
    final int totalMinutes = (totalSeconds % 3600) ~/ 60;
    final int totalCalories = monthSessions.fold(0, (sum, s) => sum + s.calories);

    final monthName = DateFormat.yMMMM(lang).format(_selectedMonth);
    final now = DateTime.now();
    final canGoNext = _selectedMonth.isBefore(DateTime(now.year, now.month));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          LocalizationService.tr('full_history_title', lang),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          // Month Selector Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_rounded, size: 18, color: AppColors.textDark),
                  onPressed: _prevMonth,
                ),
                Text(
                  monthName[0].toUpperCase() + monthName.substring(1),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 18,
                    color: canGoNext ? AppColors.textDark : AppColors.textMuted,
                  ),
                  onPressed: canGoNext ? _nextMonth : null,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Monthly Summary Banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.softGreenTint,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.forestGreen.withValues(alpha: 0.15)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                  context: context,
                  value: totalKm.toStringAsFixed(1),
                  unit: 'km',
                  label: LocalizationService.tr('total_distance', lang),
                ),
                Container(width: 1, height: 36, color: AppColors.forestGreen.withValues(alpha: 0.2)),
                _buildSummaryItem(
                  context: context,
                  value: totalHours > 0 ? '${totalHours}h ${totalMinutes}m' : '${totalMinutes}m',
                  unit: '',
                  label: LocalizationService.tr('total_time', lang),
                ),
                Container(width: 1, height: 36, color: AppColors.forestGreen.withValues(alpha: 0.2)),
                _buildSummaryItem(
                  context: context,
                  value: '$totalCalories',
                  unit: 'kcal',
                  label: LocalizationService.tr('calories', lang),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Timeline / List of walks
          if (monthSessions.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 48, color: AppColors.textMuted),
                  const SizedBox(height: 12),
                  Text(
                    LocalizationService.tr('no_walks_month', lang),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Wybierz inny miesiąc lub rozpocznij spacer.',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            )
          else
            ...List.generate(monthSessions.length, (index) {
              final session = monthSessions[index];
              final ActivitySession? previousSession =
                  (index + 1 < monthSessions.length) ? monthSessions[index + 1] : null;
              final gapText = _formatGap(session.startTime, previousSession?.endTime);
              final min = session.durationSeconds ~/ 60;
              final dateStr = DateFormat('dd.MM.yyyy • HH:mm').format(session.startTime);

              return Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => WorkoutReportScreen(session: session),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.border,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.softGreenTint,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.directions_walk_rounded,
                              color: AppColors.forestGreen,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  dateStr,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '$min min • ${session.tempoName}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${session.calories} kcal',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.forestGreen,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${session.distanceKm.toStringAsFixed(1)} km',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.redAccent),
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(),
                            tooltip: lang == 'pl' ? 'Usuń spacer' : 'Delete walk',
                            onPressed: () => _confirmDeleteSession(context, session, lang),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
                        ],
                      ),
                    ),
                  ),

                  // Gap indicator between walks
                  if (gapText.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.border.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '⏱️ $gapText',
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    const SizedBox(height: 10),
                ],
              );
            }),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required BuildContext context,
    required String value,
    required String unit,
    required String label,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.forestGreen,
              ),
            ),
            if (unit.isNotEmpty) ...[
              const SizedBox(width: 2),
              Text(
                unit,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.forestGreen,
                ),
              ),
            ]
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  void _confirmDeleteSession(BuildContext context, ActivitySession session, String lang) {
    final dateStr = DateFormat('dd.MM.yyyy HH:mm').format(session.startTime);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(lang == 'pl' ? 'Usunąć spacer?' : 'Delete walk?'),
        content: Text(
          lang == 'pl'
              ? 'Czy na pewno chcesz usunąć spacer z $dateStr (${session.distanceKm.toStringAsFixed(1)} km)?'
              : 'Are you sure you want to delete the walk from $dateStr (${session.distanceKm.toStringAsFixed(1)} km)?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(lang == 'pl' ? 'Anuluj' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<UserProvider>().deleteSession(session.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(lang == 'pl' ? 'Spacer został usunięty.' : 'Walk deleted.'),
                  backgroundColor: Colors.redAccent,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: Text(lang == 'pl' ? 'Usuń' : 'Delete'),
          ),
        ],
      ),
    );
  }
}
