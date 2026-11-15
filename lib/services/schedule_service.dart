import '../models/care_snapshot.dart';
import '../models/confirmation.dart';
import '../models/daily_task.dart';
import '../models/enums.dart';

class ScheduleService {
  const ScheduleService();

  List<DailyTask> buildDailySchedule(CareSnapshot snapshot, DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    final tasks = <DailyTask>[];

    for (final med in snapshot.medications.where((m) => m.isActiveOn(day))) {
      for (final minutes in med.scheduledTimesMinutes) {
        tasks.add(
          _assemble(
            snapshot: snapshot,
            type: TaskType.medication,
            templateId: med.id,
            title: med.name,
            subtitle: '${med.dosage} · ${med.strength}',
            description: '${med.dosageForm.label} · ${med.mealInstruction}',
            instructions: med.additionalInstructions,
            minutes: minutes,
            day: day,
          ),
        );
      }
    }

    for (final meal in snapshot.dietEntries.where((e) => e.isActive)) {
      tasks.add(
        _assemble(
          snapshot: snapshot,
          type: TaskType.diet,
          templateId: meal.id,
          title: meal.title,
          subtitle: meal.slot.label,
          description: meal.description,
          instructions: meal.instructions,
          minutes: meal.scheduledTimeMinutes,
          day: day,
        ),
      );
    }

    for (final exercise in snapshot.exercises.where((e) => e.isActive)) {
      tasks.add(
        _assemble(
          snapshot: snapshot,
          type: TaskType.exercise,
          templateId: exercise.id,
          title: exercise.title,
          subtitle: 'Physical activity',
          description: exercise.description,
          instructions: exercise.instructions,
          minutes: exercise.scheduledTimeMinutes,
          day: day,
        ),
      );
    }

    tasks.sort(
      (a, b) => a.scheduledTimeMinutes.compareTo(b.scheduledTimeMinutes),
    );
    return tasks;
  }

  DailyTask _assemble({
    required CareSnapshot snapshot,
    required TaskType type,
    required String templateId,
    required String title,
    required String subtitle,
    required String description,
    required String? instructions,
    required int minutes,
    required DateTime day,
  }) {
    final instanceId = DailyTask.buildInstanceId(
      type: type,
      templateId: templateId,
      date: day,
      scheduledTimeMinutes: minutes,
    );
    final records = snapshot.confirmations
        .where((c) => c.taskInstanceId == instanceId)
        .toList();
    records.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    ConfirmationRecord? latestFor(AppRole role) {
      final matches = records.where((c) => c.actor == role);
      return matches.isEmpty ? null : matches.last;
    }

    final patient = latestFor(AppRole.patient);
    final caretaker = latestFor(AppRole.caretaker);

    return DailyTask(
      instanceId: instanceId,
      templateId: templateId,
      type: type,
      title: title,
      subtitle: subtitle,
      description: description,
      scheduledTimeMinutes: minutes,
      date: day,
      dualConfirmationEnabled: snapshot.dualSettings.enabledFor(type),
      patientConfirmation: patient?.response ?? ConfirmationResponse.pending,
      caretakerConfirmation:
          caretaker?.response ?? ConfirmationResponse.pending,
      instructions: instructions,
      patientConfirmedAt: patient?.timestamp,
      caretakerConfirmedAt: caretaker?.timestamp,
      patientActorName: patient?.actorName,
      caretakerActorName: caretaker?.actorName,
    );
  }
}
