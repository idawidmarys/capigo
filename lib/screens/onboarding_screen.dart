import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../models/activity_type.dart';
import '../models/habit_item.dart';
import '../providers/user_provider.dart';
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
  ActivityType _selectedMode = ActivityType.walk;
  double _weeklyGoalKm = 12.0;
  double _maxGoalKm = 50.0;

  late List<HabitItem> _habits;

  @override
  void initState() {
    super.initState();
    _habits = HabitItem.defaultHabitsForMode(_selectedMode);
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

  void _onModeSelected(ActivityType type) {
    setState(() {
      _selectedMode = type;
      _weeklyGoalKm = type.defaultGoalKm;
      _maxGoalKm = type == ActivityType.bike ? 120.0 : 50.0;
      _habits = HabitItem.defaultHabitsForMode(type);
    });
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
        title: Text('Własny powód (${_selectedMode.displayNamePl})'),
        content: TextField(
          controller: customController,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'np. Wyjście po obiedzie, wspólny trening',
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
                    promptPl: 'Czas na aktywność: $text!',
                    promptEn: 'Time for your scheduled workout: $text!',
                    promptDe: 'Zeit für deine geplante Aktivität: $text!',
                    promptEs: '¡Hora de tu actividad programada: $text!',
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
    try {
      await [
        Permission.location,
        Permission.activityRecognition,
        Permission.notification,
      ].request();
    } catch (_) {}

    if (mounted) {
      await context.read<UserProvider>().completeOnboarding(
            name: _nameController.text.trim().isEmpty ? 'Maja' : _nameController.text.trim(),
            activityType: _selectedMode,
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
            // Top Progress Bar (5 Steps)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                children: List.generate(5, (index) {
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
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
                  _buildStep1Name(lang),
                  _buildStep2Mode(lang),
                  _buildStep3Goal(lang),
                  _buildStep4Habits(lang),
                  _buildStep5Permissions(lang),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Step 1: Info & Name
  Widget _buildStep1Name(String lang) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppColors.softGreenTint,
                borderRadius: BorderRadius.circular(26),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: Image.asset(
                  'assets/images/capigo_logo.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.pets,
                    size: 48,
                    color: AppColors.forestGreen,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'CapiGo',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
                color: AppColors.textDark,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Required text at top
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.softGreenTint,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.forestGreen.withValues(alpha: 0.15)),
            ),
            child: const Row(
              children: [
                Icon(Icons.eco_rounded, color: AppColors.forestGreen, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Aplikacja, która naturalnie zachęca do regularnej aktywności fizycznej.',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.forestGreen,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Name field with automatic first capital letter
          const Text(
            'Twoje imię',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words, // Capital first letter
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              hintText: 'Wpisz swoje imię',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              prefixIcon: const Icon(Icons.person_outline, color: AppColors.forestGreen),
            ),
          ),

          const SizedBox(height: 48),

          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                if (_nameController.text.trim().isEmpty) {
                  _nameController.text = 'Maja';
                }
                _nextPage();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.forestGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Dalej', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, color: Colors.white),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Step 2: Mode selection (Spacer, Bieg, Rower, Nordic walking)
  Widget _buildStep2Mode(String lang) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Wybierz główną aktywność',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.textDark),
          ),
          const SizedBox(height: 6),
          const Text(
            'Z jakiej formy ruchu chcesz zacząć korzystać? Tryb możesz zmienić w każdej chwili jednym kliknięciem.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.35),
          ),
          const SizedBox(height: 24),

          ...ActivityType.userSelectableModes.map((mode) {
            final isSelected = _selectedMode == mode;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: isSelected ? AppColors.softGreenTint : Colors.white,
                borderRadius: BorderRadius.circular(20),
                elevation: isSelected ? 0 : 0.5,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => _onModeSelected(mode),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? AppColors.forestGreen : AppColors.border,
                        width: isSelected ? 2.0 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: mode.color.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(mode.icon, color: mode.color, size: 26),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                mode.displayNamePl,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? AppColors.forestGreen : AppColors.textDark,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Domyślny cel: ${mode.defaultGoalKm.toInt()} km/tydzień',
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                          color: isSelected ? AppColors.forestGreen : AppColors.textMuted,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.forestGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Dalej', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, color: Colors.white),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Step 3: Goal for chosen mode
  Widget _buildStep3Goal(String lang) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_selectedMode.icon, color: _selectedMode.color, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Tygodniowy cel: ${_selectedMode.displayNamePl}',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.textDark),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Ile kilometrów tygodniowo chcesz pokonać? Cel możesz w każdej chwili edytować.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 40),

          Center(
            child: Column(
              children: [
                Text(
                  '${_weeklyGoalKm.toInt()} km',
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                    color: AppColors.forestGreen,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'tygodniowo',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _weeklyGoalKm.clamp(2.0, _maxGoalKm),
                  min: 2,
                  max: _maxGoalKm,
                  divisions: (_maxGoalKm - 2).toInt(),
                  activeColor: AppColors.forestGreen,
                  inactiveColor: AppColors.softGreenTint,
                  onChanged: (v) => setState(() => _weeklyGoalKm = v),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _maxGoalKm += 20;
                    _weeklyGoalKm += 5;
                  });
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
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
                    const SizedBox(height: 3),
                    const Text(
                      'Więcej',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.forestGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 48),

          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.forestGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Dalej', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, color: Colors.white),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Step 4: Habits for mode
  Widget _buildStep4Habits(String lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _selectedMode.habitQuestionPl,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.textDark),
              ),
              const SizedBox(height: 4),
              const Text(
                'Wybierz godziny swoich codziennych nawyków – wyślemy wtedy subtelną zachętę do ruchu.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),

        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            itemCount: _habits.length + 1,
            itemBuilder: (context, index) {
              if (index == _habits.length) {
                // Button to add custom
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: OutlinedButton.icon(
                    onPressed: _addCustomHabit,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.forestGreen),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: const Icon(Icons.add_rounded, color: AppColors.forestGreen),
                    label: const Text(
                      'Dodaj własne',
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.forestGreen),
                    ),
                  ),
                );
              }

              final habit = _habits[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            habit.triggerTime != null
                                ? 'Przypomnienie o: ${habit.triggerTime!.format(context)}'
                                : 'Nie dotyczy',
                            style: TextStyle(
                              fontSize: 12,
                              color: habit.triggerTime != null ? AppColors.forestGreen : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _pickTimeForHabit(index),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.softGreenTint,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          habit.triggerTime != null ? habit.triggerTime!.format(context) : 'Ustaw godzinę',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.forestGreen,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        Padding(
          padding: const EdgeInsets.all(24),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.forestGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Dalej', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, color: Colors.white),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Step 5: Permissions & finish
  Widget _buildStep5Permissions(String lang) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: AppColors.softGreenTint,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.security_rounded, color: AppColors.forestGreen, size: 48),
          ),
          const SizedBox(height: 24),
          const Text(
            'Dostęp do czujników i lokalizacji',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.textDark),
          ),
          const SizedBox(height: 12),
          const Text(
            'Aby precyzyjnie mierzyć przebyte kilometry, trasę i tempo oraz wysyłać motywujące przypomnienia, CapiGo potrzebuje zgody na dostęp do lokalizacji GPS i powiadomień.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 48),

          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _requestPermissionsAndFinish,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.forestGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              child: const Text(
                'Zezwól na dostęp i zaczynajmy',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
