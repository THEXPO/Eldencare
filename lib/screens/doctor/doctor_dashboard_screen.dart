import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/care_snapshot.dart';
import '../../models/enums.dart';
import '../../providers/care_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/date_utils.dart';
import '../../widgets/ec_card.dart';
import '../../widgets/section_header.dart';
import 'patient_detail_screen.dart';

class DoctorDashboardScreen extends StatelessWidget {
  const DoctorDashboardScreen({super.key, this.onNavigateToTab});

  final void Function(int tabIndex)? onNavigateToTab;

  @override
  Widget build(BuildContext context) {
    final care = context.watch<CareProvider>();
    final allPatients = care.allPatients;
    final activeSnapshot = care.snapshot;
    final activePatient = activeSnapshot.patient;

    // Derived statistics across assigned patients
    final totalPatients = allPatients.length;

    // Patients requiring attention
    // (patients with unreviewed discrepancies, missed medication, or upcoming appointments)
    final attentionPatients = <Map<String, dynamic>>[];
    for (final p in allPatients) {
      final snap = care.getSnapshotFor(p.id);
      final patientDiscrepancies = snap.discrepancies
          .where((d) => !d.isReviewed)
          .toList();
      final missedTasks = snap.confirmations.where(
        (c) => c.response == ConfirmationResponse.notCompleted,
      );
      final nextApt = snap.appointments
          .where((a) => a.dateTime.isAfter(DateTime.now()))
          .toList();

      final reasons = <String>[];
      if (patientDiscrepancies.isNotEmpty) {
        reasons.add(
          '${patientDiscrepancies.length} unreviewed task discrepancy',
        );
      }
      if (missedTasks.isNotEmpty) {
        reasons.add('${missedTasks.length} uncompleted task recorded');
      }
      if (nextApt.isNotEmpty) {
        reasons.add(
          'Upcoming review in ${nextApt.first.dateTime.difference(DateTime.now()).inDays}d',
        );
      }

      if (reasons.isNotEmpty) {
        attentionPatients.add({
          'patient': p,
          'reasons': reasons,
          'snapshot': snap,
        });
      }
    }

    // Care plan reviews count
    final activePlan = care.activeCarePlanFor(activePatient.id);
    final pendingPlanReviews = activePlan == null ? 1 : 0;

    // Recent health updates count
    final totalRecentHealth =
        activeSnapshot.bloodPressureReadings.length +
        activeSnapshot.glucoseReadings.length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Clinical Overview',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: EldenColors.tealDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Dr. Sarah Nguyen, MD · Geriatric & Cardiology Lead',
                    style: TextStyle(color: EldenColors.muted, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 4 Summary Metrics Cards
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 600;
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: isWide ? 4 : 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: isWide ? 1.4 : 1.3,
              children: [
                _SummaryCard(
                  title: 'Assigned Patients',
                  value: '$totalPatients',
                  icon: Icons.people_alt_rounded,
                  color: EldenColors.teal,
                  onTap: () => onNavigateToTab?.call(1),
                ),
                _SummaryCard(
                  title: 'Needs Attention',
                  value: '${attentionPatients.length}',
                  icon: Icons.notification_important_rounded,
                  color: attentionPatients.isNotEmpty
                      ? EldenColors.discrepancy
                      : EldenColors.success,
                  onTap: () => onNavigateToTab?.call(3),
                ),
                _SummaryCard(
                  title: 'Care Plans Active',
                  value: '${allPatients.length - pendingPlanReviews}',
                  icon: Icons.assignment_turned_in_rounded,
                  color: EldenColors.tealDark,
                  onTap: () => onNavigateToTab?.call(2),
                ),
                _SummaryCard(
                  title: 'Health Logs',
                  value: '$totalRecentHealth',
                  icon: Icons.monitor_heart_rounded,
                  color: EldenColors.pending,
                  onTap: () => onNavigateToTab?.call(3),
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 24),
        const SectionHeader(title: 'Patients requiring attention'),
        if (attentionPatients.isEmpty)
          const EcCard(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline, color: EldenColors.success),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'All assigned patients are currently stable with no pending discrepancies.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...attentionPatients.map((item) {
            final p = item['patient'];
            final reasons = (item['reasons'] as List<String>);
            final isCurrentActive = p.id == activePatient.id;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: EcCard(
                borderColor: reasons.any((r) => r.contains('discrepancy'))
                    ? EldenColors.discrepancy.withValues(alpha: 0.6)
                    : EldenColors.warning.withValues(alpha: 0.6),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: EldenColors.teal.withValues(
                              alpha: 0.12,
                            ),
                            child: Text(
                              p.preferredName[0],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: EldenColors.teal,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      p.fullName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                      ),
                                    ),
                                    if (isCurrentActive) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: EldenColors.teal.withValues(
                                            alpha: 0.12,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: const Text(
                                          'Active Context',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: EldenColors.teal,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                Text(
                                  'Age ${p.age} · Caretaker: ${p.caretakerName} (${p.caretakerRelation})',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: EldenColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: reasons
                            .map(
                              (r) => Chip(
                                visualDensity: VisualDensity.compact,
                                labelStyle: const TextStyle(fontSize: 11),
                                backgroundColor: r.contains('discrepancy')
                                    ? EldenColors.discrepancy.withValues(
                                        alpha: 0.1,
                                      )
                                    : EldenColors.warning.withValues(
                                        alpha: 0.1,
                                      ),
                                side: BorderSide.none,
                                label: Text(r),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            icon: const Icon(
                              Icons.arrow_forward_rounded,
                              size: 16,
                            ),
                            label: const Text('Open Patient File'),
                            onPressed: () {
                              care.selectPatient(p.id);
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      PatientDetailScreen(patient: p),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

        const SizedBox(height: 20),
        const SectionHeader(title: 'Recent clinical & adherence activity'),
        _RecentActivityList(snapshot: activeSnapshot),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return EcCard(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: color.withValues(alpha: 0.12),
                  child: Icon(icon, color: color, size: 18),
                ),
                if (onTap != null)
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: EldenColors.muted.withValues(alpha: 0.5),
                  ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: EldenColors.muted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentActivityList extends StatelessWidget {
  const _RecentActivityList({required this.snapshot});

  final CareSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final events = <_ActivityItem>[];

    // Care plan versions
    for (final v in snapshot.carePlanVersions) {
      events.add(
        _ActivityItem(
          title:
              'Care Plan ${v.status.name.toUpperCase()} (v${v.versionNumber})',
          subtitle: '${v.title} by ${v.doctorName} · ${v.summaryOfChanges}',
          timestamp: v.createdAt,
          icon: Icons.assignment_turned_in_rounded,
          color: EldenColors.teal,
        ),
      );
    }

    // Discrepancy events
    for (final d in snapshot.discrepancies) {
      events.add(
        _ActivityItem(
          title: d.isReviewed ? 'Discrepancy Reviewed' : 'Task Discrepancy',
          subtitle:
              '${d.taskTitle} (Patient: ${d.patientResponse.name}, Caretaker: ${d.caretakerResponse.name})${d.isReviewed ? " · Reviewed by ${d.reviewedBy}" : ""}',
          timestamp: d.occurredAt,
          icon: d.isReviewed
              ? Icons.verified_user_rounded
              : Icons.warning_rounded,
          color: d.isReviewed ? EldenColors.success : EldenColors.discrepancy,
        ),
      );
    }

    // Recent BP readings
    for (final bp in snapshot.bloodPressureReadings.take(2)) {
      events.add(
        _ActivityItem(
          title: 'BP Logged: ${bp.systolic}/${bp.diastolic} mmHg',
          subtitle:
              'Recorded by ${bp.recordedBy}${bp.notes != null ? " · ${bp.notes}" : ""}',
          timestamp: bp.recordedAt,
          icon: Icons.favorite_rounded,
          color: EldenColors.tealDark,
        ),
      );
    }

    // Recent Glucose readings
    for (final glu in snapshot.glucoseReadings.take(2)) {
      events.add(
        _ActivityItem(
          title:
              'Glucose Logged: ${glu.value.toStringAsFixed(0)} ${glu.unit.label}',
          subtitle: 'Recorded by ${glu.recordedBy}',
          timestamp: glu.recordedAt,
          icon: Icons.water_drop_rounded,
          color: EldenColors.pending,
        ),
      );
    }

    // Recent confirmations
    for (final c in snapshot.confirmations.take(3)) {
      events.add(
        _ActivityItem(
          title: '${c.actor.name.toUpperCase()}: ${c.response.name}',
          subtitle: 'Confirmed by ${c.actorName}',
          timestamp: c.timestamp,
          icon: c.response == ConfirmationResponse.completed
              ? Icons.check_circle_rounded
              : Icons.cancel_rounded,
          color: c.response == ConfirmationResponse.completed
              ? EldenColors.success
              : EldenColors.warning,
        ),
      );
    }

    // Sort by timestamp descending
    events.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    if (events.isEmpty) {
      return const EcCard(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No recorded clinical activity yet.'),
        ),
      );
    }

    return Column(
      children: events.take(6).map((e) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: EcCard(
            child: ListTile(
              leading: CircleAvatar(
                radius: 18,
                backgroundColor: e.color.withValues(alpha: 0.12),
                child: Icon(e.icon, color: e.color, size: 18),
              ),
              title: Text(
                e.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              subtitle: Text(
                e.subtitle,
                style: const TextStyle(fontSize: 12, color: EldenColors.muted),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Text(
                AppDateUtils.formatDateTime(e.timestamp),
                style: const TextStyle(fontSize: 11, color: EldenColors.muted),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ActivityItem {
  _ActivityItem({
    required this.title,
    required this.subtitle,
    required this.timestamp,
    required this.icon,
    required this.color,
  });

  final String title;
  final String subtitle;
  final DateTime timestamp;
  final IconData icon;
  final Color color;
}
