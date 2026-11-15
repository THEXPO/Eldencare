import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/care_snapshot.dart';
import '../../models/confirmation.dart';
import '../../models/enums.dart';
import '../../providers/care_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/date_utils.dart';
import '../../widgets/ec_card.dart';
import '../../widgets/section_header.dart';
import '../../widgets/status_badge.dart';

class DoctorReportsScreen extends StatefulWidget {
  const DoctorReportsScreen({super.key});

  @override
  State<DoctorReportsScreen> createState() => _DoctorReportsScreenState();
}

class _DoctorReportsScreenState extends State<DoctorReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final care = context.watch<CareProvider>();
    final snapshot = care.snapshot;
    final patient = snapshot.patient;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Clinical Reports & Adherence'),
            Text(
              'Patient: ${patient.fullName} (${patient.preferredName})',
              style: const TextStyle(fontSize: 12, color: EldenColors.muted),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: EldenColors.tealDark,
          indicatorColor: EldenColors.tealDark,
          tabs: const [
            Tab(
              icon: Icon(Icons.fact_check_rounded),
              text: 'Adherence & Dual Review',
            ),
            Tab(icon: Icon(Icons.favorite_rounded), text: 'Blood Pressure'),
            Tab(icon: Icon(Icons.water_drop_rounded), text: 'Blood Glucose'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _AdherenceReportView(snapshot: snapshot),
          _BloodPressureReportView(snapshot: snapshot),
          _GlucoseReportView(snapshot: snapshot),
        ],
      ),
    );
  }
}

class _AdherenceReportView extends StatelessWidget {
  const _AdherenceReportView({required this.snapshot});

  final CareSnapshot snapshot;

