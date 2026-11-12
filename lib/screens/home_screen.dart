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
    final currentType = userProvider.activeActivityType;

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
              icon: Icon(currentType.icon, color: AppColors.textSecondary),
              selectedIcon: Icon(currentType.icon, color: AppColors.forestGreen),
              label: currentType.displayNamePl,
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
    final currentType = userProvider.activeActivityType;
    final currentKm = userProvider.currentWeekKm;
    final goalKm = userProvider.currentModeWeeklyGoal;
    final progress = userProvider.weeklyProgress;
    final kmLeft = userProvider.kmLeftToGoal;
    final recentSessions = userProvider.recentSessions;
    final tracking = context.watch<TrackingProvider>();

    return RefreshIndicator(
      onRefresh: () => userProvider.reloadSessions(),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          // Top Bar: Mini capybara logo + Tryb: [Mode] with 3 dots edit button + Tempo + Language
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

              // Mode pill with 3 dots to edit/switch mode anytime (Requirement 5 & 6)
              Flexible(
                child: GestureDetector(
                  onTap: () => _showModeSelector(context, userProvider),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(currentType.icon, size: 16, color: currentType.color),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Tryb: ${currentType.displayNamePl}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                              color: AppColors.textDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.more_vert_rounded, size: 18, color: AppColors.textSecondary),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Tempo Button
              GestureDetector(
                onTap: () => TempoSettingsDialog.show(context, mode: currentType),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.border,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.speed, size: 14, color: currentType.color),
                      const SizedBox(width: 4),
                      Text(
                        'Tempo',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: currentType.color,
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
                      'Gotowy na dzisiejszy ${currentType.actionVerbPl}?',
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
                        tracking.isPaused ? Icons.pause_rounded : tracking.currentType.icon,
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
                                tracking.isPaused ? 'Trening wstrzymany' : '${tracking.currentType.displayNamePl} w toku',
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

          // Streak / Regularity Card (Requirement 1: accurate streak counting)
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
                  child: Text(
                    currentType.streakText(profile.streakWeeks, lang),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (progress >= 1.0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.softGreenTint,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Cel zaliczony! 🏆',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.forestGreen),
                    ),
                  )
                else
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
                          '${LocalizationService.tr('weekly_goal_header', lang)} (${currentType.displayNamePl.toUpperCase()})',
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
                      onTap: () => _showEditGoalDialog(context, goalKm, currentType),
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
                    valueColor: AlwaysStoppedAnimation<Color>(currentType.color),
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
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: currentType.color,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Big Action Button: "Rozpocznij spacer/bieg/rower" or "Wróć do aktywnego treningu"
          SizedBox(
            width: double.infinity,
            child: Material(
              color: tracking.isTracking ? const Color(0xFF1E3A2F) : currentType.color,
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

                  final success = await tracking.startTracking(currentType);
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
                        content: Text('Wymagany jest dostęp do lokalizacji GPS, aby rozpocząć aktywność.'),
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
                                  ? (tracking.isPaused ? 'Trening wstrzymany — Wróć do trasy' : 'Trening w toku — Wróć do trasy')
                                  : currentType.startButtonTextPl,
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
                                  : 'Każdy krok przybliża Cię do celu',
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

          // Header for recent activities with toggle (Requirement 8)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ostatnie aktywności',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              // Toggle: Only current mode vs All activities
              GestureDetector(
                onTap: () => userProvider.toggleAllActivitiesFilter(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: userProvider.showAllActivities ? AppColors.softGreenTint : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: userProvider.showAllActivities ? AppColors.forestGreen : AppColors.border,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        userProvider.showAllActivities ? Icons.apps_rounded : currentType.icon,
                        size: 13,
                        color: userProvider.showAllActivities ? AppColors.forestGreen : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        userProvider.showAllActivities ? 'Wszystkie' : 'Tylko ${currentType.displayNamePl}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: userProvider.showAllActivities ? AppColors.forestGreen : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Recent activities timeline
          if (recentSessions.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Center(
                child: Text(
                  userProvider.showAllActivities
                      ? 'Brak zapisanych aktywności'
                      : 'Brak zapisanych aktywności w trybie ${currentType.displayNamePl}',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              ),
            )
          else
            ...List.generate(recentSessions.length, (index) {
              final session = recentSessions[index];
              final ActivitySession? previousSession =
                  (index + 1 < recentSessions.length) ? recentSessions[index + 1] : null;
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

  // Modal to switch mode anytime (Requirement 5 & 6)
  void _showModeSelector(BuildContext context, UserProvider userProvider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Zmień tryb aktywności',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textDark),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...ActivityType.userSelectableModes.map((mode) {
                  final isCurrent = userProvider.activeActivityType == mode;
                  final goal = userProvider.profile.getGoalForMode(mode);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isCurrent ? AppColors.softGreenTint : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isCurrent ? AppColors.forestGreen : AppColors.border,
                        width: isCurrent ? 2 : 1,
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

  // Prompt goal dialog on first time entering a new mode (Requirement 6)
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
              Slider(
                value: goal.clamp(2.0, maxGoal),
                min: 2,
                max: maxGoal,
                divisions: (maxGoal - 2).toInt(),
                activeColor: AppColors.forestGreen,
                inactiveColor: AppColors.softGreenTint,
                onChanged: (v) => setDlgState(() => goal = v),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await userProvider.setGoalForMode(mode, goal);
                await userProvider.setActiveActivityType(mode);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.forestGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Zapisz i zacznij', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        ),
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
              color: session.type.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              session.type.icon,
              color: session.type.color,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      dateStr,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    if (session.photoPaths.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.softGreenTint,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.photo_camera_rounded, size: 10, color: AppColors.forestGreen),
                            const SizedBox(width: 2),
                            Text(
                              '${session.photoPaths.length}',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.forestGreen),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '$min min • ${session.tempoName} • ${session.calories} kcal',
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
            tooltip: lang == 'pl' ? 'Usuń aktywność' : 'Delete activity',
            onPressed: () => _confirmDeleteSession(context, session, lang),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteSession(BuildContext context, ActivitySession session, String lang) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(lang == 'pl' ? 'Usunąć aktywność?' : 'Delete activity?'),
        content: Text(
          lang == 'pl'
              ? 'Czy na pewno chcesz usunąć tę aktywność (${session.distanceKm.toStringAsFixed(2)} km) z historii? Ta operacja jest nieodwracalna.'
              : 'Are you sure you want to delete this activity (${session.distanceKm.toStringAsFixed(2)} km)? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(LocalizationService.tr('cancel', lang)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<UserProvider>().deleteSession(session.id);
            },
            child: Text(lang == 'pl' ? 'Usuń' : 'Delete', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _formatGap(DateTime current, DateTime? previous) {
    if (previous == null) return '';
    final diff = current.difference(previous).abs();
    if (diff.inDays > 0) {
      final hours = diff.inHours % 24;
      return '$diff.inDays d $hours h odstępu';
    } else if (diff.inHours > 0) {
      final mins = diff.inMinutes % 60;
      return '$diff.inHours h $mins m odstępu';
    } else {
      return '$diff.inMinutes m odstępu';
    }
  }

  String _formatRelativeDate(DateTime date, String lang) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateDay = DateTime(date.year, date.month, date.day);

    if (dateDay == today) {
      final timeStr = DateFormat('HH:mm').format(date);
      return '${LocalizationService.tr('today', lang)}, $timeStr';
    }
    final yesterday = today.subtract(const Duration(days: 1));
    if (dateDay == yesterday) {
      final timeStr = DateFormat('HH:mm').format(date);
      return '${LocalizationService.tr('yesterday', lang)}, $timeStr';
    }
    return DateFormat('dd.MM, HH:mm').format(date);
  }

  void _showEditGoalDialog(BuildContext context, double currentGoal, ActivityType mode) {
    double tempGoal = currentGoal;
    double maxGoal = mode == ActivityType.bike ? 150.0 : 60.0;
    final userProvider = context.read<UserProvider>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text('Cel tygodniowy: ${mode.displayNamePl}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${tempGoal.toInt()} km',
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  color: AppColors.forestGreen,
                ),
              ),
              const SizedBox(height: 16),
              Slider(
                value: tempGoal.clamp(2.0, maxGoal),
                min: 2,
                max: maxGoal,
                divisions: (maxGoal - 2).toInt(),
                activeColor: AppColors.forestGreen,
                inactiveColor: AppColors.softGreenTint,
                onChanged: (v) => setDlgState(() => tempGoal = v),
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
                userProvider.setGoalForMode(mode, tempGoal);
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.forestGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Zapisz', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
