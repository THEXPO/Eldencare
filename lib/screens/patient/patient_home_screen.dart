import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/enums.dart';
import '../../providers/care_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/date_utils.dart';
import '../../widgets/ec_card.dart';
import '../../widgets/section_header.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/task_card.dart';

class PatientHomeScreen extends StatelessWidget {
  const PatientHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final care = context.watch<CareProvider>();
    final patient = care.snapshot.patient;
    final today = DateTime.now();
    final tasks = care.tasksFor(today);
    final pending = tasks
        .where(
          (task) =>
              care.statusOf(task) == OverallTaskStatus.awaitingConfirmation &&
              task.patientConfirmation == ConfirmationResponse.pending,
        )
        .toList();
    final nextAppt = care.nextAppointment();
    final hour = today.hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
        ? 'Good afternoon'
        : 'Good evening';

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        Text(
          '$greeting, ${patient.preferredName}',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 4),
        Text(
          AppDateUtils.formatDate(today),
          style: const TextStyle(color: EldenColors.muted, fontSize: 18),
        ),
        const SizedBox(height: 20),
        if (nextAppt != null)
          EcCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Next doctor visit',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
                ),
                const SizedBox(height: 8),
                Text(nextAppt.doctorName, style: const TextStyle(fontSize: 20)),
                Text(nextAppt.speciality),
                Text(AppDateUtils.formatDateTime(nextAppt.dateTime)),
                Text(nextAppt.location),
              ],
            ),
          ),
        const SectionHeader(title: "Today's plan"),
        ...tasks.map(
          (task) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TaskCard(
              task: task,
              status: care.statusOf(task),
              large: true,
              onCompleted: () => care.confirmTask(
                task: task,
                actor: AppRole.patient,
                response: ConfirmationResponse.completed,
                actorName: patient.preferredName,
              ),
              onNotCompleted: () => care.confirmTask(
                task: task,
                actor: AppRole.patient,
                response: ConfirmationResponse.notCompleted,
                actorName: patient.preferredName,
              ),
            ),
          ),
        ),
        const SectionHeader(title: 'Waiting for you'),
        if (pending.isEmpty)
          const Text('You have no pending confirmations right now.')
        else
          ...pending.map(
            (task) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(task.title, style: const TextStyle(fontSize: 20)),
                subtitle: Text(
                  AppDateUtils.formatTimeMinutes(task.scheduledTimeMinutes),
                ),
                trailing: StatusBadge(status: care.statusOf(task)),
              ),
            ),
          ),
      ],
    );
  }
}
