import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ec_card.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();

    final success = await auth.sendPasswordResetEmail(_emailCtrl.text);
    if (success && mounted) {
      setState(() {
        _sent = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: EldenColors.background,
      appBar: AppBar(
        title: const Text('Reset Password'),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: EcCard(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: _sent
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: EldenColors.teal.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.mark_email_read_rounded,
                                size: 48,
                                color: EldenColors.teal,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Check Your Email',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: EldenColors.tealDark,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'We have sent a secure password reset link to ${_emailCtrl.text.trim()}.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 14, color: EldenColors.muted),
                            ),
                            const SizedBox(height: 24),
                            FilledButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Return to Login'),
                            ),
                          ],
                        )
                      : Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Recover Account',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: EldenColors.tealDark,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Enter your registered email address to receive password reset instructions.',
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
                                controller: _emailCtrl,
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(
                                  labelText: 'Email address',
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
                              const SizedBox(height: 24),

                              FilledButton(
                                onPressed: auth.isLoading ? null : _handleReset,
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
                                        'Send Recovery Email',
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
}
