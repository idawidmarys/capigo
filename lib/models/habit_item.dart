import 'package:flutter/material.dart';

class HabitItem {
  final String id;
  final String titlePl;
  final String titleEn;
  final String titleDe;
  final String titleEs;
  final String promptPl;
  final String promptEn;
  final String promptDe;
  final String promptEs;
  final TimeOfDay? triggerTime;
  final bool isCustom;
  final bool isEnabled;

  HabitItem({
    required this.id,
    required this.titlePl,
    required this.titleEn,
    required this.titleDe,
    required this.titleEs,
    required this.promptPl,
    required this.promptEn,
    required this.promptDe,
    required this.promptEs,
    this.triggerTime,
    this.isCustom = false,
    this.isEnabled = true,
  });

  HabitItem copyWith({
    TimeOfDay? triggerTime,
    bool? isEnabled,
    String? titlePl,
    bool clearTime = false,
  }) {
    return HabitItem(
      id: id,
      titlePl: titlePl ?? this.titlePl,
      titleEn: titleEn,
      titleDe: titleDe,
      titleEs: titleEs,
      promptPl: promptPl,
      promptEn: promptEn,
      promptDe: promptDe,
      promptEs: promptEs,
      triggerTime: clearTime ? null : (triggerTime ?? this.triggerTime),
      isCustom: isCustom,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  String getLocalizedTitle(String lang) {
    switch (lang) {
      case 'pl':
        return titlePl;
      case 'de':
        return titleDe;
      case 'es':
        return titleEs;
      case 'en':
      default:
        return titleEn;
    }
  }

  String getLocalizedPrompt(String lang) {
    switch (lang) {
      case 'pl':
        return promptPl;
      case 'de':
        return promptDe;
      case 'es':
        return promptEs;
      case 'en':
      default:
        return promptEn;
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'titlePl': titlePl,
        'titleEn': titleEn,
        'titleDe': titleDe,
        'titleEs': titleEs,
        'promptPl': promptPl,
        'promptEn': promptEn,
        'promptDe': promptDe,
        'promptEs': promptEs,
        'hour': triggerTime?.hour,
        'minute': triggerTime?.minute,
        'isCustom': isCustom,
        'isEnabled': isEnabled,
      };

  factory HabitItem.fromJson(Map<String, dynamic> json) {
    TimeOfDay? time;
    if (json['hour'] != null && json['minute'] != null) {
      time = TimeOfDay(hour: json['hour'] as int, minute: json['minute'] as int);
    }
    return HabitItem(
      id: json['id'] as String,
      titlePl: json['titlePl'] as String,
      titleEn: json['titleEn'] as String,
      titleDe: json['titleDe'] as String,
      titleEs: json['titleEs'] as String,
      promptPl: json['promptPl'] as String,
      promptEn: json['promptEn'] as String,
      promptDe: json['promptDe'] as String,
      promptEs: json['promptEs'] as String,
      triggerTime: time,
      isCustom: json['isCustom'] as bool? ?? false,
      isEnabled: json['isEnabled'] as bool? ?? true,
    );
  }

  static List<HabitItem> defaultHabits() {
    return [
      HabitItem(
        id: 'netflix',
        titlePl: 'Zamiast Netflix',
        titleEn: 'Instead of Netflix',
        titleDe: 'Statt Netflix',
        titleEs: 'En vez de Netflix',
        promptPl: 'Może spacer i spalenie kilku kalorii zamiast Netflix i chipsy?',
        promptEn: 'How about a walk and burning calories instead of Netflix and chips?',
        promptDe: 'Wie wäre es mit einem Spaziergang statt Netflix und Chips?',
        promptEs: '¿Qué tal un paseo quemando calorías en vez de Netflix y patatas?',
        triggerTime: const TimeOfDay(hour: 20, minute: 0),
      ),
      HabitItem(
        id: 'tv',
        titlePl: 'Zamiast TV',
        titleEn: 'Instead of TV',
        titleDe: 'Statt Fernsehen',
        titleEs: 'En vez de TV',
        promptPl: 'Może krótki spacer na świeżym powietrzu zamiast leżenia przed TV?',
        promptEn: 'How about a fresh air walk instead of lying in front of the TV?',
        promptDe: 'Wie wäre es mit frischer Luft statt TV auf der Couch?',
        promptEs: '¿Un paseo al aire libre en lugar de tumbarte ante la tele?',
        triggerTime: const TimeOfDay(hour: 19, minute: 0),
      ),
      HabitItem(
        id: 'boredom',
        titlePl: 'Zamiast zamulania w domu',
        titleEn: 'Instead of sluggish time at home',
        titleDe: 'Statt Langeweile zu Hause',
        titleEs: 'En vez de aburrirte en casa',
        promptPl: 'Zamulasz? Załóż buty, wyjdź na mały spacer i naładuj baterie!',
        promptEn: 'Feeling sluggish? Put on your shoes, go for a quick walk and recharge!',
        promptDe: 'Träge? Zieh deine Schuhe an und mach einen erfrischenden Spaziergang!',
        promptEs: '¿Apático? ¡Ponte las zapatillas, sal a caminar y recarga energía!',
        triggerTime: const TimeOfDay(hour: 16, minute: 30),
      ),
      HabitItem(
        id: 'audiobook',
        titlePl: 'Spacer ze słuchaniem audiobooka / podcastu',
        titleEn: 'Walking while listening to audiobook / podcast',
        titleDe: 'Spaziergang mit Hörbuch / Podcast',
        titleEs: 'Paseo escuchando audiolibro / podcast',
        promptPl: 'Nie masz ochoty przesłuchać audiobooka i pospacerować?',
        promptEn: 'Care to listen to your audiobook while taking a pleasant walk?',
        promptDe: 'Lust, dein Hörbuch bei einem schönen Spaziergang zu hören?',
        promptEs: '¿Te apetece escuchar tu audiolibro mientras das un agradable paseo?',
        triggerTime: const TimeOfDay(hour: 18, minute: 0),
      ),
      HabitItem(
        id: 'walk_dog',
        titlePl: 'Spacer z psem',
        titleEn: 'Walking the dog',
        titleDe: 'Mit dem Hund Gassi gehen',
        titleEs: 'Pasear al perro',
        promptPl: 'Czas na spacer z psiakiem — zdrowie i radość dla Was obojga!',
        promptEn: 'Time for a walk with your dog — healthy energy for both of you!',
        promptDe: 'Zeit für eine Gassirunde — gut für dich und deinen Vierbeiner!',
        promptEs: '¡Hora de pasear al perro! Movimiento y salud para los dos.',
        triggerTime: const TimeOfDay(hour: 17, minute: 30),
      ),
      HabitItem(
        id: 'child_walk',
        titlePl: 'Spacer z dzieckiem',
        titleEn: 'Walking with kids',
        titleDe: 'Spaziergang mit Kind',
        titleEs: 'Paseo con los niños',
        promptPl: 'Może spacer z dzieckiem na świeżym powietrzu?',
        promptEn: 'How about a fun outdoor walk with your child?',
        promptDe: 'Wie wäre es mit einem Familien-Spaziergang an der frischen Luft?',
        promptEs: '¿Qué tal un agradable paseo al aire libre con los peques?',
        triggerTime: null, // "Nie dotyczy" by default
      ),
    ];
  }
}
