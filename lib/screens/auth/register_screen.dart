import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/enums.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ec_card.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  AppRole _selectedRole = AppRole.patient;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();

    final success = await auth.signUp(
      email: _emailCtrl.text,
      password: _passwordCtrl.text,
      fullName: _nameCtrl.text,
      role: _selectedRole,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account successfully created!'),
          backgroundColor: EldenColors.teal,
        ),
      );
      Navigator.of(context).pop(); // Back to auth gate / root
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: EldenColors.background,
      appBar: AppBar(
        title: const Text('Create Account'),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: EcCard(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Join EldenCare',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: EldenColors.tealDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Select your role and enter your details to register.',
                          style: TextStyle(fontSize: 13, color: EldenColors.muted),
                        ),
                        const SizedBox(height: 20),

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
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  color: EldenColors.discrepancy,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    auth.error!,
                                    style: const TextStyle(
                                      color: EldenColors.discrepancy,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Full Name
                        TextFormField(
                          controller: _nameCtrl,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Full name*',
                            prefixIcon: Icon(Icons.person_outline),
                            hintText: 'e.g. Eleanor Vance',
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Please enter your full name.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // Email
                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          autocorrect: false,
                          decoration: const InputDecoration(
                            labelText: 'Email address*',
                            prefixIcon: Icon(Icons.email_outlined),
                            hintText: 'name@example.com',
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Please enter your email.';
                            }
                            if (!v.contains('@') || !v.contains('.')) {
                              return 'Please enter a valid email address.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // Password
                        TextFormField(
                          controller: _passwordCtrl,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Password*',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Please enter a password.';
                            }
                            if (v.length < 6) {
                              return 'Password must be at least 6 characters.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // Confirm Password
                        TextFormField(
                          controller: _confirmPasswordCtrl,
                          obscureText: _obscureConfirm,
                          decoration: InputDecoration(
                            labelText: 'Confirm password*',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirm
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirm = !_obscureConfirm;
                                });
                              },
                            ),
                          ),
                          validator: (v) {
                            if (v != _passwordCtrl.text) {
                              return 'Passwords do not match.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Account Type Selector
                        Text(
                          'Account Type / Primary Role',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),

                        SegmentedButton<AppRole>(
                          segments: const [
                            ButtonSegment(
                              value: AppRole.patient,
                              label: Text('Patient'),
                              icon: Icon(Icons.person, size: 16),
                            ),
                            ButtonSegment(
                              value: AppRole.caretaker,
                              label: Text('Caretaker'),
                              icon: Icon(Icons.volunteer_activism, size: 16),
                            ),
                            ButtonSegment(
                              value: AppRole.doctor,
                              label: Text('Doctor'),
                              icon: Icon(Icons.medical_services, size: 16),
                            ),
                          ],
                          selected: {_selectedRole},
                          onSelectionChanged: (set) {
                            setState(() {
                              _selectedRole = set.first;
                            });
                          },
                        ),
                        const SizedBox(height: 14),

                        // Role notice & Security badge
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: EldenColors.sand.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: EldenColors.border),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.info_outline_rounded,
                                size: 18,
                                color: EldenColors.teal,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _roleExplanation(_selectedRole),
                                  style: const TextStyle(fontSize: 12, height: 1.4),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Submit
                        FilledButton(
                          onPressed: auth.isLoading ? null : _handleRegister,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: auth.isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Complete Registration',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _roleExplanation(AppRole role) {
    switch (role) {
      case AppRole.patient:
        return 'Patient Account: A personal health workspace is created automatically for your medication, meals, and daily confirmations.';
      case AppRole.caretaker:
        return 'Caretaker Account: Access to patient data requires entering a single-use invitation code provided by your patient or family administrator.';
      case AppRole.doctor:
        return 'Doctor Account: Professional credentials or clinical assignment are verified prior to granting care-plan authoring privileges.';
    }
  }
}
