class ConsultationNote {
  const ConsultationNote({
    required this.id,
    required this.patientId,
    required this.doctorName,
    required this.date,
    required this.observations,
    required this.followUpInstructions,
    this.suggestedFollowUpDate,
  });

  final String id;
  final String patientId;
  final String doctorName;
  final DateTime date;
  final String observations;
  final String followUpInstructions;
  final DateTime? suggestedFollowUpDate;

  ConsultationNote copyWith({
    String? observations,
    String? followUpInstructions,
    DateTime? suggestedFollowUpDate,
  }) {
    return ConsultationNote(
      id: id,
      patientId: patientId,
      doctorName: doctorName,
      date: date,
      observations: observations ?? this.observations,
      followUpInstructions: followUpInstructions ?? this.followUpInstructions,
      suggestedFollowUpDate:
          suggestedFollowUpDate ?? this.suggestedFollowUpDate,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'patientId': patientId,
    'doctorName': doctorName,
    'date': date.toIso8601String(),
    'observations': observations,
    'followUpInstructions': followUpInstructions,
    'suggestedFollowUpDate': suggestedFollowUpDate?.toIso8601String(),
  };

  factory ConsultationNote.fromJson(Map<String, dynamic> json) =>
      ConsultationNote(
        id: json['id'] as String,
        patientId: json['patientId'] as String,
        doctorName: json['doctorName'] as String,
        date: DateTime.parse(json['date'] as String),
        observations: json['observations'] as String,
        followUpInstructions: json['followUpInstructions'] as String,
        suggestedFollowUpDate: json['suggestedFollowUpDate'] != null
            ? DateTime.parse(json['suggestedFollowUpDate'] as String)
            : null,
      );
}
