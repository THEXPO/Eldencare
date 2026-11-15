import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/appointment.dart';
import '../models/care_plan_version.dart';
import '../models/care_snapshot.dart';
import '../models/confirmation.dart';
import '../models/consultation_note.dart';
import '../models/daily_task.dart';
import '../models/diet_entry.dart';
import '../models/doctor_notification.dart';
import '../models/enums.dart';
import '../models/exercise_entry.dart';
import '../models/health_reading.dart';
import '../models/medication.dart';
import '../models/patient.dart';
import '../repositories/care_repository.dart';
import '../repositories/local_care_repository.dart';
import '../services/dual_confirmation_service.dart';
import '../services/duplicate_medication_service.dart';
import '../services/schedule_service.dart';

class CareProvider extends ChangeNotifier {
  CareProvider({
    required CareRepository repository,
    DualConfirmationService dualConfirmation = const DualConfirmationService(),
    DuplicateMedicationService duplicateMedication =
        const DuplicateMedicationService(),
    ScheduleService schedule = const ScheduleService(),
  }) : _repository = repository,
       _dualConfirmation = dualConfirmation,
       _duplicateMedication = duplicateMedication,
       _schedule = schedule;

  CareRepository _repository;
  final DualConfirmationService _dualConfirmation;
  final DuplicateMedicationService _duplicateMedication;
  final ScheduleService _schedule;
  final _uuid = const Uuid();

  CareSnapshot? _snapshot;
  bool _loading = true;
  String? _error;

  bool get isLoading => _loading;
  String? get error => _error;
  CareSnapshot get snapshot {
    final value = _snapshot;
    if (value == null) {
      throw StateError('Care data has not loaded yet.');
    }
    return value;
  }

  bool get hasData => _snapshot != null;

  Future<void> switchWorkspace(String workspaceId) async {
    _repository = LocalCareRepository(workspaceId: workspaceId);
    await load();
  }

