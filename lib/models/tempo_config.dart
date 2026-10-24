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

  static TempoConfig defaultPreset() {
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
          namePl: 'Solidna redukcja kalorii',
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

  // Algorithm: evaluates speed category and cadence category,
  // takes the LOWER of the two categories to prevent overestimation.
  TempoTier evaluate(double avgSpeedKmh, double avgCadence) {
    int speedLevel = 5;
    for (int i = 0; i < tiers.length; i++) {
      if (avgSpeedKmh <= tiers[i].maxSpeedKmh) {
        speedLevel = tiers[i].level;
        break;
      }
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
