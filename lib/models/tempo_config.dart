import 'activity_type.dart';

class TempoTier {
  final int level; // 1 to 5
  final String key;
  final String namePl;
  final String nameEn;
  final String nameDe;
  final String nameEs;
  final double maxSpeedKmh; // upper bound for this tier
  final int maxCadence; // upper bound steps/min for this tier
  final double met; // MET value for calorie calculation

  const TempoTier({
    required this.level,
    required this.key,
    required this.namePl,
    required this.nameEn,
    required this.nameDe,
    required this.nameEs,
    required this.maxSpeedKmh,
    required this.maxCadence,
    required this.met,
  });

  String getLocalizedName(String langCode) {
    switch (langCode) {
      case 'pl':
        return namePl;
      case 'de':
        return nameDe;
      case 'es':
        return nameEs;
      case 'en':
      default:
        return nameEn;
    }
  }

  Map<String, dynamic> toJson() => {
        'level': level,
        'key': key,
        'namePl': namePl,
        'nameEn': nameEn,
        'nameDe': nameDe,
        'nameEs': nameEs,
        'maxSpeedKmh': maxSpeedKmh,
        'maxCadence': maxCadence,
        'met': met,
      };

  factory TempoTier.fromJson(Map<String, dynamic> json) => TempoTier(
        level: json['level'] as int,
        key: json['key'] as String,
        namePl: json['namePl'] as String,
        nameEn: json['nameEn'] as String,
        nameDe: json['nameDe'] as String,
        nameEs: json['nameEs'] as String,
        maxSpeedKmh: (json['maxSpeedKmh'] as num).toDouble(),
        maxCadence: json['maxCadence'] as int,
        met: (json['met'] as num).toDouble(),
      );
}

class TempoConfig {
  final List<TempoTier> tiers;

  TempoConfig({required this.tiers});

  static TempoConfig defaultPreset() => defaultWalkPreset();

  static TempoConfig defaultPresetForMode(ActivityType type) {
    switch (type) {
      case ActivityType.run:
      case ActivityType.jog:
        return defaultRunPreset();
      case ActivityType.bike:
        return defaultBikePreset();
      case ActivityType.walk:
      case ActivityType.nordicWalk:
        return defaultWalkPreset();
    }
  }

  // Domyślne wartości dla Spaceru i Nordic Walking
  static TempoConfig defaultWalkPreset() {
    return TempoConfig(
      tiers: [
        const TempoTier(
          level: 1,
          key: 'very_slow',
          namePl: 'Bardzo spokojne',
          nameEn: 'Very slow',
          nameDe: 'Sehr langsam',
          nameEs: 'Muy tranquilo',
          maxSpeedKmh: 2.5,
          maxCadence: 70,
          met: 2.8,
        ),
        const TempoTier(
          level: 2,
          key: 'slow',
          namePl: 'Spokojne',
          nameEn: 'Slow & relaxed',
          nameDe: 'Gemütlich',
          nameEs: 'Tranquilo',
          maxSpeedKmh: 4.0,
          maxCadence: 95,
          met: 3.5,
        ),
        const TempoTier(
          level: 3,
          key: 'neutral',
          namePl: 'Neutralne',
          nameEn: 'Moderate / Neutral',
          nameDe: 'Mäßig / Neutral',
          nameEs: 'Moderado',
          maxSpeedKmh: 5.2,
          maxCadence: 115,
          met: 4.3,
        ),
        const TempoTier(
          level: 4,
          key: 'fast',
          namePl: 'Szybkie',
          nameEn: 'Brisk / Fast',
          nameDe: 'Zügig / Schnell',
          nameEs: 'Rápido',
          maxSpeedKmh: 6.5,
          maxCadence: 130,
          met: 5.5,
        ),
        const TempoTier(
          level: 5,
          key: 'calorie_burn',
          namePl: 'Bardzo szybkie',
          nameEn: 'Power burn / Jog',
          nameDe: 'Intensive Verbrennung',
          nameEs: 'Quema intensiva',
          maxSpeedKmh: 99.0,
          maxCadence: 999,
          met: 7.5,
        ),
      ],
    );
  }

