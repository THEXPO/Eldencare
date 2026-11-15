import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/care_snapshot.dart';
import '../../models/enums.dart';
import '../../models/patient.dart';
import '../../providers/care_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/date_utils.dart';
import '../../widgets/ec_card.dart';
import '../../widgets/section_header.dart';
import '../../widgets/status_badge.dart';
import 'care_plan_editor_screen.dart';
import 'consultation_note_dialog.dart';

class PatientDetailScreen extends StatefulWidget {
  const PatientDetailScreen({super.key, required this.patient});

  final Patient patient;

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final care = context.watch<CareProvider>();
    final snapshot = care.getSnapshotFor(widget.patient.id);
    final isCurrentActive = care.snapshot.patient.id == widget.patient.id;
    final notes = care.consultationNotesFor(widget.patient.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.patient.fullName),
        actions: [
          IconButton(
            tooltip: 'Add consultation note',
            icon: const Icon(Icons.note_add_rounded),
            onPressed: () =>
                ConsultationNoteDialog.show(context, widget.patient),
          ),
          FilledButton.tonalIcon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CarePlanEditorScreen(patient: widget.patient),
                ),
              );
            },
            icon: const Icon(Icons.edit_document, size: 16),
            label: const Text('Edit Plan'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Patient Header Card
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: EcCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: EldenColors.teal.withValues(
                            alpha: 0.12,
                          ),
                          child: Text(
                            widget.patient.preferredName[0],
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: EldenColors.teal,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    widget.patient.fullName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (isCurrentActive)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: EldenColors.teal.withValues(
                                          alpha: 0.12,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'Active Demo Patient',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: EldenColors.teal,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              Text(
                                'Preferred: ${widget.patient.preferredName} · Age ${widget.patient.age} · DOB: ${AppDateUtils.formatDateTime(widget.patient.dateOfBirth).split('·').first.trim()}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: EldenColors.muted,
                                ),
                              ),
                              Text(
                                'Caretaker: ${widget.patient.caretakerName} (${widget.patient.caretakerRelation})',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        if (!isCurrentActive)
                          OutlinedButton.icon(
                            icon: const Icon(Icons.check, size: 16),
                            label: const Text('Set Active'),
                            onPressed: () {
                              care.selectPatient(widget.patient.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Active patient set to ${widget.patient.preferredName}. Patient & Caretaker modes now display this profile.',
                                  ),
                                  backgroundColor: EldenColors.teal,
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: widget.patient.conditions
                          .map(
                            (c) => Chip(
                              visualDensity: VisualDensity.compact,
                              side: BorderSide.none,
                              backgroundColor: EldenColors.mist,
                              labelStyle: const TextStyle(fontSize: 12),
                              label: Text(c),
                            ),
                          )
                          .toList(),
                    ),
                    if (widget.patient.notes != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Clinical notes: ${widget.patient.notes!}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: EldenColors.muted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // Tabs
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: EldenColors.tealDark,
            indicatorColor: EldenColors.tealDark,
            tabs: const [
              Tab(icon: Icon(Icons.assignment_outlined), text: 'Care Plan'),
              Tab(
                icon: Icon(Icons.monitor_heart_outlined),
                text: 'Health Logs',
              ),
              Tab(icon: Icon(Icons.fact_check_outlined), text: 'Adherence'),
              Tab(
                icon: Icon(Icons.note_alt_outlined),
                text: 'Consultation Notes',
              ),
            ],
          ),

          // Tab views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _CarePlanTab(patient: widget.patient, snapshot: snapshot),
                _HealthLogsTab(snapshot: snapshot),
                _AdherenceTab(snapshot: snapshot),
                _ConsultationNotesTab(
                  patient: widget.patient,
                  notes: notes,
                  onAddNote: () =>
                      ConsultationNoteDialog.show(context, widget.patient),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CarePlanTab extends StatelessWidget {
  const _CarePlanTab({required this.patient, required this.snapshot});

  final Patient patient;
  final CareSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SectionHeader(title: 'Active Medications'),
            Text(
              '${snapshot.medications.where((m) => m.isActive).length} active',
              style: const TextStyle(fontSize: 13, color: EldenColors.muted),
            ),
          ],
        ),
        if (snapshot.medications.isEmpty)
          const EcCard(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No active medications prescribed.'),
            ),
          )
        else
          ...snapshot.medications.map((m) {
            final times = m.scheduledTimesMinutes
                .map((min) => AppDateUtils.formatTimeMinutes(min))
                .join(', ');
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: EcCard(
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: EldenColors.sand,
                    child: Icon(
                      Icons.medication_rounded,
                      color: EldenColors.teal,
                    ),
                  ),
                  title: Text(
                    '${m.name} ${m.strength}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    '${m.dosage} (${m.dosageForm.label}) · Times: $times · ${m.mealInstruction}\n${m.additionalInstructions ?? ""}',
                    style: const TextStyle(fontSize: 13),
                  ),
                  trailing: Chip(
                    visualDensity: VisualDensity.compact,
                    backgroundColor: m.isActive
                        ? EldenColors.success.withValues(alpha: 0.1)
                        : EldenColors.muted.withValues(alpha: 0.1),
                    side: BorderSide.none,
                    label: Text(
                      m.isActive ? 'Active' : 'Inactive',
                      style: TextStyle(
                        fontSize: 11,
                        color: m.isActive
                            ? EldenColors.success
                            : EldenColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),

        const SizedBox(height: 16),
        const SectionHeader(title: 'Daily Diet Schedule'),
        if (snapshot.dietEntries.isEmpty)
          const EcCard(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No structured diet plan defined.'),
            ),
          )
        else
          ...snapshot.dietEntries.map((d) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: EcCard(
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: EldenColors.sand,
                    child: Icon(
                      Icons.restaurant_rounded,
                      color: EldenColors.teal,
                    ),
                  ),
                  title: Text(
                    '${d.slot.label}: ${d.title}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    'Time: ${AppDateUtils.formatTimeMinutes(d.scheduledTimeMinutes)}\n${d.description}${d.instructions != null ? "\nNote: ${d.instructions}" : ""}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ),
            );
          }),

        const SizedBox(height: 16),
        const SectionHeader(title: 'Physical Activity & Exercises'),
        if (snapshot.exercises.isEmpty)
          const EcCard(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No exercise routine configured.'),
            ),
          )
        else
          ...snapshot.exercises.map((e) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: EcCard(
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: EldenColors.sand,
                    child: Icon(
                      Icons.directions_walk_rounded,
                      color: EldenColors.teal,
                    ),
                  ),
                  title: Text(
                    e.title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    'Time: ${AppDateUtils.formatTimeMinutes(e.scheduledTimeMinutes)}\n${e.description}${e.instructions != null ? "\nInstructions: ${e.instructions}" : ""}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }
}

class _HealthLogsTab extends StatelessWidget {
  const _HealthLogsTab({required this.snapshot});

  final CareSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SectionHeader(title: 'Blood Pressure Logs (mmHg)'),
        if (snapshot.bloodPressureReadings.isEmpty)
          const EcCard(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No blood pressure readings recorded.'),
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
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    'Logged by ${bp.recordedBy}${bp.notes != null ? " · ${bp.notes}" : ""}',
                    style: const TextStyle(fontSize: 13),
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

        const SizedBox(height: 16),
        const SectionHeader(title: 'Blood Sugar Logs (mg/dL)'),
        if (snapshot.glucoseReadings.isEmpty)
          const EcCard(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No blood sugar readings recorded.'),
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
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    'Logged by ${glu.recordedBy}${glu.notes != null ? " · ${glu.notes}" : ""}',
                    style: const TextStyle(fontSize: 13),
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

class _AdherenceTab extends StatelessWidget {
  const _AdherenceTab({required this.snapshot});

  final CareSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SectionHeader(title: 'Task Confirmation History'),
        if (snapshot.confirmations.isEmpty)
          const EcCard(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No task confirmations logged yet.'),
            ),
          )
        else
          ...snapshot.confirmations.map((c) {
            final isCompleted = c.response == ConfirmationResponse.completed;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: EcCard(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isCompleted
                        ? EldenColors.success.withValues(alpha: 0.12)
                        : EldenColors.warning.withValues(alpha: 0.12),
                    child: Icon(
                      isCompleted ? Icons.check : Icons.close,
                      color: isCompleted
                          ? EldenColors.success
                          : EldenColors.warning,
                    ),
                  ),
                  title: Text(
                    '${c.actor.name.toUpperCase()}: ${isCompleted ? "Completed" : "Not Done"}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    'Confirmed by ${c.actorName} · Task: ${c.taskInstanceId}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: Text(
                    AppDateUtils.formatDateTime(c.timestamp),
                    style: const TextStyle(
                      fontSize: 11,
                      color: EldenColors.muted,
                    ),
                  ),
                ),
              ),
            );
          }),

        const SizedBox(height: 16),
        const SectionHeader(title: 'Discrepancy Events'),
        if (snapshot.discrepancies.isEmpty)
          const EcCard(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No discrepancies recorded for this patient.'),
            ),
          )
        else
          ...snapshot.discrepancies.map((d) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: EcCard(
                borderColor: d.isReviewed
                    ? EldenColors.success.withValues(alpha: 0.5)
                    : EldenColors.discrepancy.withValues(alpha: 0.5),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            d.taskTitle,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          StatusBadge(
                            status: d.isReviewed
                                ? OverallTaskStatus.verified
                                : OverallTaskStatus.discrepancy,
                            large: false,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Patient (${d.patientActorName}): ${d.patientResponse.name} · Caretaker (${d.caretakerActorName}): ${d.caretakerResponse.name}',
                        style: const TextStyle(fontSize: 13),
                      ),
                      if (d.isReviewed) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: EldenColors.success.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Doctor Review (${d.reviewedBy ?? "Dr. Sarah Nguyen"}): ${d.doctorReviewNotes ?? "Reviewed"}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: EldenColors.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }
}

class _ConsultationNotesTab extends StatelessWidget {
  const _ConsultationNotesTab({
    required this.patient,
    required this.notes,
    required this.onAddNote,
  });

  final Patient patient;
  final List<dynamic> notes;
  final VoidCallback onAddNote;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SectionHeader(title: 'Doctor Consultation Notes'),
            FilledButton.icon(
              onPressed: onAddNote,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Note'),
            ),
          ],
        ),
        if (notes.isEmpty)
          const EcCard(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No consultation notes recorded yet.'),
            ),
          )
        else
          ...notes.map((note) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: EcCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            note.doctorName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: EldenColors.tealDark,
                            ),
                          ),
                          Text(
                            AppDateUtils.formatDateTime(note.date),
                            style: const TextStyle(
                              fontSize: 12,
                              color: EldenColors.muted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Observations:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        note.observations,
                        style: const TextStyle(fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Follow-up Instructions:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        note.followUpInstructions,
                        style: const TextStyle(fontSize: 13),
                      ),
                      if (note.suggestedFollowUpDate != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_rounded,
                              size: 14,
                              color: EldenColors.teal,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Suggested next visit: ${AppDateUtils.formatDateTime(note.suggestedFollowUpDate!)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: EldenColors.teal,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }
}
