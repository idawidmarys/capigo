import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class CircularProgressClock extends StatelessWidget {
  final double currentKm;
  final double goalKm;
  final double size;

  const CircularProgressClock({
    super.key,
    required this.currentKm,
    required this.goalKm,
    this.size = 180,
  });

  @override
  Widget build(BuildContext context) {
    final double progress = (goalKm > 0) ? (currentKm / goalKm).clamp(0.0, 1.0) : 0.0;
    final isDark = AppColors.isDark(context);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _ClockRingPainter(
              progress: progress,
              strokeWidth: 14,
              trackColor: isDark ? AppColors.darkSoftGreenTint : AppColors.softGreenTint,
              fillColor: isDark ? AppColors.forestGreenAccent : AppColors.forestGreen,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                currentKm.toStringAsFixed(1).replaceAll('.', ','),
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  color: AppColors.text(isDark),
                  letterSpacing: -1.0,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'z ${goalKm.toStringAsFixed(0)} km',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.subtext(isDark),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ClockRingPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color trackColor;
  final Color fillColor;

  _ClockRingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.trackColor,
    required this.fillColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Track circle
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, trackPaint);

    if (progress > 0) {
      // Clockwise progress starting from -90 degrees (12 o'clock)
      final fillPaint = Paint()
        ..color = fillColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      const startAngle = -math.pi / 2;
      final sweepAngle = 2 * math.pi * progress;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        fillPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ClockRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.trackColor != trackColor;
  }
}
