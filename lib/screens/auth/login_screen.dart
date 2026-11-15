import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/enums.dart';
import '../../providers/auth_provider.dart';
import '../../providers/care_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ec_card.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final care = context.read<CareProvider>();

    final success = await auth.signInWithEmailAndPassword(
      email: _emailCtrl.text,
      password: _passwordCtrl.text,
    );

    if (success && mounted) {
      // Sync care workspace if patient has specific workspace
      final profile = auth.profile;
      if (profile != null && profile.workspaceId != null) {
        await care.switchWorkspace(profile.workspaceId!);
      } else {
        await care.switchWorkspace('default_demo');
      }
    }
  }

  Future<void> _handleQuickDemo(AppRole role) async {
    final auth = context.read<AuthProvider>();
    final care = context.read<CareProvider>();

    await auth.enterDemoMode(role);
    if (mounted) {
      await care.switchWorkspace('default_demo');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: EldenColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Branding Header
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: EldenColors.teal.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.elderly_rounded,
                        size: 48,
                        color: EldenColors.teal,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'EldenCare',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: EldenColors.tealDark,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Care, connected. Health, simplified.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: EldenColors.muted,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Login Form Card
                  EcCard(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Sign in to your account',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: EldenColors.text,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Access your personalized care dashboard',
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

                            // Email input
                            TextFormField(
                              controller: _emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              autocorrect: false,
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
                            const SizedBox(height: 16),

                            // Password input
                            TextFormField(
                              controller: _passwordCtrl,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: const Icon(Icons.lock_outline_rounded),
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
                                  return 'Please enter your password.';
                                }
                                if (v.length < 6) {
                                  return 'Password must be at least 6 characters.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 10),

                            // Remember me & Forgot Password
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Checkbox(
                                      value: _rememberMe,
                                      activeColor: EldenColors.teal,
                                      onChanged: (val) {
                                        setState(() {
                                          _rememberMe = val ?? true;
                                        });
                                      },
                                    ),
                                    const Text(
                                      'Remember me',
                                      style: TextStyle(fontSize: 13),
                                    ),
                                  ],
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => const ForgotPasswordScreen(),
                                      ),
                                    );
                                  },
                                  child: const Text('Forgot password?'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Submit Button
                            FilledButton(
                              onPressed: auth.isLoading ? null : _handleLogin,
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
                                      'Sign In',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                            const SizedBox(height: 16),

                            // Create account link
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  "Don't have an account? ",
                                  style: TextStyle(color: EldenColors.muted),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => const RegisterScreen(),
                                      ),
                                    );
                                  },
                                  child: const Text('Register here'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Quick Demo Evaluation Bypass
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: EldenColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.play_circle_outline_rounded,
                              size: 18,
                              color: EldenColors.teal,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Instant Demo Profiles',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: EldenColors.tealDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Select a preconfigured role to inspect full care team workflows:',
                          style: TextStyle(fontSize: 12, color: EldenColors.muted),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.person, size: 16),
                                label: const Text('Patient mode', style: TextStyle(fontSize: 12)),
                                onPressed: () => _handleQuickDemo(AppRole.patient),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.volunteer_activism, size: 16),
                                label: const Text('Caretaker mode', style: TextStyle(fontSize: 12)),
                                onPressed: () => _handleQuickDemo(AppRole.caretaker),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.medical_services, size: 16),
                                label: const Text('Doctor mode', style: TextStyle(fontSize: 12)),
                                onPressed: () => _handleQuickDemo(AppRole.doctor),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
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
