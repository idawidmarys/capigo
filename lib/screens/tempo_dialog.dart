import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/activity_type.dart';
import '../models/tempo_config.dart';
import '../providers/user_provider.dart';
import '../services/localization_service.dart';
import '../theme/app_colors.dart';

class TempoSettingsDialog extends StatefulWidget {
  final ActivityType? mode;

  const TempoSettingsDialog({super.key, this.mode});

  static Future<void> show(BuildContext context, {ActivityType? mode}) {
    return showDialog(
      context: context,
      builder: (_) => TempoSettingsDialog(mode: mode),
    );
  }

  @override
  State<TempoSettingsDialog> createState() => _TempoSettingsDialogState();
}

class _TempoSettingsDialogState extends State<TempoSettingsDialog> {
  late ActivityType _mode;
  late List<TextEditingController> _speedControllers;
  late List<TextEditingController> _cadenceControllers;
  late List<TempoTier> _tiers;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final userProvider = context.read<UserProvider>();
    _mode = widget.mode ?? userProvider.activeActivityType;
    final config = userProvider.getTempoConfigForMode(_mode);
    _tiers = List.from(config.tiers);
    _speedControllers = _tiers.map((t) => TextEditingController(text: t.maxSpeedKmh.toString())).toList();
    _cadenceControllers = _tiers.map((t) => TextEditingController(text: t.maxCadence.toString())).toList();
  }

  @override
  void dispose() {
    for (var c in _speedControllers) {
      c.dispose();
    }
    for (var c in _cadenceControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    final lang = context.read<UserProvider>().languageCode;
    final bool isBike = _mode == ActivityType.bike;
    final updatedTiers = <TempoTier>[];

    for (int i = 0; i < _tiers.length; i++) {
      final double? speed = double.tryParse(_speedControllers[i].text.trim().replaceAll(',', '.'));
      int cadence = 999;

      if (!isBike) {
        final parsedCadence = int.tryParse(_cadenceControllers[i].text.trim());
        if (parsedCadence == null || parsedCadence <= 0) {
          setState(() {
            _errorMessage = lang == 'pl'
                ? 'Wprowadź prawidłową kadencję dla każdego poziomu.'
                : 'Please enter valid cadence for each level.';
          });
          return;
        }
        cadence = parsedCadence;
      }

      if (speed == null || speed <= 0) {
        setState(() {
          _errorMessage = lang == 'pl'
              ? 'Wprowadź prawidłową prędkość dla każdego poziomu.'
              : 'Please enter valid speed for each level.';
        });
        return;
      }

      updatedTiers.add(TempoTier(
        level: _tiers[i].level,
        key: _tiers[i].key,
        namePl: _tiers[i].namePl,
        nameEn: _tiers[i].nameEn,
        nameDe: _tiers[i].nameDe,
        nameEs: _tiers[i].nameEs,
        maxSpeedKmh: speed,
        maxCadence: cadence,
        met: _tiers[i].met,
      ));
    }

    // Walidacja gradacji: każdy kolejny poziom musi mieć większą prędkość (i kadencję dla nie-roweru)
    for (int i = 1; i < updatedTiers.length; i++) {
      if (updatedTiers[i].maxSpeedKmh <= updatedTiers[i - 1].maxSpeedKmh) {
        setState(() {
          _errorMessage = lang == 'pl'
              ? 'Prędkość powinna stopniowo rosnąć (poziom $i musi być mniejszy niż poziom ${i + 1}).'
              : 'Speed should gradually increase (level $i must be lower than level ${i + 1}).';
        });
        return;
      }
      if (!isBike && updatedTiers[i].maxCadence <= updatedTiers[i - 1].maxCadence) {
        setState(() {
          _errorMessage = lang == 'pl'
              ? 'Kadencja powinna stopniowo rosnąć (poziom $i musi być mniejsza niż poziom ${i + 1}).'
              : 'Cadence should gradually increase (level $i must be lower than level ${i + 1}).';
        });
        return;
      }
    }

    setState(() {
      _errorMessage = null;
    });

    context.read<UserProvider>().updateTempoConfigForMode(_mode, TempoConfig(tiers: updatedTiers));
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(lang == 'pl'
            ? 'Ustawienia tempa dla trybu ${_mode.displayNamePl} zostały zapisane!'
            : 'Pace settings for ${_mode.name} saved!'),
        backgroundColor: AppColors.forestGreen,
      ),
    );
  }

  void _resetToDefaults() {
    final defaultCfg = TempoConfig.defaultPresetForMode(_mode);
    for (int i = 0; i < defaultCfg.tiers.length && i < _speedControllers.length; i++) {
      _speedControllers[i].text = defaultCfg.tiers[i].maxSpeedKmh.toString();
      _cadenceControllers[i].text = defaultCfg.tiers[i].maxCadence.toString();
    }
    setState(() {
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final lang = userProvider.languageCode;
    final bool isBike = _mode == ActivityType.bike;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 640),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _mode.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_mode.icon, color: _mode.color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              LocalizationService.tr('tempo_settings', lang),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: _mode.color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _mode.displayNamePl,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: _mode.color,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isBike
                            ? (lang == 'pl'
                                ? 'Progi prędkości dla 5 poziomów tempa na rowerze:'
                                : 'Speed thresholds for 5 cycling pace levels:')
                            : LocalizationService.tr('tempo_desc', lang),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textDark),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
            const Divider(
              height: 24,
              color: AppColors.border,
            ),

            // Komunikat błędu nad oknami wpisywania danych
            if (_errorMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDE8E8),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFC53030),
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            Expanded(
              child: ListView.separated(
                itemCount: _tiers.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (ctx, i) {
                  final tier = _tiers[i];
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7FAF8),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.border,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: _mode.color,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${tier.level}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                tier.getLocalizedName(lang),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    height: 18,
                                    child: Text(
                                      lang == 'pl' ? 'Maks. km/h' : 'Max km/h',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textSecondary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  SizedBox(
                                    height: 42,
                                    child: TextField(
                                      controller: _speedControllers[i],
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textDark,
                                      ),
                                      decoration: InputDecoration(
                                        isDense: true,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                                        filled: true,
                                        fillColor: Colors.white,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: const BorderSide(
                                            color: AppColors.border,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: const BorderSide(
                                            color: AppColors.border,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: BorderSide(color: _mode.color, width: 1.5),
                                        ),
                                        suffixText: 'km/h',
                                        suffixStyle: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!isBike) ...[
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      height: 18,
                                      child: Text(
                                        lang == 'pl' ? 'Maks. krok/min' : 'Max steps/min',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textSecondary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    SizedBox(
                                      height: 42,
                                      child: TextField(
                                        controller: _cadenceControllers[i],
                                        keyboardType: TextInputType.number,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textDark,
                                        ),
                                        decoration: InputDecoration(
                                          isDense: true,
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                                          filled: true,
                                          fillColor: Colors.white,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(10),
                                            borderSide: const BorderSide(
                                              color: AppColors.border,
                                            ),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(10),
                                            borderSide: const BorderSide(
                                              color: AppColors.border,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(10),
                                            borderSide: BorderSide(color: _mode.color, width: 1.5),
                                          ),
                                          suffixText: 'spm',
                                          suffixStyle: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                TextButton(
                  onPressed: _resetToDefaults,
                  child: Text(
                    lang == 'pl' ? 'Domyślne' : 'Defaults',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _mode.color,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(LocalizationService.tr('save', lang)),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
