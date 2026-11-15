import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/care_provider.dart';
import '../../providers/role_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ec_card.dart';
import '../../widgets/section_header.dart';

class DoctorProfileScreen extends StatelessWidget {
  const DoctorProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final care = context.watch<CareProvider>();
    final patientsCount = care.allPatients.length;
    final activePatient = care.snapshot.patient;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        EcCard(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 36,
                  backgroundColor: EldenColors.teal,
                  child: Icon(
                    Icons.medical_services_rounded,
                    size: 36,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Dr. Sarah Nguyen, MD',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Text(
                        'Cardiology & Geriatric Medicine Lead',
                        style: TextStyle(
                          color: EldenColors.muted,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: EldenColors.teal.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Licence #MED-74892 · Verified Physician',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: EldenColors.teal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),
        const SectionHeader(title: 'Clinic & Hospital Affiliation'),
        const EcCard(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Riverside Heart & Elder Care Clinic',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                SizedBox(height: 4),
                Text(
                  'Suite 214, Riverside Health Campus\nOffice Hours: Mon–Thu, 9:00 AM – 4:00 PM\nDirect Line: +1 (555) 019-4820',
                  style: TextStyle(fontSize: 13, color: EldenColors.muted),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),
        const SectionHeader(title: 'Clinical Oversight Overview'),
        EcCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _ProfileRow(
                  label: 'Assigned Elderly Patients',
                  value: '$patientsCount',
                ),
                const Divider(),
                _ProfileRow(
                  label: 'Current Demo Patient Context',
                  value:
                      '${activePatient.fullName} (${activePatient.preferredName})',
                ),
                const Divider(),
                _ProfileRow(
                  label: 'Caretaker Contact for Current Patient',
                  value:
                      '${activePatient.caretakerName} (${activePatient.caretakerRelation})',
                ),
                const Divider(),
                const _ProfileRow(
                  label: 'EHR Synchronization Mode',
                  value: 'Local Shared Ecosystem (Demo)',
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),
        FilledButton.tonalIcon(
          icon: const Icon(Icons.swap_horiz_rounded),
          label: const Text('Switch Role (Return to Role Selector)'),
          onPressed: () => context.read<RoleProvider>().clear(),
        ),
      ],
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: EldenColors.muted),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
