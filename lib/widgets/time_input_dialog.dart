import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';

class TimeInputDialog extends StatefulWidget {
  final TimeOfDay initialTime;

  const TimeInputDialog({super.key, required this.initialTime});

  static Future<TimeOfDay?> show(BuildContext context, {TimeOfDay? initialTime}) {
    return showDialog<TimeOfDay>(
      context: context,
      builder: (_) => TimeInputDialog(
        initialTime: initialTime ?? const TimeOfDay(hour: 18, minute: 0),
      ),
    );
  }

  @override
  State<TimeInputDialog> createState() => _TimeInputDialogState();
}

class _TimeInputDialogState extends State<TimeInputDialog> {
  late TextEditingController _hourController;
  late TextEditingController _minuteController;
  final FocusNode _hourFocus = FocusNode();
  final FocusNode _minuteFocus = FocusNode();
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _hourController = TextEditingController(
      text: widget.initialTime.hour.toString().padLeft(2, '0'),
    );
    _minuteController = TextEditingController(
      text: widget.initialTime.minute.toString().padLeft(2, '0'),
    );
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    _hourFocus.dispose();
    _minuteFocus.dispose();
    super.dispose();
  }

  void _submit() {
    final int? hour = int.tryParse(_hourController.text);
    final int? minute = int.tryParse(_minuteController.text);

    if (hour == null || hour < 0 || hour > 23) {
      setState(() => _errorMessage = 'Godzina musi być w przedziale 00 - 23');
      return;
    }

    if (minute == null || minute < 0 || minute > 59) {
      setState(() => _errorMessage = 'Minuty muszą być w przedziale 00 - 59');
      return;
    }

    Navigator.pop(context, TimeOfDay(hour: hour, minute: minute));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Wpisz godzinę',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Wprowadź czas za pomocą klawiatury (format 24h):',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),

            // Two textfields [ HH ] : [ MM ]
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildBox(
                  controller: _hourController,
                  focusNode: _hourFocus,
                  hint: 'HH',
                  max: 23,
                  onChanged: (val) {
                    if (val.length == 2) {
                      _minuteFocus.requestFocus();
                      _minuteController.selection = TextSelection(
                        baseOffset: 0,
                        extentOffset: _minuteController.text.length,
                      );
                    }
                  },
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    ':',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: AppColors.forestGreen,
                    ),
                  ),
                ),
                _buildBox(
                  controller: _minuteController,
                  focusNode: _minuteFocus,
                  hint: 'MM',
                  max: 59,
                  onChanged: (val) {},
                ),
              ],
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],

            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Anuluj', style: TextStyle(color: AppColors.textSecondary)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.forestGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Zapisz'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBox({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    required int max,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      width: 76,
      height: 70,
      decoration: BoxDecoration(
        color: AppColors.softGreenTint.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.forestGreen, width: 1.5),
      ),
      child: Center(
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(2),
          ],
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: AppColors.forestGreen,
          ),
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 24),
          ),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
