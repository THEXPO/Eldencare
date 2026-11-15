import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/enums.dart';
import '../../providers/care_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ec_card.dart';
import '../../widgets/section_header.dart';
import 'consultation_note_dialog.dart';
import 'patient_detail_screen.dart';

class DoctorPatientsScreen extends StatelessWidget {
  const DoctorPatientsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final care = context.watch<CareProvider>();
    final patients = care.allPatients;
    final activePatientId = care.snapshot.patient.id;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Patients',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: EldenColors.tealDark,
                  ),
                ),
                Text(
                  '${patients.length} assigned elderly patients under your clinical care',
                  style: const TextStyle(
                    color: EldenColors.muted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        const SectionHeader(title: 'Assigned Patient Roster'),
        ...patients.map((p) {
          final snap = care.getSnapshotFor(p.id);
          final isActive = p.id == activePatientId;
          final discrepancies = snap.discrepancies
              .where((d) => !d.isReviewed)
              .length;
          final activeMedsCount = snap.medications
              .where((m) => m.isActive)
              .length;
          final latestBp = snap.bloodPressureReadings.isEmpty
              ? 'No BP'
              : '${snap.bloodPressureReadings.first.systolic}/${snap.bloodPressureReadings.first.diastolic}';
          final latestGlu = snap.glucoseReadings.isEmpty
              ? 'No glucose'
              : '${snap.glucoseReadings.first.value.toStringAsFixed(0)} ${snap.glucoseReadings.first.unit.label}';

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: EcCard(
              borderColor: isActive ? EldenColors.teal : null,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PatientDetailScreen(patient: p),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: EldenColors.teal.withValues(
                            alpha: 0.12,
                          ),
                          child: Text(
                            p.preferredName[0],
                            style: const TextStyle(
                              fontSize: 20,
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
                                    p.fullName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                                  if (isActive) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: EldenColors.teal.withValues(
                                          alpha: 0.12,
                                        ),
                                        borderRadius: BorderRadius.circular(6),
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
                        const Icon(Icons.chevron_right_rounded),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: p.conditions
                          .map(
                            (c) => Chip(
                              visualDensity: VisualDensity.compact,
                              side: BorderSide.none,
                              backgroundColor: EldenColors.mist,
                              labelStyle: const TextStyle(fontSize: 11),
                              label: Text(c),
                            ),
                          )
                          .toList(),
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _StatInfo(
                          label: 'Active Meds',
                          value: '$activeMedsCount',
                          icon: Icons.medication_rounded,
                        ),
                        _StatInfo(
                          label: 'Latest BP',
                          value: latestBp,
                          icon: Icons.favorite_rounded,
                        ),
                        _StatInfo(
                          label: 'Latest Glucose',
                          value: latestGlu,
                          icon: Icons.water_drop_rounded,
                        ),
                        if (discrepancies > 0)
                          Chip(
                            visualDensity: VisualDensity.compact,
                            backgroundColor: EldenColors.discrepancy.withValues(
                              alpha: 0.1,
                            ),
                            side: BorderSide.none,
                            avatar: const Icon(
                              Icons.warning_amber_rounded,
                              size: 14,
                              color: EldenColors.discrepancy,
                            ),
                            label: Text(
                              '$discrepancies issue',
                              style: const TextStyle(
                                fontSize: 11,
                                color: EldenColors.discrepancy,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          icon: const Icon(Icons.note_add_outlined, size: 16),
                          label: const Text('Add Note'),
                          onPressed: () =>
                              ConsultationNoteDialog.show(context, p),
                        ),
                        const SizedBox(width: 8),
                        if (!isActive)
                          OutlinedButton.icon(
                            icon: const Icon(Icons.swap_horiz, size: 16),
                            label: const Text('Select for Demo'),
                            onPressed: () {
                              care.selectPatient(p.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Active patient switched to ${p.preferredName}. Patient & Caretaker modes now mirror this patient.',
                                  ),
                                  backgroundColor: EldenColors.teal,
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
      ],
    );
  }
}

class _StatInfo extends StatelessWidget {
  const _StatInfo({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: EldenColors.muted),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: EldenColors.muted),
            ),
          ],
        ),
      ],
    );
  }
}
