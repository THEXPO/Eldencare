import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'models/enums.dart';
import 'providers/auth_provider.dart';
import 'providers/care_provider.dart';
import 'providers/role_provider.dart';
import 'screens/auth/caretaker_join_screen.dart';
import 'screens/auth/doctor_approval_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/caretaker/caretaker_shell.dart';
import 'screens/doctor/doctor_shell.dart';
import 'screens/patient/patient_shell.dart';
import 'screens/role_select/role_select_screen.dart';
import 'theme/app_theme.dart';

class EldenCareApp extends StatelessWidget {
  const EldenCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    AppRole? activeRole;

    // Determine active role from AuthProvider if present, else RoleProvider
    final auth = Provider.of<AuthProvider?>(context);
    if (auth != null && auth.isAuthenticated) {
      activeRole = auth.role;
    } else {
      final roleProv = Provider.of<RoleProvider?>(context);
      activeRole = roleProv?.role;
    }

    return MaterialApp(
      title: 'EldenCare',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.forRole(activeRole),
      home: const _Root(),
    );
  }
}

class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final care = context.watch<CareProvider>();
    final auth = Provider.of<AuthProvider?>(context);
    final roleProv = Provider.of<RoleProvider?>(context);

    if (care.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (care.error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(care.error!),
                const SizedBox(height: 12),
                FilledButton(onPressed: care.load, child: const Text('Try again')),
              ],
            ),
          ),
        ),
      );
    }

    // 1. AuthProvider Guarded Navigation (Phase 2 Architecture)
    if (auth != null) {
      if (auth.isLoading) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }

      // Unauthenticated -> Login Screen
      if (auth.status == AuthStatus.unauthenticated || auth.profile == null) {
        return const LoginScreen();
      }

      // Pending Onboarding (Caretaker waiting for invitation or Doctor awaiting credentials)
      if (auth.status == AuthStatus.pendingOnboarding) {
        if (auth.profile!.isCaretaker) {
          return const CaretakerJoinScreen();
        }
        if (auth.profile!.isDoctor) {
          return const DoctorApprovalScreen();
        }
      }

      // Authenticated with Role Guards
      if (auth.status == AuthStatus.authenticated) {
        switch (auth.role) {
          case AppRole.patient:
            return const PatientShell();
          case AppRole.caretaker:
            return const CaretakerShell();
          case AppRole.doctor:
            return const DoctorShell();
          case null:
            return const LoginScreen();
        }
      }

      return const LoginScreen();
    }

    // 2. Fallback to RoleProvider for backward compatibility
    final role = roleProv?.role;
    if (role == null) return const RoleSelectScreen();
    if (role == AppRole.patient) return const PatientShell();
    if (role == AppRole.doctor) return const DoctorShell();
    return const CaretakerShell();
  }
}
