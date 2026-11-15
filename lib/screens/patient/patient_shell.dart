import 'package:flutter/material.dart';

import '../../widgets/notification_bell_action.dart';
import '../../widgets/role_switch_chip.dart';
import 'patient_health_screen.dart';
import 'patient_home_screen.dart';
import 'patient_profile_screen.dart';
import 'patient_schedule_screen.dart';

class PatientShell extends StatefulWidget {
  const PatientShell({super.key});

  @override
  State<PatientShell> createState() => _PatientShellState();
}

class _PatientShellState extends State<PatientShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = const [
      PatientHomeScreen(),
      PatientScheduleScreen(),
      PatientHealthScreen(),
      PatientProfileScreen(),
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
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today_rounded),
            label: 'My Schedule',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_outline),
            selectedIcon: Icon(Icons.favorite_rounded),
            label: 'Health',
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
