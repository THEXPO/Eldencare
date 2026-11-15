import 'appointment.dart';
import 'care_plan_version.dart';
import 'confirmation.dart';
import 'consultation_note.dart';
import 'diet_entry.dart';
import 'doctor_notification.dart';
import 'exercise_entry.dart';
import 'health_reading.dart';
import 'medication.dart';
import 'patient.dart';

class CareSnapshot {
  const CareSnapshot({
    required this.patient,
    required this.medications,
    required this.dietEntries,
    required this.exercises,
    required this.appointments,
    required this.bloodPressureReadings,
    required this.glucoseReadings,
    required this.confirmations,
    required this.discrepancies,
    required this.dualSettings,
    this.consultationNotes = const [],
    this.carePlanVersions = const [],
    this.notifications = const [],
    this.patientSnapshots = const {},
  });

  final Patient patient;
  final List<Medication> medications;
  final List<DietEntry> dietEntries;
  final List<ExerciseEntry> exercises;
  final List<Appointment> appointments;
  final List<BloodPressureReading> bloodPressureReadings;
  final List<GlucoseReading> glucoseReadings;
  final List<ConfirmationRecord> confirmations;
  final List<DiscrepancyEvent> discrepancies;
  final DualConfirmationSettings dualSettings;
  final List<ConsultationNote> consultationNotes;
  final List<CarePlanVersion> carePlanVersions;
  final List<DoctorNotification> notifications;
  final Map<String, CareSnapshot> patientSnapshots;

  CareSnapshot copyWith({
    Patient? patient,
    List<Medication>? medications,
    List<DietEntry>? dietEntries,
    List<ExerciseEntry>? exercises,
    List<Appointment>? appointments,
    List<BloodPressureReading>? bloodPressureReadings,
    List<GlucoseReading>? glucoseReadings,
    List<ConfirmationRecord>? confirmations,
    List<DiscrepancyEvent>? discrepancies,
    DualConfirmationSettings? dualSettings,
    List<ConsultationNote>? consultationNotes,
    List<CarePlanVersion>? carePlanVersions,
    List<DoctorNotification>? notifications,
    Map<String, CareSnapshot>? patientSnapshots,
  }) {
    return CareSnapshot(
      patient: patient ?? this.patient,
      medications: medications ?? this.medications,
      dietEntries: dietEntries ?? this.dietEntries,
      exercises: exercises ?? this.exercises,
      appointments: appointments ?? this.appointments,
      bloodPressureReadings:
          bloodPressureReadings ?? this.bloodPressureReadings,
      glucoseReadings: glucoseReadings ?? this.glucoseReadings,
      confirmations: confirmations ?? this.confirmations,
      discrepancies: discrepancies ?? this.discrepancies,
      dualSettings: dualSettings ?? this.dualSettings,
      consultationNotes: consultationNotes ?? this.consultationNotes,
      carePlanVersions: carePlanVersions ?? this.carePlanVersions,
      notifications: notifications ?? this.notifications,
      patientSnapshots: patientSnapshots ?? this.patientSnapshots,
    );
  }

  Map<String, dynamic> toJson() => {
    'patient': patient.toJson(),
    'medications': medications.map((e) => e.toJson()).toList(),
    'dietEntries': dietEntries.map((e) => e.toJson()).toList(),
    'exercises': exercises.map((e) => e.toJson()).toList(),
    'appointments': appointments.map((e) => e.toJson()).toList(),
    'bloodPressureReadings': bloodPressureReadings
        .map((e) => e.toJson())
        .toList(),
    'glucoseReadings': glucoseReadings.map((e) => e.toJson()).toList(),
    'confirmations': confirmations.map((e) => e.toJson()).toList(),
    'discrepancies': discrepancies.map((e) => e.toJson()).toList(),
    'dualSettings': dualSettings.toJson(),
    'consultationNotes': consultationNotes.map((e) => e.toJson()).toList(),
    'carePlanVersions': carePlanVersions.map((e) => e.toJson()).toList(),
    'notifications': notifications.map((e) => e.toJson()).toList(),
    'patientSnapshots': patientSnapshots.map((k, v) => MapEntry(k, v.toJson())),
  };

  factory CareSnapshot.fromJson(Map<String, dynamic> json) => CareSnapshot(
    patient: Patient.fromJson(json['patient'] as Map<String, dynamic>),
    medications: (json['medications'] as List<dynamic>)
        .map((e) => Medication.fromJson(e as Map<String, dynamic>))
        .toList(),
    dietEntries: (json['dietEntries'] as List<dynamic>)
        .map((e) => DietEntry.fromJson(e as Map<String, dynamic>))
        .toList(),
    exercises: (json['exercises'] as List<dynamic>)
        .map((e) => ExerciseEntry.fromJson(e as Map<String, dynamic>))
        .toList(),
    appointments: (json['appointments'] as List<dynamic>)
        .map((e) => Appointment.fromJson(e as Map<String, dynamic>))
        .toList(),
    bloodPressureReadings: (json['bloodPressureReadings'] as List<dynamic>)
        .map((e) => BloodPressureReading.fromJson(e as Map<String, dynamic>))
        .toList(),
    glucoseReadings: (json['glucoseReadings'] as List<dynamic>)
        .map((e) => GlucoseReading.fromJson(e as Map<String, dynamic>))
        .toList(),
    confirmations: (json['confirmations'] as List<dynamic>)
        .map((e) => ConfirmationRecord.fromJson(e as Map<String, dynamic>))
        .toList(),
    discrepancies: (json['discrepancies'] as List<dynamic>)
        .map((e) => DiscrepancyEvent.fromJson(e as Map<String, dynamic>))
        .toList(),
    dualSettings: DualConfirmationSettings.fromJson(
      json['dualSettings'] as Map<String, dynamic>,
    ),
    consultationNotes: json['consultationNotes'] != null
        ? (json['consultationNotes'] as List<dynamic>)
              .map((e) => ConsultationNote.fromJson(e as Map<String, dynamic>))
              .toList()
        : const [],
    carePlanVersions: json['carePlanVersions'] != null
        ? (json['carePlanVersions'] as List<dynamic>)
              .map((e) => CarePlanVersion.fromJson(e as Map<String, dynamic>))
              .toList()
        : const [],
    notifications: json['notifications'] != null
        ? (json['notifications'] as List<dynamic>)
              .map(
                (e) => DoctorNotification.fromJson(e as Map<String, dynamic>),
              )
              .toList()
        : const [],
    patientSnapshots: json['patientSnapshots'] != null
        ? (json['patientSnapshots'] as Map<String, dynamic>).map(
            (k, v) =>
                MapEntry(k, CareSnapshot.fromJson(v as Map<String, dynamic>)),
          )
        : const {},
  );
}
