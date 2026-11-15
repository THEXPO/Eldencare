import 'package:flutter/material.dart';

import '../../widgets/notification_bell_action.dart';
import '../../widgets/role_switch_chip.dart';
import 'appointments_screen.dart';
import 'caretaker_dashboard_screen.dart';
import 'caretaker_profile_screen.dart';
import 'daily_care_screen.dart';
import 'health_records_screen.dart';

class CaretakerShell extends StatefulWidget {
  const CaretakerShell({super.key});

  @override
  State<CaretakerShell> createState() => _CaretakerShellState();
}

class _CaretakerShellState extends State<CaretakerShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = const [
      CaretakerDashboardScreen(),
      DailyCareScreen(),
      HealthRecordsScreen(),
      AppointmentsScreen(),
      CaretakerProfileScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('EldenCare'),
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
            icon: Icon(Icons.fact_check_outlined),
            selectedIcon: Icon(Icons.fact_check_rounded),
            label: 'Daily Care',
          ),
          NavigationDestination(
            icon: Icon(Icons.monitor_heart_outlined),
            selectedIcon: Icon(Icons.monitor_heart_rounded),
            label: 'Health Records',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_outlined),
            selectedIcon: Icon(Icons.event_rounded),
            label: 'Appointments',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
