import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/care_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ec_card.dart';

class CaretakerJoinScreen extends StatefulWidget {
  const CaretakerJoinScreen({super.key});

  @override
  State<CaretakerJoinScreen> createState() => _CaretakerJoinScreenState();
}

class _CaretakerJoinScreenState extends State<CaretakerJoinScreen> {
  final _codeCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleRedeem(String code) async {
    final auth = context.read<AuthProvider>();
    final care = context.read<CareProvider>();

    final success = await auth.redeemInvitationCode(code);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Successfully connected to patient care workspace!'),
          backgroundColor: EldenColors.teal,
        ),
      );
      // Load shared care data
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
        title: const Text('Caretaker Onboarding'),
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
                        color: EldenColors.teal.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.shield_outlined,
                        size: 48,
                        color: EldenColors.teal,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Patient Access Authorization',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: EldenColors.tealDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Welcome, ${profile?.fullName ?? "Caretaker"}. As a healthcare security safeguard, caretakers cannot access medical records without patient authorization.',
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
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Enter Care Team Invitation Code',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Obtain an invitation code from the patient or family administrator.',
                              style: TextStyle(fontSize: 12, color: EldenColors.muted),
                            ),
                            const SizedBox(height: 16),

                            if (auth.error != null) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: EldenColors.discrepancy.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: EldenColors.discrepancy.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Text(
                                  auth.error!,
                                  style: const TextStyle(
                                    color: EldenColors.discrepancy,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            TextFormField(
                              controller: _codeCtrl,
                              textCapitalization: TextCapitalization.characters,
                              decoration: const InputDecoration(
                                labelText: 'Invitation Code',
                                hintText: 'e.g. ELDEN-CARE-789',
                                prefixIcon: Icon(Icons.key_rounded),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Please enter an invitation code.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),

                            FilledButton.icon(
                              icon: const Icon(Icons.link_rounded),
                              label: auth.isLoading
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Join Patient Care Team'),
                              onPressed: auth.isLoading
                                  ? null
                                  : () {
                                      if (_formKey.currentState!.validate()) {
                                        _handleRedeem(_codeCtrl.text);
                                      }
                                    },
                            ),

                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 8),

                            // Demo Helper Chips
                            Text(
                              'Demo Test Invitation Codes:',
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: EldenColors.muted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                ActionChip(
                                  avatar: const Icon(Icons.person, size: 16),
                                  label: const Text('Eleanor Vance (ELDEN-CARE-789)'),
                                  onPressed: () {
                                    _codeCtrl.text = 'ELDEN-CARE-789';
                                    _handleRedeem('ELDEN-CARE-789');
                                  },
                                ),
                                ActionChip(
                                  avatar: const Icon(Icons.person, size: 16),
                                  label: const Text('Arthur Vance (ELDEN-CARE-456)'),
                                  onPressed: () {
                                    _codeCtrl.text = 'ELDEN-CARE-456';
                                    _handleRedeem('ELDEN-CARE-456');
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
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