  void resetForLogout() {
    _snapshot = null;
    _loading = false;
    _error = null;
    notifyListeners();
  }

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _snapshot = await _repository.load();
    } catch (e, st) {
      debugPrint('CareProvider load error: $e\n$st');
      _error = 'Could not load care data.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  List<DailyTask> tasksFor(DateTime date) =>
      _schedule.buildDailySchedule(snapshot, date);

  OverallTaskStatus statusOf(DailyTask task) => _dualConfirmation.calculate(
    patient: task.patientConfirmation,
    caretaker: task.caretakerConfirmation,
    dualEnabled: task.dualConfirmationEnabled,
  );

  List<DuplicateMedicationMatch> checkMedicationDuplicates(
    Medication candidate,
  ) {
    return _duplicateMedication.findPotentialDuplicates(
      candidate: candidate,
      existing: snapshot.medications,
    );
  }

  Future<void> confirmTask({
    required DailyTask task,
    required AppRole actor,
    required ConfirmationResponse response,
    required String actorName,
  }) async {
    final record = ConfirmationRecord(
      id: _uuid.v4(),
      taskInstanceId: task.instanceId,
      actor: actor,
      response: response,
      timestamp: DateTime.now(),
      actorName: actorName,
    );

    final confirmations = [...snapshot.confirmations, record];
    final patientResponse = actor == AppRole.patient
        ? response
        : task.patientConfirmation;
    final caretakerResponse = actor == AppRole.caretaker
        ? response
        : task.caretakerConfirmation;

    var discrepancies = snapshot.discrepancies;
    final nextStatus = _dualConfirmation.calculate(
      patient: patientResponse,
      caretaker: caretakerResponse,
      dualEnabled: task.dualConfirmationEnabled,
    );
    if (nextStatus == OverallTaskStatus.discrepancy) {
      final alreadyLogged = discrepancies.any(
        (event) =>
            event.taskInstanceId == task.instanceId &&
            event.patientResponse == patientResponse &&
            event.caretakerResponse == caretakerResponse,
      );
      if (!alreadyLogged) {
        discrepancies = [
          ...discrepancies,
          DiscrepancyEvent(
            id: _uuid.v4(),
            taskInstanceId: task.instanceId,
            taskTitle: task.title,
            occurredAt: DateTime.now(),
            patientResponse: patientResponse,
            caretakerResponse: caretakerResponse,
            patientActorName: actor == AppRole.patient
                ? actorName
                : (task.patientActorName ?? snapshot.patient.preferredName),
            caretakerActorName: actor == AppRole.caretaker
                ? actorName
                : (task.caretakerActorName ?? snapshot.patient.caretakerName),
          ),
        ];
      }
    }

    await _commit(
      snapshot.copyWith(
        confirmations: confirmations,
        discrepancies: discrepancies,
      ),
    );
  }

  Future<void> upsertMedication(Medication medication) async {
    final list = [...snapshot.medications];
    final index = list.indexWhere((item) => item.id == medication.id);
    if (index >= 0) {
      list[index] = medication;
    } else {
      list.add(medication);
    }
    await _commit(snapshot.copyWith(medications: list));
  }

  Future<void> deleteMedication(String id) async {
    await _commit(
      snapshot.copyWith(
        medications: snapshot.medications.where((m) => m.id != id).toList(),
      ),
    );
  }

  Future<void> upsertDiet(DietEntry entry) async {
    final list = [...snapshot.dietEntries];
    final index = list.indexWhere((item) => item.id == entry.id);
    if (index >= 0) {
      list[index] = entry;
    } else {
      list.add(entry);
    }
    await _commit(snapshot.copyWith(dietEntries: list));
  }

  Future<void> deleteDiet(String id) async {
    await _commit(
      snapshot.copyWith(
        dietEntries: snapshot.dietEntries.where((e) => e.id != id).toList(),
      ),
    );
  }

  Future<void> upsertExercise(ExerciseEntry entry) async {
    final list = [...snapshot.exercises];
    final index = list.indexWhere((item) => item.id == entry.id);
    if (index >= 0) {
      list[index] = entry;
    } else {
      list.add(entry);
    }
    await _commit(snapshot.copyWith(exercises: list));
  }

  Future<void> deleteExercise(String id) async {
    await _commit(
      snapshot.copyWith(
        exercises: snapshot.exercises.where((e) => e.id != id).toList(),
      ),
    );
  }

  Future<void> upsertAppointment(Appointment appointment) async {
    final list = [...snapshot.appointments];
    final index = list.indexWhere((item) => item.id == appointment.id);
    if (index >= 0) {
      list[index] = appointment;
    } else {
      list.add(appointment);
    }
    list.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    await _commit(snapshot.copyWith(appointments: list));
  }

  Future<void> deleteAppointment(String id) async {
    await _commit(
      snapshot.copyWith(
        appointments: snapshot.appointments.where((a) => a.id != id).toList(),
      ),
    );
  }

  Future<void> addBloodPressure(BloodPressureReading reading) async {
    final list = [...snapshot.bloodPressureReadings, reading]
      ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    await _commit(snapshot.copyWith(bloodPressureReadings: list));
  }

  Future<void> addGlucose(GlucoseReading reading) async {
    final list = [...snapshot.glucoseReadings, reading]
      ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    await _commit(snapshot.copyWith(glucoseReadings: list));
  }

  Future<void> updateDualSettings(DualConfirmationSettings settings) async {
    await _commit(snapshot.copyWith(dualSettings: settings));
  }

  Appointment? nextAppointment({DateTime? from}) {
    final now = from ?? DateTime.now();
    final upcoming =
        snapshot.appointments.where((a) => a.dateTime.isAfter(now)).toList()
          ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return upcoming.isEmpty ? null : upcoming.first;
  }

  BloodPressureReading? get latestBp {
    if (snapshot.bloodPressureReadings.isEmpty) return null;
    final list = [...snapshot.bloodPressureReadings]
      ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    return list.first;
  }

  GlucoseReading? get latestGlucose {
    if (snapshot.glucoseReadings.isEmpty) return null;
    final list = [...snapshot.glucoseReadings]
      ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    return list.first;
  }

  // ---------------------------------------------------------------------------
  // Multi-patient & Doctor Mode Extensions
  // ---------------------------------------------------------------------------

  List<Patient> get allPatients {
    final map = <String, Patient>{snapshot.patient.id: snapshot.patient};
    for (final other in snapshot.patientSnapshots.values) {
      map.putIfAbsent(other.patient.id, () => other.patient);
    }
    return map.values.toList();
  }

  CareSnapshot getSnapshotFor(String patientId) {
    if (patientId == snapshot.patient.id) return snapshot;
    final found = snapshot.patientSnapshots[patientId];
    if (found != null) return found;
    return snapshot;
  }

  Future<void> selectPatient(String patientId) async {
    if (patientId == snapshot.patient.id) return;

    final target = snapshot.patientSnapshots[patientId];
    if (target == null) return;

    // Save current active patient's latest snapshot into patientSnapshots
    final updatedMap = Map<String, CareSnapshot>.from(
      snapshot.patientSnapshots,
    );
    updatedMap[snapshot.patient.id] = snapshot;

    // Set new active snapshot, sharing the updated patientSnapshots map
    final nextSnapshot = target.copyWith(
      patientSnapshots: updatedMap,
      notifications: snapshot.notifications,
    );

    await _commit(nextSnapshot);
  }

  List<ConsultationNote> consultationNotesFor(String patientId) {
    final all = [
      ...snapshot.consultationNotes,
      ...?snapshot.patientSnapshots[patientId]?.consultationNotes,
    ];
    final unique = <String, ConsultationNote>{};
    for (final note in all) {
      if (note.patientId == patientId) {
        unique[note.id] = note;
      }
    }
    final list = unique.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  Future<void> addConsultationNote(ConsultationNote note) async {
    final list = [note, ...snapshot.consultationNotes];
    final notif = DoctorNotification(
      id: _uuid.v4(),
      title: 'Consultation Note Added',
      message:
          '${note.doctorName} recorded consultation notes for ${snapshot.patient.preferredName}.',
      timestamp: DateTime.now(),
      category: 'consultation',
      patientId: note.patientId,
      patientName: snapshot.patient.fullName,
    );

    final notifs = [notif, ...snapshot.notifications];
    await _commit(
      snapshot.copyWith(consultationNotes: list, notifications: notifs),
    );
  }

  List<CarePlanVersion> carePlanVersionsFor(String patientId) {
    final all = [
      ...snapshot.carePlanVersions,
      ...?snapshot.patientSnapshots[patientId]?.carePlanVersions,
    ];
    final unique = <String, CarePlanVersion>{};
    for (final v in all) {
      if (v.patientId == patientId) {
        unique[v.id] = v;
      }
    }
    final list = unique.values.toList()
      ..sort((a, b) => b.versionNumber.compareTo(a.versionNumber));
    return list;
  }

  CarePlanVersion? activeCarePlanFor(String patientId) {
    final list = carePlanVersionsFor(patientId);
    final active = list.where((v) => v.status == CarePlanStatus.active);
    return active.isEmpty ? (list.isEmpty ? null : list.first) : active.first;
  }

  Future<void> saveCarePlanVersion({
    required String title,
    required String summaryOfChanges,
    required bool activate,
    required String doctorName,
    required List<Medication> medications,
    required List<DietEntry> dietEntries,
    required List<ExerciseEntry> exercises,
  }) async {
    final currentVersions = carePlanVersionsFor(snapshot.patient.id);
    final newVersionNumber = currentVersions.isEmpty
        ? 1
        : currentVersions
                  .map((v) => v.versionNumber)
                  .reduce((a, b) => a > b ? a : b) +
              1;

    final updatedVersions = currentVersions.map((v) {
      if (activate && v.status == CarePlanStatus.active) {
        return v.copyWith(status: CarePlanStatus.superseded);
      }
      return v;
    }).toList();

    final newVersion = CarePlanVersion(
      id: _uuid.v4(),
      patientId: snapshot.patient.id,
      versionNumber: newVersionNumber,
      title: title,
      doctorName: doctorName,
      createdAt: DateTime.now(),
      status: activate ? CarePlanStatus.active : CarePlanStatus.draft,
      summaryOfChanges: summaryOfChanges,
      medications: medications,
      dietEntries: dietEntries,
      exercises: exercises,
    );
    updatedVersions.insert(0, newVersion);

    final notif = DoctorNotification(
      id: _uuid.v4(),
      title: activate ? 'Care Plan Activated' : 'Care Plan Draft Saved',
      message:
          '$doctorName ${activate ? "activated" : "saved draft of"} $title (v$newVersionNumber) for ${snapshot.patient.preferredName}.',
      timestamp: DateTime.now(),
      category: 'carePlan',
      patientId: snapshot.patient.id,
      patientName: snapshot.patient.fullName,
    );

    final notifs = [notif, ...snapshot.notifications];

    if (activate) {
      // Immediate reflection in shared patient data
      await _commit(
        snapshot.copyWith(
          medications: medications,
          dietEntries: dietEntries,
          exercises: exercises,
          carePlanVersions: updatedVersions,
          notifications: notifs,
        ),
      );
    } else {
      await _commit(
        snapshot.copyWith(
          carePlanVersions: updatedVersions,
          notifications: notifs,
        ),
      );
    }
  }

  Future<void> reviewDiscrepancy({
    required String discrepancyId,
    required String notes,
    required String doctorName,
  }) async {
    final list = snapshot.discrepancies.map((d) {
      if (d.id == discrepancyId) {
        return d.copyWith(
          doctorReviewNotes: notes,
          reviewedAt: DateTime.now(),
          reviewedBy: doctorName,
        );
      }
      return d;
    }).toList();

    final target = snapshot.discrepancies.firstWhere(
      (d) => d.id == discrepancyId,
    );
    final notif = DoctorNotification(
      id: _uuid.v4(),
      title: 'Discrepancy Reviewed',
      message:
          '$doctorName reviewed discrepancy on "${target.taskTitle}": "$notes"',
      timestamp: DateTime.now(),
      category: 'discrepancy',
      patientId: snapshot.patient.id,
      patientName: snapshot.patient.fullName,
    );

    await _commit(
      snapshot.copyWith(
        discrepancies: list,
        notifications: [notif, ...snapshot.notifications],
      ),
    );
  }

  List<DiscrepancyEvent> get unreviewedDiscrepancies =>
      snapshot.discrepancies.where((d) => !d.isReviewed).toList();

  List<DoctorNotification> get notifications => snapshot.notifications;

  Future<void> _commit(CareSnapshot next) async {
    _snapshot = next;
    notifyListeners();
    await _repository.save(next);
  }
}
