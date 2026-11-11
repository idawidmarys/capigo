import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/activity_session.dart';
import '../models/activity_type.dart';
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
    final ActivityType activeType = userProvider.activeActivityType;

    // Filter sessions for selected mode / all
    final filteredSessions = userProvider.showAllActivities
        ? allSessions
        : allSessions.where((s) => s.type == activeType).toList();

    // Filter sessions for selected month
    final monthSessions = filteredSessions.where((s) {
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
          // Active Mode indicator & All activities filter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _showModeSelector(context, userProvider),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: activeType.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(activeType.icon, size: 18, color: activeType.color),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Tryb: ${activeType.displayNamePl}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: activeType.color,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(Icons.more_vert_rounded, size: 18, color: activeType.color),
                    ],
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: () => userProvider.toggleAllActivitiesFilter(),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: userProvider.showAllActivities
                          ? AppColors.forestGreen
                          : AppColors.softGreenTint,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          userProvider.showAllActivities ? Icons.filter_alt_off : Icons.filter_alt,
                          size: 13,
                          color: userProvider.showAllActivities ? Colors.white : AppColors.forestGreen,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          userProvider.showAllActivities
                              ? LocalizationService.tr('all_activities', lang)
                              : activeType.displayNamePl,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: userProvider.showAllActivities ? Colors.white : AppColors.forestGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

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
                    lang == 'pl'
                        ? 'Wybierz inny miesiąc lub rozpocznij aktywność.'
                        : 'Choose another month or start an activity.',
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
                              color: session.type.color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              session.type.icon,
                              color: session.type.color,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      dateStr,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textDark,
                                      ),
                                    ),
                                    if (session.photoPaths.isNotEmpty) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.shade100,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Text('📸', style: TextStyle(fontSize: 10)),
                                            const SizedBox(width: 2),
                                            Text(
                                              '${session.photoPaths.length}',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.amber.shade900,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${session.type.displayNamePl} • $min min • ${session.tempoName}',
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
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: session.type.color,
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
                            tooltip: lang == 'pl' ? 'Usuń aktywność' : 'Delete activity',
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
    final actName = session.type.displayNamePl.toLowerCase();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(lang == 'pl' ? 'Usunąć $actName?' : 'Delete ${session.type.name}?'),
        content: Text(
          lang == 'pl'
              ? 'Czy na pewno chcesz usunąć $actName z $dateStr (${session.distanceKm.toStringAsFixed(1)} km)?'
              : 'Are you sure you want to delete ${session.type.name} from $dateStr (${session.distanceKm.toStringAsFixed(1)} km)?',
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
                  content: Text(lang == 'pl' ? 'Aktywność została usunięta.' : 'Activity deleted.'),
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

  void _showModeSelector(BuildContext context, UserProvider userProvider) {
    final currentType = userProvider.activeActivityType;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.tune_rounded, color: AppColors.forestGreen),
                    SizedBox(width: 8),
                    Text(
                      'Wybierz tryb aktywności',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Zmień dyscyplinę w dowolnym momencie. Każdy tryb ma swój własny cel tygodniowy.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                ...ActivityType.userSelectableModes.map((mode) {
                  final isCurrent = mode == currentType;
                  final goal = userProvider.profile.getGoalForMode(mode);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isCurrent ? AppColors.softGreenTint : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isCurrent ? AppColors.forestGreen : AppColors.border,
                        width: isCurrent ? 1.5 : 1.0,
                      ),
                    ),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: mode.color.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(mode.icon, color: mode.color, size: 22),
                      ),
                      title: Text(
                        mode.displayNamePl,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isCurrent ? AppColors.forestGreen : AppColors.textDark,
                        ),
                      ),
                      subtitle: Text(
                        'Tygodniowy cel: ${goal.toInt()} km',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: isCurrent
                          ? const Icon(Icons.check_circle_rounded, color: AppColors.forestGreen)
                          : const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
                      onTap: () async {
                        Navigator.pop(ctx);
                        if (isCurrent) return;

                        if (!userProvider.hasGoalForMode(mode)) {
                          await _showFirstTimeGoalDialog(context, userProvider, mode);
                        } else {
                          await userProvider.setActiveActivityType(mode);
                        }
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showFirstTimeGoalDialog(BuildContext context, UserProvider userProvider, ActivityType mode) async {
    double goal = mode.defaultGoalKm;
    double maxGoal = mode == ActivityType.bike ? 150.0 : 60.0;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Icon(mode.icon, color: mode.color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tygodniowy cel: ${mode.displayNamePl}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'To Twoje pierwsze wejście w ten tryb. Ustaw ile kilometrów tygodniowo chcesz pokonać:',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              Text(
                '${goal.toInt()} km',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: AppColors.forestGreen,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: goal.clamp(1.0, maxGoal),
                      min: 1,
                      max: maxGoal,
                      divisions: (maxGoal - 1).toInt(),
                      activeColor: AppColors.forestGreen,
                      onChanged: (val) => setDlgState(() => goal = val),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      setDlgState(() {
                        maxGoal += 20;
                        goal += 10;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.softGreenTint,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        '+ Więcej',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.forestGreen,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Anuluj'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await userProvider.setGoalForMode(mode, goal);
                await userProvider.setActiveActivityType(mode);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.forestGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Zatwierdź cel'),
            ),
          ],
        ),
      ),
    );
  }
}
