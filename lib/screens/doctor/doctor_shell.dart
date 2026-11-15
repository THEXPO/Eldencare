import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/care_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/notification_bell_action.dart';
import '../../widgets/role_switch_chip.dart';
import 'doctor_care_plans_screen.dart';
import 'doctor_dashboard_screen.dart';
import 'doctor_patients_screen.dart';
import 'doctor_profile_screen.dart';
import 'doctor_reports_screen.dart';

class DoctorShell extends StatefulWidget {
  const DoctorShell({super.key});

  @override
  State<DoctorShell> createState() => _DoctorShellState();
}

class _DoctorShellState extends State<DoctorShell> {
  int _index = 0;

  void _navigateToTab(int tabIndex) {
    setState(() => _index = tabIndex);
  }

  @override
  Widget build(BuildContext context) {
    final care = context.watch<CareProvider>();
    final activePatient = care.snapshot.patient;

    final pages = [
      DoctorDashboardScreen(onNavigateToTab: _navigateToTab),
      const DoctorPatientsScreen(),
      const DoctorCarePlansScreen(),
      const DoctorReportsScreen(),
      const DoctorProfileScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(
              Icons.local_hospital_rounded,
              color: EldenColors.teal,
              size: 22,
            ),
            const SizedBox(width: 8),
            const Text('EldenCare'),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: EldenColors.teal.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.person, size: 14, color: EldenColors.teal),
                  const SizedBox(width: 4),
                  Text(
                    'Active: ${activePatient.preferredName}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: EldenColors.teal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: const [
          NotificationBellAction(),
          Padding(padding: EdgeInsets.only(right: 12), child: RoleSwitchChip()),
        ],
      ),
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_alt_outlined),
            selectedIcon: Icon(Icons.people_alt_rounded),
            label: 'My Patients',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment_rounded),
            label: 'Care Plans',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics_rounded),
            label: 'Reports',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_pin_outlined),
            selectedIcon: Icon(Icons.person_pin_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
