import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/care_provider.dart';
import '../../providers/role_provider.dart';
import '../../widgets/ec_card.dart';

class PatientProfileScreen extends StatelessWidget {
  const PatientProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final patient = context.watch<CareProvider>().snapshot.patient;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        Text('Profile', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 16),
        EcCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                patient.fullName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text('${patient.age} years old'),
              const SizedBox(height: 12),
              const Text(
                'Conditions',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              Text(patient.conditions.join(', ')),
              const SizedBox(height: 12),
              const Text(
                'Caretaker',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              Text('${patient.caretakerName} · ${patient.caretakerRelation}'),
            ],
          ),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: () => context.read<RoleProvider>().clear(),
          child: const Text('Switch demo role'),
        ),
        const SizedBox(height: 12),
        const Text(
          'Role switching is only for demonstration. Future versions will use a real account for each person.',
        ),
      ],
    );
  }
}
