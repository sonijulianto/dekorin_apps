import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dekorin_apps/config/theme/app_theme.dart';
import 'package:dekorin_apps/ui/core/widgets/dekorin_text_field.dart';
import 'package:dekorin_apps/ui/features/login/view_models/login_view_model.dart';

/// Login screen for the Dekorin app.
///
/// Displays the brand logo, email/password fields, and a login button.
/// Listens to [loginViewModelProvider] for state changes via Riverpod.
class LoginView extends ConsumerStatefulWidget {
  const LoginView({super.key});

  @override
  ConsumerState<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends ConsumerState<LoginView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Pre-fill kredensial untuk kemudahan testing
    _emailController.text = 'admin@dekorin.com';
    _passwordController.text = 'admin123';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLogin() {
    ref.read(loginViewModelProvider.notifier).clearError();
    ref.read(loginViewModelProvider.notifier).login(
          email: _emailController.text,
          password: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(loginViewModelProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // --- Logo / Brand ---
                  _buildLogo(),
                  const SizedBox(height: 12),
                  Text(
                    'Kelola bisnis dekorasi Anda\ndengan mudah dan efisien',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppTheme.textLight,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // --- Email Field ---
                  DekorinTextField(
                    controller: _emailController,
                    label: 'Email',
                    hint: 'contoh@dekorin.com',
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),

                  // --- Password Field ---
                  DekorinTextField(
                    controller: _passwordController,
                    label: 'Password',
                    hint: 'Masukkan password',
                    prefixIcon: Icons.lock_outline,
                    obscureText: !state.isPasswordVisible,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _onLogin(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        state.isPasswordVisible
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppTheme.textLight,
                      ),
                      onPressed: () {
                        ref
                            .read(loginViewModelProvider.notifier)
                            .togglePasswordVisibility();
                      },
                    ),
                  ),
                  const SizedBox(height: 8),

                  // --- Error Message ---
                  if (state.errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.errorRed.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: AppTheme.errorRed,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              state.errorMessage!,
                              style: const TextStyle(
                                color: AppTheme.errorRed,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),

                  // --- Login Button ---
                  ElevatedButton(
                    onPressed: state.isLoading ? null : _onLogin,
                    child: state.isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Masuk'),
                  ),
                  const SizedBox(height: 24),

                  // --- Quick Role Selector for Easy Testing ---
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pilih Akun Demo / Role:',
                          style: AppTypography.caption.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textLight,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildRoleChip(
                                label: 'Owner',
                                email: 'owner@dekorin.com',
                                pass: 'owner123',
                                color: Colors.purple,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildRoleChip(
                                label: 'Admin',
                                email: 'admin@dekorin.com',
                                pass: 'admin123',
                                color: AppTheme.primaryGold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildRoleChip(
                                label: 'Crew',
                                email: 'crew@dekorin.com',
                                pass: 'crew123',
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- Footer ---
                  Text(
                    '© 2026 Dekorin. All rights reserved.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppTheme.textLight.withValues(alpha: 0.6),
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

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primaryGold, Color(0xFFE8C9A0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryGold.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.auto_awesome,
            color: Colors.white,
            size: 40,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Dekorin',
          style: AppTypography.h1.copyWith(
            fontSize: 32,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildRoleChip({
    required String label,
    required String email,
    required String pass,
    required Color color,
  }) {
    final isSelected = _emailController.text == email;
    return InkWell(
      onTap: () {
        setState(() {
          _emailController.text = email;
          _passwordController.text = pass;
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.bold,
                color: isSelected ? color : AppTheme.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
