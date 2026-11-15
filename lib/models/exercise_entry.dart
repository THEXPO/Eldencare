class ExerciseEntry {
  const ExerciseEntry({
    required this.id,
    required this.title,
    required this.description,
    required this.scheduledTimeMinutes,
    this.instructions,
    this.isActive = true,
  });

  final String id;
  final String title;
  final String description;
  final int scheduledTimeMinutes;
  final String? instructions;
  final bool isActive;

  ExerciseEntry copyWith({
    String? title,
    String? description,
    int? scheduledTimeMinutes,
    String? instructions,
    bool? isActive,
  }) {
    return ExerciseEntry(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      scheduledTimeMinutes: scheduledTimeMinutes ?? this.scheduledTimeMinutes,
      instructions: instructions ?? this.instructions,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'scheduledTimeMinutes': scheduledTimeMinutes,
    'instructions': instructions,
    'isActive': isActive,
  };

  factory ExerciseEntry.fromJson(Map<String, dynamic> json) => ExerciseEntry(
    id: json['id'] as String,
    title: json['title'] as String,
    description: json['description'] as String,
    scheduledTimeMinutes: json['scheduledTimeMinutes'] as int,
    instructions: json['instructions'] as String?,
    isActive: json['isActive'] as bool? ?? true,
  );
}
