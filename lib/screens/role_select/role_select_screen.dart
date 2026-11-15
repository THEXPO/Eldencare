import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/enums.dart';
import '../../providers/care_provider.dart';
import '../../providers/role_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ec_card.dart';

class RoleSelectScreen extends StatelessWidget {
  const RoleSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final patient = context.watch<CareProvider>().hasData
        ? context.watch<CareProvider>().snapshot.patient
        : null;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Text(
                'EldenCare',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: EldenColors.teal,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Care, connected. Health, simplified.',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: EldenColors.muted),
              ),
              const SizedBox(height: 16),
              const Text(
                'This is a demo role selector. It is not a login and does not enforce access control.',
                style: TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 28),
              EcCard(
                onTap: () =>
                    context.read<RoleProvider>().select(AppRole.patient),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 28,
                      child: Icon(Icons.favorite_rounded, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Patient mode',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            patient == null
                                ? 'Simple daily view'
                                : 'Continue as ${patient.preferredName}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              EcCard(
                onTap: () =>
                    context.read<RoleProvider>().select(AppRole.caretaker),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 28,
                      child: Icon(Icons.groups_rounded, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Caretaker mode',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            patient == null
                                ? 'Manage the care plan'
                                : 'Continue as ${patient.caretakerName}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              EcCard(
                onTap: () =>
                    context.read<RoleProvider>().select(AppRole.doctor),
                child: const Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      child: Icon(Icons.medical_services_rounded, size: 28),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Doctor mode',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Clinical oversight & care plans (Dr. Sarah Nguyen)',
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
