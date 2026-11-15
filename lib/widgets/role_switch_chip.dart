import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/enums.dart';
import '../providers/auth_provider.dart';
import '../providers/care_provider.dart';
import '../providers/notification_provider.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';

/// User account pill displayed in AppBars.
///
/// Replaces the unrestricted role switcher with verified identity display
/// and secure session termination (logout).
class RoleSwitchChip extends StatelessWidget {
  const RoleSwitchChip({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final profile = auth.profile;
    final role = profile?.role;

    final displayName = profile?.fullName ?? 'User';
    final roleLabel = switch (role) {
      AppRole.patient => 'Patient',
      AppRole.caretaker => 'Caretaker',
      AppRole.doctor => 'Doctor',
      null => 'Signed In',
    };

    return ActionChip(
      avatar: CircleAvatar(
        radius: 10,
        backgroundColor: EldenColors.tealDark,
        child: Text(
          displayName.isNotEmpty ? displayName[0] : 'U',
          style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      label: Text('$displayName ($roleLabel)'),
      onPressed: () => _showAccountDialog(context, auth),
    );
  }

  void _showAccountDialog(BuildContext context, AuthProvider auth) {
    final profile = auth.profile;
    final care = context.read<CareProvider>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.account_circle_rounded, color: EldenColors.teal),
            const SizedBox(width: 8),
            const Text('Account & Session'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              profile?.fullName ?? 'EldenCare Member',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              'Role: ${profile?.role.name.toUpperCase() ?? "UNKNOWN"}',
              style: const TextStyle(fontSize: 13, color: EldenColors.muted),
            ),
            if (auth.isDemoMode) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: EldenColors.sand,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Demo Sandbox Session Active',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ],
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              'Session Security',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            ),
            const Text(
              'Logging out clears all local cached patient health data from memory.',
              style: TextStyle(fontSize: 12, color: EldenColors.muted),
            ),
          ],
        ),
        actions: [
          if (auth.isDemoMode)
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _showDemoSwitchDialog(context, auth, care);
              },
              child: const Text('Switch Demo Role'),
            ),
          FilledButton.icon(
            icon: const Icon(Icons.logout_rounded, size: 16),
            label: const Text('Log Out'),
            style: FilledButton.styleFrom(backgroundColor: EldenColors.discrepancy),
            onPressed: () async {
              Navigator.of(ctx).pop();
              care.resetForLogout();
              if (context.mounted) {
                context.read<NotificationProvider>().resetForLogout();
              }
              await NotificationService.instance.clearOnLogout();
              await auth.signOut();
            },
          ),
        ],
      ),
    );
  }

  void _showDemoSwitchDialog(
    BuildContext context,
    AuthProvider auth,
    CareProvider care,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Switch Demo Role (Hackathon Mode)'),
        children: [
          SimpleDialogOption(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await auth.enterDemoMode(AppRole.patient);
              await care.switchWorkspace('default_demo');
            },
            child: const ListTile(
              leading: Icon(Icons.person, color: EldenColors.teal),
              title: Text('Eleanor Vance'),
              subtitle: Text('Patient Mode'),
            ),
          ),
          SimpleDialogOption(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await auth.enterDemoMode(AppRole.caretaker);
              await care.switchWorkspace('default_demo');
            },
            child: const ListTile(
              leading: Icon(Icons.volunteer_activism, color: EldenColors.teal),
              title: Text('Priya Hart'),
              subtitle: Text('Caretaker Mode'),
            ),
          ),
          SimpleDialogOption(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await auth.enterDemoMode(AppRole.doctor);
              await care.switchWorkspace('default_demo');
            },
            child: const ListTile(
              leading: Icon(Icons.medical_services, color: EldenColors.teal),
              title: Text('Dr. Sarah Nguyen, MD'),
              subtitle: Text('Doctor Mode'),
            ),
          ),
        ],
      ),
    );
  }
}
