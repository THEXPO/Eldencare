import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/enums.dart';
import '../../providers/care_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/date_utils.dart';
import '../../widgets/ec_card.dart';
import '../../widgets/section_header.dart';
import 'care_plan_editor_screen.dart';

class DoctorCarePlansScreen extends StatefulWidget {
  const DoctorCarePlansScreen({super.key});

  @override
  State<DoctorCarePlansScreen> createState() => _DoctorCarePlansScreenState();
}

class _DoctorCarePlansScreenState extends State<DoctorCarePlansScreen> {
  String? _selectedPatientId;

  @override
  Widget build(BuildContext context) {
    final care = context.watch<CareProvider>();
    final allPatients = care.allPatients;
    final currentPatient = care.snapshot.patient;

    final patientId = _selectedPatientId ?? currentPatient.id;
    final targetPatient = allPatients.firstWhere(
      (p) => p.id == patientId,
      orElse: () => currentPatient,
    );

    final versions = care.carePlanVersionsFor(targetPatient.id);
    final activeVersion = care.activeCarePlanFor(targetPatient.id);

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
                  'Care Plan Management',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: EldenColors.tealDark,
                  ),
                ),
                const Text(
                  'Doctor-approved prescriptions, diet, and physical activity regimens',
                  style: TextStyle(color: EldenColors.muted, fontSize: 13),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Patient Selector Dropdown
        EcCard(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.person_pin_rounded, color: EldenColors.teal),
                const SizedBox(width: 12),
                const Text(
                  'Patient:',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: targetPatient.id,
                      items: allPatients.map((p) {
                        return DropdownMenuItem(
                          value: p.id,
                          child: Text(
                            '${p.fullName} (${p.preferredName})',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedPatientId = val);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SectionHeader(title: 'Active Clinical Care Plan'),
            FilledButton.icon(
              icon: const Icon(Icons.edit_document, size: 16),
              label: const Text('Update Plan'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        CarePlanEditorScreen(patient: targetPatient),
                  ),
                );
              },
            ),
          ],
        ),

        if (activeVersion == null)
          EcCard(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Icon(
                    Icons.assignment_outlined,
                    size: 40,
                    color: EldenColors.muted,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'No active care plan published for ${targetPatient.preferredName}.',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              CarePlanEditorScreen(patient: targetPatient),
                        ),
                      );
                    },
                    child: const Text('Create Initial Plan'),
                  ),
                ],
              ),
            ),
          )
        else
          EcCard(
            borderColor: EldenColors.teal,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: EldenColors.teal,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'v${activeVersion.versionNumber}.0',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            activeVersion.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 17,
                            ),
                          ),
                        ],
                      ),
                      Chip(
                        backgroundColor: EldenColors.success.withValues(
                          alpha: 0.12,
                        ),
                        side: BorderSide.none,
                        label: const Text(
                          'ACTIVE',
                          style: TextStyle(
                            fontSize: 11,
                            color: EldenColors.success,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Approved by: ${activeVersion.doctorName} · Published: ${AppDateUtils.formatDateTime(activeVersion.createdAt)}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: EldenColors.muted,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: EldenColors.mist,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline,
                          size: 16,
                          color: EldenColors.teal,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            activeVersion.summaryOfChanges,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _PlanStat(
                        icon: Icons.medication_rounded,
                        count: '${activeVersion.medications.length}',
                        label: 'Medications',
                      ),
                      _PlanStat(
                        icon: Icons.restaurant_rounded,
                        count: '${activeVersion.dietEntries.length}',
                        label: 'Meal Slots',
                      ),
                      _PlanStat(
                        icon: Icons.directions_walk_rounded,
                        count: '${activeVersion.exercises.length}',
                        label: 'Activities',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

        const SizedBox(height: 24),
        const SectionHeader(title: 'Care Plan Version History & Audit Trail'),
        if (versions.isEmpty)
          const EcCard(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No historical revisions recorded.'),
            ),
          )
        else
          ...versions.map((ver) {
            final isCurrent = ver.status == CarePlanStatus.active;
            final isDraft = ver.status == CarePlanStatus.draft;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: EcCard(
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: isCurrent
                        ? EldenColors.teal.withValues(alpha: 0.12)
                        : (isDraft
                              ? EldenColors.warning.withValues(alpha: 0.12)
                              : EldenColors.muted.withValues(alpha: 0.12)),
                    child: Text(
                      'v${ver.versionNumber}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: isCurrent
                            ? EldenColors.teal
                            : (isDraft
                                  ? EldenColors.warning
                                  : EldenColors.muted),
                      ),
                    ),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          ver.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      Chip(
                        visualDensity: VisualDensity.compact,
                        side: BorderSide.none,
                        backgroundColor: isCurrent
                            ? EldenColors.success.withValues(alpha: 0.1)
                            : (isDraft
                                  ? EldenColors.warning.withValues(alpha: 0.1)
                                  : EldenColors.muted.withValues(alpha: 0.1)),
                        label: Text(
                          ver.status.name.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isCurrent
                                ? EldenColors.success
                                : (isDraft
                                      ? EldenColors.warning
                                      : EldenColors.muted),
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Text(
                    '${ver.doctorName} · ${AppDateUtils.formatDateTime(ver.createdAt)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: EldenColors.muted,
                    ),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Divider(),
                          Text(
                            'Revision notes: ${ver.summaryOfChanges}',
                            style: const TextStyle(
                              fontStyle: FontStyle.italic,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Prescribed Medications in this version:',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          ...ver.medications.map(
                            (m) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(
                                '• ${m.name} ${m.strength} (${m.dosageForm.label}) - ${m.dosage}, ${m.mealInstruction}',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}

class _PlanStat extends StatelessWidget {
  const _PlanStat({
    required this.icon,
    required this.count,
    required this.label,
  });

  final IconData icon;
  final String count;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: EldenColors.teal, size: 22),
        const SizedBox(height: 4),
        Text(
          count,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: EldenColors.muted),
        ),
      ],
    );
  }
}
