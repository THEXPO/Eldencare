import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/enums.dart';
import '../../providers/care_provider.dart';
import '../../widgets/task_card.dart';

class PatientScheduleScreen extends StatelessWidget {
  const PatientScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final care = context.watch<CareProvider>();
    final patient = care.snapshot.patient;
    final tasks = care.tasksFor(DateTime.now());

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        Text('My schedule', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        const Text(
          'Medicines, meals, and activities for today, in time order.',
        ),
        const SizedBox(height: 16),
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
      ],
    );
  }
}
