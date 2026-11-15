import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/care_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ec_card.dart';

class DoctorApprovalScreen extends StatefulWidget {
  const DoctorApprovalScreen({super.key});

  @override
  State<DoctorApprovalScreen> createState() => _DoctorApprovalScreenState();
}

class _DoctorApprovalScreenState extends State<DoctorApprovalScreen> {
  final _codeCtrl = TextEditingController();

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleApproveDemo() async {
    final auth = context.read<AuthProvider>();
    final care = context.read<CareProvider>();

    await auth.approveDoctorDemo();
    if (mounted) {
      await care.switchWorkspace('default_demo');
    }
  }

  Future<void> _handleRedeemCode() async {
    if (_codeCtrl.text.trim().isEmpty) return;
    final auth = context.read<AuthProvider>();
    final care = context.read<CareProvider>();

    final success = await auth.redeemInvitationCode(_codeCtrl.text);
    if (success && mounted) {
      await care.switchWorkspace('default_demo');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final profile = auth.profile;

    return Scaffold(
      backgroundColor: EldenColors.background,
      appBar: AppBar(
        title: const Text('Clinical Credential Verification'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => auth.signOut(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: EldenColors.warning.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.medical_services_outlined,
                        size: 48,
                        color: EldenColors.warning,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Doctor Verification Pending',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: EldenColors.tealDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Dr. ${profile?.fullName ?? "Physician"}, selecting "Doctor" during registration is not sufficient authorization to view patient health records or prescribe care plans.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: EldenColors.muted,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),

                  EcCard(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.verified_user_outlined,
                                color: EldenColors.teal,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Credential Verification',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'In a clinical production environment, doctors are authenticated via institutional SSO (NPI, GMC, or hospital federation). For this hackathon demonstration, you can approve demo credentials immediately below:',
                            style: TextStyle(fontSize: 13, color: EldenColors.muted, height: 1.4),
                          ),
                          const SizedBox(height: 20),

                          FilledButton.icon(
                            icon: const Icon(Icons.check_circle_outline_rounded),
                            label: const Text('Approve Doctor Access (Demo Mode)'),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: auth.isLoading ? null : _handleApproveDemo,
                          ),

                          const SizedBox(height: 20),
                          const Divider(),
                          const SizedBox(height: 12),

                          Text(
                            'Or Enter Institutional Clinic Token',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _codeCtrl,
                                  decoration: const InputDecoration(
                                    hintText: 'e.g. DOCTOR-CLINIC-456',
                                    isDense: true,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              FilledButton.tonal(
                                onPressed: auth.isLoading ? null : _handleRedeemCode,
                                child: const Text('Verify'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  TextButton.icon(
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: const Text('Log out and use a different account'),
                    onPressed: () => auth.signOut(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
