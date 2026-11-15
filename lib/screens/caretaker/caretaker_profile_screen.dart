import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/care_provider.dart';
import '../../providers/role_provider.dart';
import '../../widgets/ec_card.dart';

class CaretakerProfileScreen extends StatelessWidget {
  const CaretakerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final care = context.watch<CareProvider>();
    final patient = care.snapshot.patient;
    final settings = care.snapshot.dualSettings;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        Text(
          'Profile',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        EcCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                patient.caretakerName,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
              ),
              Text('${patient.caretakerRelation} of ${patient.fullName}'),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Dual confirmation',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        const SizedBox(height: 8),
        const Text(
          'When enabled, both the patient and caretaker confirm an activity independently.',
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Medications'),
          value: settings.medication,
          onChanged: (value) =>
              care.updateDualSettings(settings.copyWith(medication: value)),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Diet'),
          value: settings.diet,
          onChanged: (value) =>
              care.updateDualSettings(settings.copyWith(diet: value)),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Exercise'),
          value: settings.exercise,
          onChanged: (value) =>
              care.updateDualSettings(settings.copyWith(exercise: value)),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () => context.read<RoleProvider>().clear(),
          child: const Text('Switch demo role'),
        ),
        const SizedBox(height: 12),
        const Text(
          'Role switching is for demonstration only. It is not authentication or access control.',
        ),
      ],
    );
  }
}
