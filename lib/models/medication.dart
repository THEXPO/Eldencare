import 'enums.dart';

class Medication {
  const Medication({
    required this.id,
    required this.name,
    required this.strength,
    required this.dosage,
    required this.dosageForm,
    required this.scheduledTimesMinutes,
    required this.mealInstruction,
    required this.startDate,
    this.endDate,
    this.additionalInstructions,
    this.isActive = true,
  });

  final String id;
  final String name;
  final String strength;
  final String dosage;
  final DosageForm dosageForm;
  final List<int> scheduledTimesMinutes;
  final String mealInstruction;
  final DateTime startDate;
  final DateTime? endDate;
  final String? additionalInstructions;
  final bool isActive;

  bool isActiveOn(DateTime date) {
    if (!isActive) return false;
    final day = DateTime(date.year, date.month, date.day);
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    if (day.isBefore(start)) return false;
    if (endDate == null) return true;
    final end = DateTime(endDate!.year, endDate!.month, endDate!.day);
    return !day.isAfter(end);
  }

  Medication copyWith({
    String? name,
    String? strength,
    String? dosage,
    DosageForm? dosageForm,
    List<int>? scheduledTimesMinutes,
    String? mealInstruction,
    DateTime? startDate,
    DateTime? endDate,
    String? additionalInstructions,
    bool? isActive,
    bool clearEndDate = false,
  }) {
    return Medication(
      id: id,
      name: name ?? this.name,
      strength: strength ?? this.strength,
      dosage: dosage ?? this.dosage,
      dosageForm: dosageForm ?? this.dosageForm,
      scheduledTimesMinutes:
          scheduledTimesMinutes ?? this.scheduledTimesMinutes,
      mealInstruction: mealInstruction ?? this.mealInstruction,
      startDate: startDate ?? this.startDate,
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      additionalInstructions:
          additionalInstructions ?? this.additionalInstructions,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'strength': strength,
    'dosage': dosage,
    'dosageForm': dosageForm.name,
    'scheduledTimesMinutes': scheduledTimesMinutes,
    'mealInstruction': mealInstruction,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate?.toIso8601String(),
    'additionalInstructions': additionalInstructions,
    'isActive': isActive,
  };

  factory Medication.fromJson(Map<String, dynamic> json) => Medication(
    id: json['id'] as String,
    name: json['name'] as String,
    strength: json['strength'] as String,
    dosage: json['dosage'] as String,
    dosageForm: DosageForm.values.byName(json['dosageForm'] as String),
    scheduledTimesMinutes: (json['scheduledTimesMinutes'] as List<dynamic>)
        .map((e) => e as int)
        .toList(),
    mealInstruction: json['mealInstruction'] as String,
    startDate: DateTime.parse(json['startDate'] as String),
    endDate: json['endDate'] == null
        ? null
        : DateTime.parse(json['endDate'] as String),
    additionalInstructions: json['additionalInstructions'] as String?,
    isActive: json['isActive'] as bool? ?? true,
  );
}
