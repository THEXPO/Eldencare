import 'enums.dart';

class DietEntry {
  const DietEntry({
    required this.id,
    required this.slot,
    required this.title,
    required this.description,
    required this.scheduledTimeMinutes,
    this.instructions,
    this.isActive = true,
  });

  final String id;
  final MealSlot slot;
  final String title;
  final String description;
  final int scheduledTimeMinutes;
  final String? instructions;
  final bool isActive;

  DietEntry copyWith({
    MealSlot? slot,
    String? title,
    String? description,
    int? scheduledTimeMinutes,
    String? instructions,
    bool? isActive,
  }) {
    return DietEntry(
      id: id,
      slot: slot ?? this.slot,
      title: title ?? this.title,
      description: description ?? this.description,
      scheduledTimeMinutes: scheduledTimeMinutes ?? this.scheduledTimeMinutes,
      instructions: instructions ?? this.instructions,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'slot': slot.name,
    'title': title,
    'description': description,
    'scheduledTimeMinutes': scheduledTimeMinutes,
    'instructions': instructions,
    'isActive': isActive,
  };

  factory DietEntry.fromJson(Map<String, dynamic> json) => DietEntry(
    id: json['id'] as String,
    slot: MealSlot.values.byName(json['slot'] as String),
    title: json['title'] as String,
    description: json['description'] as String,
    scheduledTimeMinutes: json['scheduledTimeMinutes'] as int,
    instructions: json['instructions'] as String?,
    isActive: json['isActive'] as bool? ?? true,
  );
}
