import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/enums.dart';
import '../../providers/care_provider.dart';
import '../../widgets/section_header.dart';
import '../../widgets/task_card.dart';
import 'diet_form_screen.dart';
import 'exercise_form_screen.dart';
import 'medication_form_screen.dart';

class DailyCareScreen extends StatelessWidget {
  const DailyCareScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final care = context.watch<CareProvider>();
    final patient = care.snapshot.patient;
    final tasks = care.tasksFor(DateTime.now());

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        Text(
          'Daily care',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const Text('Shared schedule plus plan management.'),
        const SectionHeader(title: "Today's unified schedule"),
        ...tasks.map(
          (task) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TaskCard(
              task: task,
              status: care.statusOf(task),
              large: false,
              showBothResponses: true,
              completedLabel: 'Verify it',
              notCompletedLabel: 'Mark not done',
              onCompleted: () => care.confirmTask(
                task: task,
                actor: AppRole.caretaker,
                response: ConfirmationResponse.completed,
                actorName: patient.caretakerName,
              ),
              onNotCompleted: () => care.confirmTask(
                task: task,
                actor: AppRole.caretaker,
                response: ConfirmationResponse.notCompleted,
                actorName: patient.caretakerName,
              ),
            ),
          ),
        ),
        const SectionHeader(title: 'Medications'),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MedicationFormScreen()),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Add medication'),
          ),
        ),
        ...care.snapshot.medications.map(
          (med) => _PlanTile(
            title: '${med.name} ${med.strength}',
            subtitle:
                '${med.dosage} · ${med.dosageForm.label} · ${med.isActive ? 'Active' : 'Inactive'}',
            onEdit: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => MedicationFormScreen(existing: med),
              ),
            ),
            onDelete: () => _confirmDelete(
              context,
              title: 'Remove ${med.name}?',
              onConfirm: () => care.deleteMedication(med.id),
            ),
            extra: med.isActive
                ? TextButton(
                    onPressed: () =>
                        care.upsertMedication(med.copyWith(isActive: false)),
                    child: const Text('Deactivate'),
                  )
                : TextButton(
                    onPressed: () =>
                        care.upsertMedication(med.copyWith(isActive: true)),
                    child: const Text('Reactivate'),
                  ),
          ),
        ),
        const SectionHeader(title: 'Diet plan'),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.icon(
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const DietFormScreen())),
            icon: const Icon(Icons.add),
            label: const Text('Add meal'),
          ),
        ),
        ...care.snapshot.dietEntries.map(
          (entry) => _PlanTile(
            title: entry.title,
            subtitle: '${entry.slot.label} · ${entry.description}',
            onEdit: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => DietFormScreen(existing: entry),
              ),
            ),
            onDelete: () => _confirmDelete(
              context,
              title: 'Remove ${entry.title}?',
              onConfirm: () => care.deleteDiet(entry.id),
            ),
          ),
        ),
        const SectionHeader(title: 'Exercise'),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ExerciseFormScreen()),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Add activity'),
          ),
        ),
        ...care.snapshot.exercises.map(
          (entry) => _PlanTile(
            title: entry.title,
            subtitle: entry.description,
            onEdit: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ExerciseFormScreen(existing: entry),
              ),
            ),
            onDelete: () => _confirmDelete(
              context,
              title: 'Remove ${entry.title}?',
              onConfirm: () => care.deleteExercise(entry.id),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(
    BuildContext context, {
    required String title,
    required Future<void> Function() onConfirm,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: const Text('This cannot be undone in this demo store.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok == true) await onConfirm();
  }
}

class _PlanTile extends StatelessWidget {
  const _PlanTile({
    required this.title,
    required this.subtitle,
    required this.onEdit,
    required this.onDelete,
    this.extra,
  });

  final String title;
  final String subtitle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ?extra,
          IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_outlined)),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }
}
