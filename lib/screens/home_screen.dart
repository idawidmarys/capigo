import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/activity_session.dart';
import '../models/activity_type.dart';
import '../providers/tracking_provider.dart';
import '../providers/user_provider.dart';
import '../services/localization_service.dart';
import '../theme/app_colors.dart';
import '../widgets/circular_progress_clock.dart';
import 'active_workout_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';
import 'tempo_dialog.dart';
import 'workout_report_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final lang = userProvider.languageCode;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: IndexedStack(
          index: _currentTabIndex,
          children: [
            _buildWalkTab(context, userProvider, lang),
            const HistoryScreen(),
            const SettingsScreen(),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(
              color: AppColors.border,
              width: 1,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _currentTabIndex,
          backgroundColor: Colors.white,
          indicatorColor: AppColors.softGreenTint,
          surfaceTintColor: Colors.transparent,
          onDestinationSelected: (i) => setState(() => _currentTabIndex = i),
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.directions_walk_outlined, color: AppColors.textSecondary),
              selectedIcon: const Icon(Icons.directions_walk_rounded, color: AppColors.forestGreen),
              label: LocalizationService.tr('tab_walk', lang),
            ),
            NavigationDestination(
              icon: const Icon(Icons.history_outlined, color: AppColors.textSecondary),
              selectedIcon: const Icon(Icons.history_rounded, color: AppColors.forestGreen),
              label: LocalizationService.tr('tab_history', lang),
            ),
            NavigationDestination(
              icon: const Icon(Icons.settings_outlined, color: AppColors.textSecondary),
              selectedIcon: const Icon(Icons.settings_rounded, color: AppColors.forestGreen),
              label: LocalizationService.tr('tab_settings', lang),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalkTab(BuildContext context, UserProvider userProvider, String lang) {
    final profile = userProvider.profile;
    final currentKm = userProvider.currentWeekKm;
    final goalKm = profile.weeklyGoalKm;
    final progress = userProvider.weeklyProgress;
    final kmLeft = userProvider.kmLeftToGoal;
    final last3 = userProvider.last3Sessions;
    final tracking = context.watch<TrackingProvider>();

    return RefreshIndicator(
      onRefresh: () => userProvider.reloadSessions(),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          // Top Bar: Mini capybara logo + Weekly Walk + Tempo + Language flag
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.softGreenTint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/images/capigo_logo.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.pets,
                      size: 20,
                      color: AppColors.forestGreen,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                LocalizationService.tr('app_title', lang),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                  color: AppColors.textDark,
                ),
              ),
              const Spacer(),

              // Tempo Button
              GestureDetector(
                onTap: () => TempoSettingsDialog.show(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.border,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.speed, size: 14, color: AppColors.forestGreen),
                      SizedBox(width: 4),
                      Text(
                        'Tempo',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.forestGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Language Flag Dropdown
              PopupMenuButton<String>(
                initialValue: lang,
                onSelected: (code) => userProvider.setLanguage(code),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        LocalizationService.languageFlags[lang] ?? '🦫',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.arrow_drop_down, size: 16, color: AppColors.textSecondary),
                    ],
                  ),
                ),
                itemBuilder: (_) => LocalizationService.languageNames.entries.map((e) {
                  return PopupMenuItem(
                    value: e.key,
                    child: Row(
                      children: [
                        Text(LocalizationService.languageFlags[e.key] ?? '🦫', style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Text(e.value, style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Greeting Card with Capybara Avatar on the right
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${LocalizationService.tr('greeting_prefix', lang)}, ${profile.name}!',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      LocalizationService.tr('greeting_subtitle', lang),
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.softGreenTint,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.asset(
                    'assets/images/capigo_logo.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.pets,
                      size: 32,
                      color: AppColors.forestGreen,
                    ),
                  ),
                ),
              ),
            ],
          ),

          if (tracking.isTracking) ...[
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ActiveWorkoutScreen(),
                  ),
                );
                userProvider.reloadSessions();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: tracking.isPaused
                        ? [const Color(0xFFF57C00), const Color(0xFFFFB74D)]
                        : [AppColors.forestGreen, const Color(0xFF388E3C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: (tracking.isPaused ? const Color(0xFFF57C00) : AppColors.forestGreen)
                          .withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        tracking.isPaused ? Icons.pause_rounded : Icons.directions_walk_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: tracking.isPaused ? Colors.amberAccent : Colors.lightGreenAccent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                tracking.isPaused ? 'Spacer wstrzymany' : 'Spacer w toku',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${tracking.distanceKm.toStringAsFixed(2)} km  •  ${tracking.formattedDuration}  •  ${tracking.steps} kroków',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.95),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Streak / Regularity Card (One star, week streak counter)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(Icons.star_rounded, color: AppColors.streakOrange, size: 24),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${LocalizationService.tr('streak_prefix', lang)} ${profile.streakWeeks}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: AppColors.forestGreen,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${profile.streakWeeks}. ${LocalizationService.tr('streak_suffix', lang)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textSecondary),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Weekly Goal Card with Circular Progress Clock
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          LocalizationService.tr('weekly_goal_header', lang),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.9,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          LocalizationService.tr('current_week', lang),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => _showEditGoalDialog(context, goalKm),
                      child: Row(
                        children: [
                          Text(
                            LocalizationService.tr('edit', lang),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.forestGreen,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.edit_outlined, size: 14, color: AppColors.forestGreen),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Center: Circular Progress Clock that fills clockwise with every meter
                CircularProgressClock(
                  currentKm: currentKm,
                  goalKm: goalKm,
                  size: 170,
                ),

                const SizedBox(height: 22),

                // Bottom linear progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: AppColors.softGreenTint,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.forestGreen),
                  ),
                ),
                const SizedBox(height: 8),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      LocalizationService.tr('km_to_goal', lang, params: {'km': kmLeft.toStringAsFixed(1)}),
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.forestGreen,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Big Action Button: "Rozpocznij spacer" or "Wróć do aktywnego spaceru"
          SizedBox(
            width: double.infinity,
            child: Material(
              color: tracking.isTracking ? const Color(0xFF1E3A2F) : AppColors.forestGreen,
              borderRadius: BorderRadius.circular(22),
              elevation: 0,
              child: InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: () async {
                  if (tracking.isTracking) {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ActiveWorkoutScreen(),
                      ),
                    );
                    userProvider.reloadSessions();
                    return;
                  }

                  final navigator = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);

                  final success = await tracking.startTracking(ActivityType.walk);
                  if (!context.mounted) return;

                  if (success) {
                    await navigator.push(
                      MaterialPageRoute(
                        builder: (_) => const ActiveWorkoutScreen(),
                      ),
                    );
                    userProvider.reloadSessions();
                  } else {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Wymagany jest dostęp do lokalizacji GPS, aby rozpocząć spacer.'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tracking.isTracking
                                  ? (tracking.isPaused ? 'Spacer wstrzymany — Wróć do trasy' : 'Spacer w toku — Wróć do trasy')
                                  : LocalizationService.tr('start_walk', lang),
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              tracking.isTracking
                                  ? '${tracking.distanceKm.toStringAsFixed(2)} km  •  ${tracking.formattedDuration}'
                                  : LocalizationService.tr('start_walk_sub', lang),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          tracking.isTracking ? Icons.navigation_rounded : Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Ostatnie spacery header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                LocalizationService.tr('recent_walks', lang),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _currentTabIndex = 1),
                child: Text(
                  LocalizationService.tr('show_all_history', lang),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Last 3 walks timeline
          if (last3.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Center(
                child: Text(
                  LocalizationService.tr('no_walks_yet', lang),
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              ),
            )
          else
            ...List.generate(last3.length, (index) {
              final session = last3[index];
              final ActivitySession? previousSession = (index + 1 < last3.length) ? last3[index + 1] : null;
              final gapText = _formatGap(session.startTime, previousSession?.endTime);

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
                    child: _buildRecentWalkCard(session, lang),
                  ),
                  if (gapText.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        '⏱️ $gapText',
                        style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                      ),
                    )
                  else
                    const SizedBox(height: 8),
                ],
              );
            }),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildRecentWalkCard(ActivitySession session, String lang) {
    final int min = session.durationSeconds ~/ 60;
    final dateStr = _formatRelativeDate(session.startTime, lang);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.border,
        ),
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
              Icons.show_chart_rounded,
              color: AppColors.forestGreen,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateStr,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$min min • ${session.tempoName}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
        ],
      ),
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

  String _formatRelativeDate(DateTime time, String lang) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sessionDay = DateTime(time.year, time.month, time.day);
    final timeStr = DateFormat('HH:mm').format(time);

    if (sessionDay == today) {
      return '${LocalizationService.tr('today', lang)} • $timeStr';
    } else if (sessionDay == today.subtract(const Duration(days: 1))) {
      return '${LocalizationService.tr('yesterday', lang)} • $timeStr';
    } else {
      final weekday = DateFormat('EEEE', lang).format(time);
      return '${weekday[0].toUpperCase()}${weekday.substring(1)} • $timeStr';
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

  void _showEditGoalDialog(BuildContext context, double currentGoal) {
    double tempGoal = currentGoal;
    double maxGoal = currentGoal > 50 ? (currentGoal + 10) : 50.0;
    bool nextWeekOnly = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Edytuj cel tygodniowy'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${tempGoal.toInt()} km',
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.forestGreen),
              ),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: tempGoal.clamp(3.0, maxGoal),
                      min: 3,
                      max: maxGoal,
                      divisions: (maxGoal - 3).toInt(),
                      activeColor: AppColors.forestGreen,
                      onChanged: (v) => setDialogState(() => tempGoal = v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      setDialogState(() {
                        maxGoal += 10;
                        tempGoal += 5;
                      });
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: AppColors.softGreenTint,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.add_rounded, color: AppColors.forestGreen, size: 22),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Więcej',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.forestGreen),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Od przyszłego tygodnia', style: TextStyle(fontSize: 13)),
                value: nextWeekOnly,
                onChanged: (val) => setDialogState(() => nextWeekOnly = val ?? true),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Anuluj'),
            ),
            ElevatedButton(
              onPressed: () {
                context.read<UserProvider>().updateGoal(
                      newGoalKm: tempGoal,
                      forNextWeek: nextWeekOnly,
                    );
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.forestGreen),
              child: const Text('Zapisz'),
            ),
          ],
        ),
      ),
    );
  }
}