  void _showDiscrepancyReviewDialog(
    BuildContext context,
    DiscrepancyEvent discrepancy,
  ) {
    final notesCtrl = TextEditingController(
      text: discrepancy.doctorReviewNotes ?? '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Review Task Discrepancy'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Task: ${discrepancy.taskTitle}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              'Patient (${discrepancy.patientActorName}): ${discrepancy.patientResponse.name.toUpperCase()}',
              style: const TextStyle(fontSize: 13),
            ),
            Text(
              'Caretaker (${discrepancy.caretakerActorName}): ${discrepancy.caretakerResponse.name.toUpperCase()}',
              style: const TextStyle(fontSize: 13),
            ),
            Text(
              'Occurred: ${AppDateUtils.formatDateTime(discrepancy.occurredAt)}',
              style: const TextStyle(fontSize: 12, color: EldenColors.muted),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: notesCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Doctor Clinical Review Notes',
                hintText:
                    'e.g. Discussed in consultation. Patient took medication with lunch 40 min late.',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.check, size: 16),
            label: const Text('Mark as Reviewed'),
            onPressed: () {
              if (notesCtrl.text.trim().isEmpty) return;
              context.read<CareProvider>().reviewDiscrepancy(
                discrepancyId: discrepancy.id,
                notes: notesCtrl.text.trim(),
                doctorName: 'Dr. Sarah Nguyen, MD',
              );
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final care = context.watch<CareProvider>();
    final todayTasks = care.tasksFor(DateTime.now());

    final verifiedCount = todayTasks
        .where((t) => care.statusOf(t) == OverallTaskStatus.verified)
        .length;
    final pendingCount = todayTasks
        .where(
          (t) => care.statusOf(t) == OverallTaskStatus.awaitingConfirmation,
        )
        .length;
    final discrepancyCount = todayTasks
        .where((t) => care.statusOf(t) == OverallTaskStatus.discrepancy)
        .length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary Cards
        Row(
          children: [
            Expanded(
              child: EcCard(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Text(
                        '$verifiedCount',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: EldenColors.success,
                        ),
                      ),
                      const Text(
                        'Verified',
                        style: TextStyle(
                          fontSize: 12,
                          color: EldenColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: EcCard(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Text(
                        '$pendingCount',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: EldenColors.pending,
                        ),
                      ),
                      const Text(
                        'Awaiting',
                        style: TextStyle(
                          fontSize: 12,
                          color: EldenColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: EcCard(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Text(
                        '$discrepancyCount',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: EldenColors.discrepancy,
                        ),
                      ),
                      const Text(
                        'Discrepancies',
                        style: TextStyle(
                          fontSize: 12,
                          color: EldenColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),
        const SectionHeader(title: 'Discrepancy Review Queue'),
        if (snapshot.discrepancies.isEmpty)
          const EcCard(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No discrepancy events recorded.'),
            ),
          )
        else
          ...snapshot.discrepancies.map((d) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: EcCard(
                borderColor: d.isReviewed
                    ? EldenColors.success.withValues(alpha: 0.4)
                    : EldenColors.discrepancy.withValues(alpha: 0.6),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            d.taskTitle,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Chip(
                            visualDensity: VisualDensity.compact,
                            side: BorderSide.none,
                            backgroundColor: d.isReviewed
                                ? EldenColors.success.withValues(alpha: 0.1)
                                : EldenColors.discrepancy.withValues(
                                    alpha: 0.1,
                                  ),
                            label: Text(
                              d.isReviewed ? 'REVIEWED' : 'PENDING REVIEW',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: d.isReviewed
                                    ? EldenColors.success
                                    : EldenColors.discrepancy,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: EldenColors.sand,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Patient (${d.patientActorName}):',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: EldenColors.muted,
                                    ),
                                  ),
                                  Text(
                                    d.patientResponse.name.toUpperCase(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: EldenColors.mist,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Caretaker (${d.caretakerActorName}):',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: EldenColors.muted,
                                    ),
                                  ),
                                  Text(
                                    d.caretakerResponse.name.toUpperCase(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (d.doctorReviewNotes != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: EldenColors.success.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Doctor Clinical Note (${d.reviewedBy}): ${d.doctorReviewNotes}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: EldenColors.tealDark,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton.icon(
                            icon: const Icon(
                              Icons.rate_review_rounded,
                              size: 16,
                            ),
                            label: Text(
                              d.isReviewed ? 'Edit Note' : 'Review & Add Note',
                            ),
                            onPressed: () =>
                                _showDiscrepancyReviewDialog(context, d),
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
        const SectionHeader(title: "Today's Dual-Confirmation Status"),
        ...todayTasks.map((task) {
          final status = care.statusOf(task);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: EcCard(
              child: ListTile(
                leading: StatusBadge(status: status, large: false),
                title: Text(
                  task.title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'Patient: ${task.patientConfirmation.label} · Caretaker: ${task.caretakerConfirmation.label}',
                ),
                trailing: Text(
                  AppDateUtils.formatTimeMinutes(task.scheduledTimeMinutes),
                  style: const TextStyle(
                    fontSize: 12,
                    color: EldenColors.muted,
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _BloodPressureReportView extends StatelessWidget {
  const _BloodPressureReportView({required this.snapshot});

  final CareSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final readings = [...snapshot.bloodPressureReadings]
      ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SectionHeader(title: 'Blood Pressure Trend (Chronological)'),
        if (readings.length >= 2) ...[
          EcCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                height: 180,
                child: LineChart(
                  LineChartData(
                    minY: 60,
                    maxY: 160,
                    titlesData: const FlTitlesData(show: false),
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: [
                          for (var i = 0; i < readings.length; i++)
                            FlSpot(
                              i.toDouble(),
                              readings[i].systolic.toDouble(),
                            ),
                        ],
                        color: EldenColors.teal,
                        isCurved: true,
                        dotData: const FlDotData(show: true),
                      ),
                      LineChartBarData(
                        spots: [
                          for (var i = 0; i < readings.length; i++)
                            FlSpot(
                              i.toDouble(),
                              readings[i].diastolic.toDouble(),
                            ),
                        ],
                        color: EldenColors.warning,
                        isCurved: true,
                        dotData: const FlDotData(show: true),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.circle, color: EldenColors.teal, size: 10),
              SizedBox(width: 4),
              Text('Systolic', style: TextStyle(fontSize: 12)),
              SizedBox(width: 16),
              Icon(Icons.circle, color: EldenColors.warning, size: 10),
              SizedBox(width: 4),
              Text('Diastolic', style: TextStyle(fontSize: 12)),
            ],
          ),
          const SizedBox(height: 16),
        ],

        const SectionHeader(title: 'Historical Blood Pressure Readings'),
        if (snapshot.bloodPressureReadings.isEmpty)
          const EcCard(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No readings recorded.'),
            ),
          )
        else
          ...snapshot.bloodPressureReadings.map((bp) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: EcCard(
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: EldenColors.sand,
                    child: Icon(
                      Icons.favorite_rounded,
                      color: EldenColors.teal,
                    ),
                  ),
                  title: Text(
                    '${bp.systolic} / ${bp.diastolic} mmHg',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    'Recorded by ${bp.recordedBy}${bp.notes != null ? " · ${bp.notes}" : ""}',
                  ),
                  trailing: Text(
                    AppDateUtils.formatDateTime(bp.recordedAt),
                    style: const TextStyle(
                      fontSize: 12,
                      color: EldenColors.muted,
                    ),
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }
}

class _GlucoseReportView extends StatelessWidget {
  const _GlucoseReportView({required this.snapshot});

  final CareSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final readings = [...snapshot.glucoseReadings]
      ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SectionHeader(title: 'Blood Glucose Trend (Chronological)'),
        if (readings.length >= 2) ...[
          EcCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                height: 180,
                child: LineChart(
                  LineChartData(
                    titlesData: const FlTitlesData(show: false),
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: [
                          for (var i = 0; i < readings.length; i++)
                            FlSpot(i.toDouble(), readings[i].value),
                        ],
                        color: EldenColors.tealDark,
                        isCurved: true,
                        dotData: const FlDotData(show: true),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text(
              'Blood glucose in mg/dL over time',
              style: TextStyle(fontSize: 12, color: EldenColors.muted),
            ),
          ),
          const SizedBox(height: 16),
        ],

        const SectionHeader(title: 'Historical Blood Sugar Readings'),
        if (snapshot.glucoseReadings.isEmpty)
          const EcCard(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No glucose readings recorded.'),
            ),
          )
        else
          ...snapshot.glucoseReadings.map((glu) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: EcCard(
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: EldenColors.sand,
                    child: Icon(
                      Icons.water_drop_rounded,
                      color: EldenColors.teal,
                    ),
                  ),
                  title: Text(
                    '${glu.value.toStringAsFixed(0)} ${glu.unit.label}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    'Recorded by ${glu.recordedBy}${glu.notes != null ? " · ${glu.notes}" : ""}',
                  ),
                  trailing: Text(
                    AppDateUtils.formatDateTime(glu.recordedAt),
                    style: const TextStyle(
                      fontSize: 12,
                      color: EldenColors.muted,
                    ),
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }
}
