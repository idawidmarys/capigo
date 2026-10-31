import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/habit_item.dart';
import '../providers/user_provider.dart';
import '../services/localization_service.dart';
import '../theme/app_colors.dart';
import '../widgets/time_input_dialog.dart';
import 'tempo_dialog.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final profile = userProvider.profile;
    final lang = userProvider.languageCode;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          LocalizationService.tr('tab_settings', lang),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          // Profile Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
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
                        size: 32,
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
                        profile.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${profile.streakWeeks}. ${LocalizationService.tr('streak_suffix', lang)}',
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Options section
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                // Goal Edit
                ListTile(
                  leading: const Icon(Icons.flag_outlined, color: AppColors.forestGreen),
                  title: Text(
                    LocalizationService.tr('weekly_goal_header', lang),
                    style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark),
                  ),
                  subtitle: Text(
                    '${profile.weeklyGoalKm.toInt()} km${profile.nextWeekGoalKm != null ? ' → ${profile.nextWeekGoalKm!.toInt()} km' : ''}',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textSecondary),
                  onTap: () => _showEditGoalDialog(context, profile.weeklyGoalKm),
                ),
                const Divider(height: 1, indent: 56, color: AppColors.divider),

                // Tempo settings
                ListTile(
                  leading: const Icon(Icons.speed, color: AppColors.forestGreen),
                  title: Text(
                    LocalizationService.tr('tempo_settings', lang),
                    style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark),
                  ),
                  subtitle: Text(
                    LocalizationService.tr('tempo_desc', lang),
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textSecondary),
                  onTap: () => TempoSettingsDialog.show(context),
                ),
                const Divider(height: 1, indent: 56, color: AppColors.divider),

                // Language change
                ListTile(
                  leading: const Icon(Icons.language, color: AppColors.forestGreen),
                  title: Text(
                    lang == 'pl' ? 'Język aplikacji' : lang == 'de' ? 'Sprache' : lang == 'es' ? 'Idioma' : 'Language',
                    style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark),
                  ),
                  subtitle: Text(
                    '${LocalizationService.languageFlags[lang]} ${LocalizationService.languageNames[lang]}',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textSecondary),
                  onTap: () => _showLanguagePicker(context, userProvider),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Scheduled habit prompts header
          Text(
            LocalizationService.tr('habits_title', lang),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 10),

          // Habits list
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                if (profile.habits.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      lang == 'pl' ? 'Brak zdefiniowanych powodów do spaceru.' : 'No walk reasons defined.',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                else
                  ...List.generate(profile.habits.length, (i) {
                    final habit = profile.habits[i];
                    final hasTime = habit.triggerTime != null;

                    return Column(
                      children: [
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                          onTap: () async {
                            final picked = await TimeInputDialog.show(context, initialTime: habit.triggerTime);
                            if (picked != null) {
                              final updated = List<HabitItem>.from(profile.habits);
                              updated[i] = updated[i].copyWith(triggerTime: picked, isEnabled: true);
                              userProvider.updateHabits(updated);
                            }
                          },
                          title: Text(
                            habit.getLocalizedTitle(lang),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                          ),
                          subtitle: Text(
                            hasTime
                                ? '${LocalizationService.tr('set_hour', lang)}: ${habit.triggerTime!.format(context)}'
                                : LocalizationService.tr('not_applicable', lang),
                            style: TextStyle(
                              fontSize: 12,
                              color: hasTime ? AppColors.forestGreen : AppColors.textSecondary,
                              fontWeight: hasTime ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Switch(
                                value: hasTime && habit.isEnabled,
                                activeThumbColor: AppColors.forestGreen,
                                activeTrackColor: AppColors.softGreenTint,
                                onChanged: (val) async {
                                  if (val) {
                                    final picked = await TimeInputDialog.show(
                                      context,
                                      initialTime: const TimeOfDay(hour: 18, minute: 0),
                                    );
                                    if (picked != null) {
                                      final updated = List<HabitItem>.from(profile.habits);
                                      updated[i] = updated[i].copyWith(triggerTime: picked, isEnabled: true);
                                      userProvider.updateHabits(updated);
                                    }
                                  } else {
                                    final updated = List<HabitItem>.from(profile.habits);
                                    updated[i] = updated[i].copyWith(clearTime: true, isEnabled: false);
                                    userProvider.updateHabits(updated);
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textSecondary),
                                tooltip: lang == 'pl' ? 'Usuń pozycję' : 'Remove',
                                onPressed: () {
                                  final updated = List<HabitItem>.from(profile.habits);
                                  updated.removeAt(i);
                                  userProvider.updateHabits(updated);
                                },
                              ),
                            ],
                          ),
                        ),
                        if (i < profile.habits.length - 1)
                          const Divider(height: 1, indent: 16, color: AppColors.divider),
                      ],
                    );
                  }),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Add custom habit button
          Center(
            child: TextButton.icon(
              onPressed: () => _showAddCustomHabitDialog(context, userProvider, lang),
              icon: const Icon(Icons.add_rounded, color: AppColors.forestGreen),
              label: Text(
                LocalizationService.tr('add_custom_walk', lang),
                style: const TextStyle(
                  color: AppColors.forestGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Reset App button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
            ),
            child: Center(
              child: OutlinedButton.icon(
                onPressed: () => _confirmResetApp(context, userProvider, lang),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent, width: 1.5),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.restart_alt_rounded, size: 22),
                label: Text(
                  LocalizationService.tr('reset_app', lang),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
          ),

          const SizedBox(height: 28),

          // Version info
          Center(
            child: Column(
              children: [
                const Text(
                  'CapiGo',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  lang == 'pl' ? 'Wersja 1.0.4' : 'Version 1.0.4',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
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
                title: const Text('Obowiązuje od przyszłego tygodnia', style: TextStyle(fontSize: 13)),
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

  void _showLanguagePicker(BuildContext context, UserProvider userProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: LocalizationService.languageNames.entries.map((entry) {
            final isSelected = entry.key == userProvider.languageCode;
            return ListTile(
              leading: Text(
                LocalizationService.languageFlags[entry.key] ?? '🦫',
                style: const TextStyle(fontSize: 24),
              ),
              title: Text(
                entry.value,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppColors.forestGreen : AppColors.textDark,
                ),
              ),
              trailing: isSelected
                  ? const Icon(Icons.check, color: AppColors.forestGreen)
                  : null,
              onTap: () {
                userProvider.setLanguage(entry.key);
                Navigator.pop(ctx);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showAddCustomHabitDialog(BuildContext context, UserProvider userProvider, String lang) {
    final customController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(LocalizationService.tr('add_custom_walk', lang)),
        content: TextField(
          controller: customController,
          decoration: InputDecoration(
            hintText: lang == 'pl'
                ? 'np. Spacer po obiedzie, spacer z partnerem'
                : 'e.g. Afternoon walk, walk with partner',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(LocalizationService.tr('cancel', lang)),
          ),
          ElevatedButton(
            onPressed: () {
              final text = customController.text.trim();
              if (text.isNotEmpty) {
                final updated = List<HabitItem>.from(userProvider.profile.habits);
                updated.add(HabitItem(
                  id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                  titlePl: text,
                  titleEn: text,
                  titleDe: text,
                  titleEs: text,
                  promptPl: 'Czas na Twój zaplanowany spacer: $text!',
                  promptEn: 'Time for your scheduled walk: $text!',
                  promptDe: 'Zeit für deinen geplanten Spaziergang: $text!',
                  promptEs: '¡Hora de tu paseo programado: $text!',
                  triggerTime: null,
                  isCustom: true,
                ));
                userProvider.updateHabits(updated);
              }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.forestGreen),
            child: Text(lang == 'pl' ? 'Dodaj' : 'Add'),
          ),
        ],
      ),
    );
  }

  void _confirmResetApp(BuildContext context, UserProvider userProvider, String lang) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          LocalizationService.tr('reset_dialog_title', lang),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          LocalizationService.tr('reset_dialog_desc', lang),
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(LocalizationService.tr('cancel', lang)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await userProvider.resetApp();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
            ),
            child: Text(LocalizationService.tr('reset_app', lang)),
          ),
        ],
      ),
    );
  }
}
