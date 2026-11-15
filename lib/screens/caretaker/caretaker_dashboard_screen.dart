import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/enums.dart';
import '../../providers/care_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/date_utils.dart';
import '../../widgets/ec_card.dart';
import '../../widgets/section_header.dart';
import '../../widgets/status_badge.dart';

class CaretakerDashboardScreen extends StatelessWidget {
  const CaretakerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final care = context.watch<CareProvider>();
    final patient = care.snapshot.patient;
    final tasks = care.tasksFor(DateTime.now());
    final pending = tasks
        .where(
          (t) => care.statusOf(t) == OverallTaskStatus.awaitingConfirmation,
        )
        .toList();
    final discrepancies = tasks
        .where((t) => care.statusOf(t) == OverallTaskStatus.discrepancy)
        .toList();
    final completed = tasks.where((t) {
      final status = care.statusOf(t);
      return status == OverallTaskStatus.verified ||
          status == OverallTaskStatus.completed;
    }).length;
    final missed = tasks.where((t) {
      final status = care.statusOf(t);
      return status == OverallTaskStatus.verifiedNotCompleted ||
          status == OverallTaskStatus.notCompleted;
    }).length;
    final nextAppt = care.nextAppointment();
    final bp = care.latestBp;
    final glu = care.latestGlucose;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        Text(
          '${patient.preferredName}\'s care',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        Text(
          '${patient.fullName} · ${patient.age} · ${patient.conditions.join(', ')}',
          style: const TextStyle(color: EldenColors.muted),
        ),
        const SizedBox(height: 16),
        if (discrepancies.isNotEmpty)
          EcCard(
            borderColor: EldenColors.discrepancy,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Discrepancies to review',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: EldenColors.discrepancy,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Patient and caretaker responses differ. Original answers are kept. This is a prompt to talk, not a finding of non-compliance.',
                ),
                const SizedBox(height: 8),
                ...discrepancies.map(
                  (task) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(task.title),
                    subtitle: Text(
                      'Patient: ${task.patientConfirmation.label} · Caretaker: ${task.caretakerConfirmation.label}',
                    ),
                    trailing: StatusBadge(status: care.statusOf(task)),
                  ),
                ),
              ],
            ),
          ),
        const SectionHeader(title: "Today at a glance"),
        Row(
          children: [
            _StatChip(label: 'Verified / done', value: '$completed'),
            const SizedBox(width: 8),
            _StatChip(label: 'Missed / not done', value: '$missed'),
            const SizedBox(width: 8),
            _StatChip(label: 'Awaiting', value: '${pending.length}'),
          ],
        ),
        const SectionHeader(title: "Today's medication"),
        ...tasks
            .where((t) => t.type == TaskType.medication)
            .map(
              (task) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Text(
                  AppDateUtils.formatTimeMinutes(task.scheduledTimeMinutes),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                title: Text(task.title),
                subtitle: Text(task.subtitle),
                trailing: StatusBadge(status: care.statusOf(task)),
              ),
            ),
        const SectionHeader(title: 'Pending confirmations'),
        if (pending.isEmpty)
          const Text('No pending confirmations.')
        else
          ...pending.map(
            (task) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(task.title),
              subtitle: Text(
                '${task.type.label} · ${AppDateUtils.formatTimeMinutes(task.scheduledTimeMinutes)}',
              ),
              trailing: StatusBadge(status: care.statusOf(task)),
            ),
          ),
        const SectionHeader(title: 'Latest readings'),
        EcCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                bp == null
                    ? 'No blood pressure yet'
                    : 'BP ${bp.systolic}/${bp.diastolic} · ${AppDateUtils.formatDateTime(bp.recordedAt)}',
              ),
              const SizedBox(height: 8),
              Text(
                glu == null
                    ? 'No glucose yet'
                    : 'Glucose ${glu.value.toStringAsFixed(0)} ${glu.unit.label} · ${AppDateUtils.formatDateTime(glu.recordedAt)}',
              ),
            ],
          ),
        ),
        const SectionHeader(title: 'Upcoming appointment'),
        if (nextAppt == null)
          const Text('None scheduled.')
        else
          EcCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nextAppt.doctorName,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(nextAppt.speciality),
                Text(AppDateUtils.formatDateTime(nextAppt.dateTime)),
                Text(nextAppt.location),
              ],
            ),
          ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: EcCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
