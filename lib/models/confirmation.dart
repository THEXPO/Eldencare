import 'enums.dart';

class ConfirmationRecord {
  const ConfirmationRecord({
    required this.id,
    required this.taskInstanceId,
    required this.actor,
    required this.response,
    required this.timestamp,
    required this.actorName,
  });

  final String id;
  final String taskInstanceId;
  final AppRole actor;
  final ConfirmationResponse response;
  final DateTime timestamp;
  final String actorName;

  Map<String, dynamic> toJson() => {
    'id': id,
    'taskInstanceId': taskInstanceId,
    'actor': actor.name,
    'response': response.name,
    'timestamp': timestamp.toIso8601String(),
    'actorName': actorName,
  };

  factory ConfirmationRecord.fromJson(Map<String, dynamic> json) =>
      ConfirmationRecord(
        id: json['id'] as String,
        taskInstanceId: json['taskInstanceId'] as String,
        actor: AppRole.values.byName(json['actor'] as String),
        response: ConfirmationResponse.values.byName(
          json['response'] as String,
        ),
        timestamp: DateTime.parse(json['timestamp'] as String),
        actorName: json['actorName'] as String,
      );
}

class DiscrepancyEvent {
  const DiscrepancyEvent({
    required this.id,
    required this.taskInstanceId,
    required this.taskTitle,
    required this.occurredAt,
    required this.patientResponse,
    required this.caretakerResponse,
    required this.patientActorName,
    required this.caretakerActorName,
    this.doctorReviewNotes,
    this.reviewedAt,
    this.reviewedBy,
  });

  final String id;
  final String taskInstanceId;
  final String taskTitle;
  final DateTime occurredAt;
  final ConfirmationResponse patientResponse;
  final ConfirmationResponse caretakerResponse;
  final String patientActorName;
  final String caretakerActorName;
  final String? doctorReviewNotes;
  final DateTime? reviewedAt;
  final String? reviewedBy;

  bool get isReviewed => reviewedAt != null;

  DiscrepancyEvent copyWith({
    String? doctorReviewNotes,
    DateTime? reviewedAt,
    String? reviewedBy,
  }) {
    return DiscrepancyEvent(
      id: id,
      taskInstanceId: taskInstanceId,
      taskTitle: taskTitle,
      occurredAt: occurredAt,
      patientResponse: patientResponse,
      caretakerResponse: caretakerResponse,
      patientActorName: patientActorName,
      caretakerActorName: caretakerActorName,
      doctorReviewNotes: doctorReviewNotes ?? this.doctorReviewNotes,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'taskInstanceId': taskInstanceId,
    'taskTitle': taskTitle,
    'occurredAt': occurredAt.toIso8601String(),
    'patientResponse': patientResponse.name,
    'caretakerResponse': caretakerResponse.name,
    'patientActorName': patientActorName,
    'caretakerActorName': caretakerActorName,
    'doctorReviewNotes': doctorReviewNotes,
    'reviewedAt': reviewedAt?.toIso8601String(),
    'reviewedBy': reviewedBy,
  };

  factory DiscrepancyEvent.fromJson(Map<String, dynamic> json) =>
      DiscrepancyEvent(
        id: json['id'] as String,
        taskInstanceId: json['taskInstanceId'] as String,
        taskTitle: json['taskTitle'] as String,
        occurredAt: DateTime.parse(json['occurredAt'] as String),
        patientResponse: ConfirmationResponse.values.byName(
          json['patientResponse'] as String,
        ),
        caretakerResponse: ConfirmationResponse.values.byName(
          json['caretakerResponse'] as String,
        ),
        patientActorName: json['patientActorName'] as String,
        caretakerActorName: json['caretakerActorName'] as String,
        doctorReviewNotes: json['doctorReviewNotes'] as String?,
        reviewedAt: json['reviewedAt'] != null
            ? DateTime.parse(json['reviewedAt'] as String)
            : null,
        reviewedBy: json['reviewedBy'] as String?,
      );
}

class DualConfirmationSettings {
  const DualConfirmationSettings({
    this.medication = true,
    this.diet = true,
    this.exercise = true,
  });

  final bool medication;
  final bool diet;
  final bool exercise;

  bool enabledFor(TaskType type) => switch (type) {
    TaskType.medication => medication,
    TaskType.diet => diet,
    TaskType.exercise => exercise,
  };

  DualConfirmationSettings copyWith({
    bool? medication,
    bool? diet,
    bool? exercise,
  }) {
    return DualConfirmationSettings(
      medication: medication ?? this.medication,
      diet: diet ?? this.diet,
      exercise: exercise ?? this.exercise,
    );
  }

  Map<String, dynamic> toJson() => {
    'medication': medication,
    'diet': diet,
    'exercise': exercise,
  };

  factory DualConfirmationSettings.fromJson(Map<String, dynamic> json) =>
      DualConfirmationSettings(
        medication: json['medication'] as bool? ?? true,
        diet: json['diet'] as bool? ?? true,
        exercise: json['exercise'] as bool? ?? true,
      );
}
