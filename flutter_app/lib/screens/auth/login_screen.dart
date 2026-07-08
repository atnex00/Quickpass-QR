import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _employeeIdCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.isLoading) {
        auth.initialize();
      }
    });
  }

  @override
  void dispose() {
    _employeeIdCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    auth.clearError();
    await auth.login(
      _employeeIdCtrl.text.trim(),
      _passwordCtrl.text,
    );
  }

  void _showForgotPassword() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Reset Password'),
        content: const Text(
          'Contact your HR department or supervisor to reset your password. '
          'They can issue a new password through the admin panel.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Privacy Policy'),
        content: const Text(
          'Your data is handled securely in accordance with company policy. '
          'Access logs are maintained for security purposes. '
          'No personal data is shared with third parties.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSupport() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Internal Support'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Contact the IT Help Desk for support:'),
            SizedBox(height: 12),
            Row(children: [Icon(Icons.email, size: 16), SizedBox(width: 8), Text(AppConstants.supportEmail)]),
            SizedBox(height: 8),
            Row(children: [Icon(Icons.phone, size: 16), SizedBox(width: 8), Text(AppConstants.supportPhone)]),
            SizedBox(height: 8),
            Row(children: [Icon(Icons.access_time, size: 16), SizedBox(width: 8), Text(AppConstants.supportHours)]),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            if (auth.isLoading) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: QuickpassColors.outlineVariant),
                      ),
                      child: Image.asset(
                        'assets/icon/logo.png',
                        height: 56,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Quickpass',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: QuickpassColors.darkPrimary,
                        letterSpacing: -0.01,
                        height: 1.33,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Employee Gatepass System',
                      style: TextStyle(
                        fontSize: 14,
                        color: QuickpassColors.onSurfaceVariant,
                        height: 1.43,
                      ),
                    ),
                    const SizedBox(height: 48),
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: QuickpassColors.darkPrimary,
                      ),
                    ),
                  ],
                ),
              );
            }

            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: QuickpassColors.outlineVariant),
                          ),
                          child: Image.asset(
                            'assets/icon/logo.png',
                            height: 56,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Quickpass',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: QuickpassColors.darkPrimary,
                            letterSpacing: -0.01,
                            height: 1.33,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Sign in to your workplace command center',
                          style: TextStyle(
                            fontSize: 14,
                            color: QuickpassColors.onSurfaceVariant,
                            height: 1.43,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxWidth: 400),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: QuickpassColors.outlineVariant),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Employee ID',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.01,
                                color: QuickpassColors.onSurfaceVariant,
                                height: 1.43,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _employeeIdCtrl,
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                              decoration: InputDecoration(
                                hintText: '6-digit ID',
                                prefixIcon: const Icon(Icons.badge_outlined, color: QuickpassColors.outline),
                                counterText: '',
                                filled: true,
                                fillColor: QuickpassColors.surfaceContainerLow,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: QuickpassColors.outlineVariant),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: QuickpassColors.outlineVariant),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: QuickpassColors.secondary, width: 2),
                                ),
                              ),
                              validator: Validators.employeeId,
                            ),
                            const SizedBox(height: 16),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Password',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.01,
                                    color: QuickpassColors.onSurfaceVariant,
                                    height: 1.43,
                                  ),
                                ),
                                TextButton(
                                  onPressed: _showForgotPassword,
                                  style: TextButton.styleFrom(
                                    foregroundColor: QuickpassColors.secondary,
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text('Forgot?',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: QuickpassColors.secondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _passwordCtrl,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                hintText: '••••••••',
                                prefixIcon: const Icon(Icons.lock_outlined, color: QuickpassColors.outline),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                    color: QuickpassColors.outline,
                                  ),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                                filled: true,
                                fillColor: QuickpassColors.surfaceContainerLow,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: QuickpassColors.outlineVariant),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: QuickpassColors.outlineVariant),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: QuickpassColors.secondary, width: 2),
                                ),
                              ),
                              validator: Validators.password,
                              onFieldSubmitted: (_) => _login(),
                            ),
                            const SizedBox(height: 8),

                            Consumer<AuthProvider>(
                              builder: (context, auth, _) {
                                if (auth.error != null) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: QuickpassColors.errorContainer,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: QuickpassColors.error.withValues(alpha: 0.2)),
                                      ),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Icon(Icons.error_outline, size: 20, color: QuickpassColors.error),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              auth.error!,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                color: QuickpassColors.onErrorContainer,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                            const SizedBox(height: 8),

                            Consumer<AuthProvider>(
                              builder: (context, auth, _) {
                                return SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: FilledButton(
                                    onPressed: auth.loginLoading ? null : _login,
                                    child: auth.loginLoading
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              color: QuickpassColors.darkOnPrimary,
                                            ),
                                          )
                                        : const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                'Sign In',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  height: 1.5,
                                                ),
                                              ),
                                              SizedBox(width: 8),
                                              Icon(Icons.arrow_forward, size: 20, color: QuickpassColors.darkOnPrimary),
                                            ],
                                          ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxWidth: 400),
                      padding: const EdgeInsets.only(top: 16),
                      child: const Column(
                        children: [
                          Divider(color: QuickpassColors.outlineVariant),
                          SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _FooterBadge(icon: Icons.verified_user, label: 'Verified'),
                              SizedBox(width: 24),
                              _FooterBadge(icon: Icons.security, label: 'Secured'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    const Text(
                      'ZANECO QUICKPASS AUTHORITY SYSTEM',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                        color: QuickpassColors.outline,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: _showPrivacyPolicy,
                          style: TextButton.styleFrom(
                            foregroundColor: QuickpassColors.onSurfaceVariant,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('Privacy Policy',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ),
                        const Text('•', style: TextStyle(color: QuickpassColors.outlineVariant)),
                        TextButton(
                          onPressed: _showSupport,
                          style: TextButton.styleFrom(
                            foregroundColor: QuickpassColors.onSurfaceVariant,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('Internal Support',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FooterBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FooterBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: QuickpassColors.outline),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: QuickpassColors.outline,
          ),
        ),
      ],
    );
  }
}
