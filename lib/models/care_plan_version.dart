import 'diet_entry.dart';
import 'enums.dart';
import 'exercise_entry.dart';
import 'medication.dart';

class CarePlanVersion {
  const CarePlanVersion({
    required this.id,
    required this.patientId,
    required this.versionNumber,
    required this.title,
    required this.doctorName,
    required this.createdAt,
    required this.status,
    required this.summaryOfChanges,
    required this.medications,
    required this.dietEntries,
    required this.exercises,
  });

  final String id;
  final String patientId;
  final int versionNumber;
  final String title;
  final String doctorName;
  final DateTime createdAt;
  final CarePlanStatus status;
  final String summaryOfChanges;
  final List<Medication> medications;
  final List<DietEntry> dietEntries;
  final List<ExerciseEntry> exercises;

  CarePlanVersion copyWith({
    CarePlanStatus? status,
    String? summaryOfChanges,
    String? title,
    List<Medication>? medications,
    List<DietEntry>? dietEntries,
    List<ExerciseEntry>? exercises,
  }) {
    return CarePlanVersion(
      id: id,
      patientId: patientId,
      versionNumber: versionNumber,
      title: title ?? this.title,
      doctorName: doctorName,
      createdAt: createdAt,
      status: status ?? this.status,
      summaryOfChanges: summaryOfChanges ?? this.summaryOfChanges,
      medications: medications ?? this.medications,
      dietEntries: dietEntries ?? this.dietEntries,
      exercises: exercises ?? this.exercises,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'patientId': patientId,
    'versionNumber': versionNumber,
    'title': title,
    'doctorName': doctorName,
    'createdAt': createdAt.toIso8601String(),
    'status': status.name,
    'summaryOfChanges': summaryOfChanges,
    'medications': medications.map((e) => e.toJson()).toList(),
    'dietEntries': dietEntries.map((e) => e.toJson()).toList(),
    'exercises': exercises.map((e) => e.toJson()).toList(),
  };

  factory CarePlanVersion.fromJson(Map<String, dynamic> json) =>
      CarePlanVersion(
        id: json['id'] as String,
        patientId: json['patientId'] as String,
        versionNumber: json['versionNumber'] as int,
        title: json['title'] as String,
        doctorName: json['doctorName'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        status: CarePlanStatus.values.byName(json['status'] as String),
        summaryOfChanges: json['summaryOfChanges'] as String,
        medications: (json['medications'] as List<dynamic>)
            .map((e) => Medication.fromJson(e as Map<String, dynamic>))
            .toList(),
        dietEntries: (json['dietEntries'] as List<dynamic>)
            .map((e) => DietEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
        exercises: (json['exercises'] as List<dynamic>)
            .map((e) => ExerciseEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