  // Domyślne wartości dla Biegu
  static TempoConfig defaultRunPreset() {
    return TempoConfig(
      tiers: [
        const TempoTier(
          level: 1,
          key: 'very_slow',
          namePl: 'Bardzo spokojne',
          nameEn: 'Very slow',
          nameDe: 'Sehr langsam',
          nameEs: 'Muy tranquilo',
          maxSpeedKmh: 7.0,
          maxCadence: 155,
          met: 6.5,
        ),
        const TempoTier(
          level: 2,
          key: 'slow',
          namePl: 'Spokojne',
          nameEn: 'Slow & relaxed',
          nameDe: 'Gemütlich',
          nameEs: 'Tranquilo',
          maxSpeedKmh: 9.0,
          maxCadence: 165,
          met: 8.5,
        ),
        const TempoTier(
          level: 3,
          key: 'neutral',
          namePl: 'Neutralne',
          nameEn: 'Moderate / Neutral',
          nameDe: 'Mäßig / Neutral',
          nameEs: 'Moderado',
          maxSpeedKmh: 11.0,
          maxCadence: 175,
          met: 10.0,
        ),
        const TempoTier(
          level: 4,
          key: 'fast',
          namePl: 'Szybkie',
          nameEn: 'Brisk / Fast',
          nameDe: 'Zügig / Schnell',
          nameEs: 'Rápido',
          maxSpeedKmh: 14.0,
          maxCadence: 185,
          met: 12.0,
        ),
        const TempoTier(
          level: 5,
          key: 'very_fast',
          namePl: 'Bardzo szybkie',
          nameEn: 'Very fast',
          nameDe: 'Sehr schnell',
          nameEs: 'Muy rápido',
          maxSpeedKmh: 99.0,
          maxCadence: 999,
          met: 14.5,
        ),
      ],
    );
  }

  // Domyślne wartości dla Roweru (bez kadencji)
  static TempoConfig defaultBikePreset() {
    return TempoConfig(
      tiers: [
        const TempoTier(
          level: 1,
          key: 'very_slow',
          namePl: 'Bardzo spokojne',
          nameEn: 'Very slow',
          nameDe: 'Sehr langsam',
          nameEs: 'Muy tranquilo',
          maxSpeedKmh: 10.0,
          maxCadence: 999,
          met: 4.0,
        ),
        const TempoTier(
          level: 2,
          key: 'slow',
          namePl: 'Spokojne',
          nameEn: 'Slow & relaxed',
          nameDe: 'Gemütlich',
          nameEs: 'Tranquilo',
          maxSpeedKmh: 15.0,
          maxCadence: 999,
          met: 6.0,
        ),
        const TempoTier(
          level: 3,
          key: 'neutral',
          namePl: 'Neutralne',
          nameEn: 'Moderate / Neutral',
          nameDe: 'Mäßig / Neutral',
          nameEs: 'Moderado',
          maxSpeedKmh: 20.0,
          maxCadence: 999,
          met: 8.0,
        ),
        const TempoTier(
          level: 4,
          key: 'fast',
          namePl: 'Szybkie',
          nameEn: 'Brisk / Fast',
          nameDe: 'Zügig / Schnell',
          nameEs: 'Rápido',
          maxSpeedKmh: 25.0,
          maxCadence: 999,
          met: 10.0,
        ),
        const TempoTier(
          level: 5,
          key: 'very_fast',
          namePl: 'Bardzo szybkie',
          nameEn: 'Very fast',
          nameDe: 'Sehr schnell',
          nameEs: 'Muy rápido',
          maxSpeedKmh: 99.0,
          maxCadence: 999,
          met: 12.5,
        ),
      ],
    );
  }

  // Algorithm: evaluates speed category and cadence category,
  // takes the LOWER of the two categories to prevent overestimation.
  // For bike or zero-cadence workouts, evaluates by speed only.
  TempoTier evaluate(double avgSpeedKmh, double avgCadence, {bool isBike = false}) {
    int speedLevel = 5;
    for (int i = 0; i < tiers.length; i++) {
      if (avgSpeedKmh <= tiers[i].maxSpeedKmh) {
        speedLevel = tiers[i].level;
        break;
      }
    }

    if (isBike || avgCadence <= 0) {
      return tiers.firstWhere((t) => t.level == speedLevel, orElse: () => tiers[0]);
    }

    int cadenceLevel = 5;
    for (int i = 0; i < tiers.length; i++) {
      if (avgCadence <= tiers[i].maxCadence) {
        cadenceLevel = tiers[i].level;
        break;
      }
    }

    // Take the lowest level of both metrics
    final int finalLevel = speedLevel < cadenceLevel ? speedLevel : cadenceLevel;
    return tiers.firstWhere((t) => t.level == finalLevel, orElse: () => tiers[0]);
  }

  Map<String, dynamic> toJson() => {
        'tiers': tiers.map((t) => t.toJson()).toList(),
      };

  factory TempoConfig.fromJson(Map<String, dynamic> json) {
    final list = json['tiers'] as List<dynamic>?;
    if (list == null || list.isEmpty) return TempoConfig.defaultPreset();
    return TempoConfig(
      tiers: list.map((e) => TempoTier.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}
