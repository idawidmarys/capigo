import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../models/habit_item.dart';
import '../providers/user_provider.dart';
import '../services/localization_service.dart';
import '../theme/app_colors.dart';
import '../widgets/time_input_dialog.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onFinished;

  const OnboardingScreen({super.key, required this.onFinished});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final TextEditingController _nameController = TextEditingController(text: 'Maja');
  double _weeklyGoalKm = 12.0;
  double _maxGoalKm = 50.0;

  late List<HabitItem> _habits;

  @override
  void initState() {
    super.initState();
    _habits = HabitItem.defaultHabits();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _pickTimeForHabit(int index) async {
    final initial = _habits[index].triggerTime ?? const TimeOfDay(hour: 18, minute: 0);
    final picked = await TimeInputDialog.show(context, initialTime: initial);
    if (picked != null) {
      setState(() {
        _habits[index] = _habits[index].copyWith(triggerTime: picked, isEnabled: true);
      });
    }
  }

  void _addCustomHabit() {
    final customController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Inny zaplanowany spacer'),
        content: TextField(
          controller: customController,
          decoration: const InputDecoration(
            hintText: 'np. Spacer po obiedzie, spacer z partnerem',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Anuluj'),
          ),
          ElevatedButton(
            onPressed: () {
              final text = customController.text.trim();
              if (text.isNotEmpty) {
                setState(() {
                  _habits.add(HabitItem(
                    id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                    titlePl: text,
                    titleEn: text,
                    titleDe: text,
                    titleEs: text,
                    promptPl: 'Czas na Twój zaplanowany spacer: $text!',
                    promptEn: 'Time for your scheduled walk: $text!',
                    promptDe: 'Zeit für deinen geplanten Spaziergang: $text!',
                    promptEs: '¡Hora de tu paseo programado: $text!',
                    triggerTime: const TimeOfDay(hour: 17, minute: 0),
                    isCustom: true,
                  ));
                });
              }
              Navigator.pop(ctx);
            },
            child: const Text('Dodaj'),
          ),
        ],
      ),
    );
  }

  Future<void> _requestPermissionsAndFinish() async {
    // Request location & activity recognition
    try {
      await [
        Permission.location,
        Permission.activityRecognition,
      ].request();
    } catch (_) {
      // Handled gracefully
    }

    if (mounted) {
      await context.read<UserProvider>().completeOnboarding(
            name: _nameController.text,
            weeklyGoalKm: _weeklyGoalKm,
            habits: _habits,
          );
      widget.onFinished();
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<UserProvider>().languageCode;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Progress Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                children: List.generate(3, (index) {
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 6,
                      decoration: BoxDecoration(
                        color: index <= _currentPage ? AppColors.forestGreen : AppColors.softGreenTint,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  );
                }),
              ),
            ),

            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  _buildStep1NameAndGoal(lang),
                  _buildStep2Habits(lang),
                  _buildStep3Permissions(lang),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Step 1: Name and Weekly Goal
  Widget _buildStep1NameAndGoal(String lang) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.softGreenTint,
                borderRadius: BorderRadius.circular(28),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Image.asset(
                  'assets/images/capigo_logo.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.pets,
                    size: 54,
                    color: AppColors.forestGreen,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              LocalizationService.tr('onboarding_welcome', lang),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              LocalizationService.tr('onboarding_sub', lang),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 32),

          // Name field
          Text(
            LocalizationService.tr('enter_name', lang),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              prefixIcon: const Icon(Icons.person_outline, color: AppColors.forestGreen),
            ),
          ),

          const SizedBox(height: 28),

          // Goal slider
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                LocalizationService.tr('weekly_goal_km', lang),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark),
              ),
              Text(
                '${_weeklyGoalKm.toInt()} km',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.forestGreen,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _weeklyGoalKm.clamp(3.0, _maxGoalKm),
                  min: 3,
                  max: _maxGoalKm,
                  divisions: (_maxGoalKm - 3).toInt(),
                  activeColor: AppColors.forestGreen,
                  inactiveColor: AppColors.softGreenTint,
                  onChanged: (v) => setState(() => _weeklyGoalKm = v),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _maxGoalKm += 10;
                    _weeklyGoalKm += 5;
                  });
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.softGreenTint,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.softGreenBorder),
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: AppColors.forestGreen,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lang == 'pl' ? 'Więcej' : 'More',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.forestGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const Spacer(),

          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.forestGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              child: Text(
                LocalizationService.tr('next', lang),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Step 2: Habits questionnaire
  Widget _buildStep2Habits(String lang) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            LocalizationService.tr('habits_title', lang),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark),
          ),
          const SizedBox(height: 4),
          Text(
            LocalizationService.tr('habits_sub', lang),
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),

          Expanded(
            child: ListView.separated(
              itemCount: _habits.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (ctx, i) {
                final habit = _habits[i];
                final hasTime = habit.triggerTime != null;

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              habit.getLocalizedTitle(lang),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '"${habit.getLocalizedPrompt(lang)}"',
                              style: const TextStyle(
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Time or N/A Selector
                      GestureDetector(
                        onTap: () => _pickTimeForHabit(i),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: hasTime ? AppColors.softGreenTint : AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: hasTime ? AppColors.forestGreen : AppColors.border,
                            ),
                          ),
                          child: Text(
                            hasTime ? habit.triggerTime!.format(context) : LocalizationService.tr('not_applicable', lang),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: hasTime ? AppColors.forestGreen : AppColors.textMuted,
                            ),
                          ),
                        ),
                      ),

                      if (hasTime)
                        IconButton(
                          icon: const Icon(Icons.close, size: 16, color: AppColors.textMuted),
                          onPressed: () {
                            setState(() {
                              _habits[i] = _habits[i].copyWith(clearTime: true);
                            });
                          },
                        ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Add Custom Walk button
          Center(
            child: TextButton.icon(
              onPressed: _addCustomHabit,
              icon: const Icon(Icons.add, color: AppColors.forestGreen),
              label: Text(
                LocalizationService.tr('add_custom_walk', lang),
                style: const TextStyle(color: AppColors.forestGreen, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 10),

          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.forestGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              child: Text(
                LocalizationService.tr('next', lang),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Step 3: Permissions Screen
  Widget _buildStep3Permissions(String lang) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: AppColors.softGreenTint,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.directions_walk_rounded,
              size: 64,
              color: AppColors.forestGreen,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            LocalizationService.tr('permissions_title', lang),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            LocalizationService.tr('permissions_desc', lang),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 58,
            child: ElevatedButton(
              onPressed: _requestPermissionsAndFinish,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.forestGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              child: Text(
                LocalizationService.tr('grant_permissions', lang),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
