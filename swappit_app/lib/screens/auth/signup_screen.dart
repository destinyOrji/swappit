import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/validators.dart';
import '../../services/auth_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import 'verification_screen.dart';
import 'login_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _agreedToTerms = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please agree to the Terms & Privacy Policy')),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final success = await auth.signup(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
    );

    if (mounted && success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => VerificationScreen(email: _emailCtrl.text.trim()),
        ),
      );
    }
  }

  Future<void> _handleGoogleSignUp() async {
    final auth = context.read<AuthProvider>();
    final result = await auth.signInWithGoogle();

    if (mounted && result != null) {
      final isNewUser = result['isNewUser'] == true;
      if (isNewUser) {
        Navigator.pushReplacementNamed(context, '/onboarding');
      } else {
        Navigator.pushReplacementNamed(context, '/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // Header
              Text('Create Account',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      )),
              const SizedBox(height: 6),
              const Text('Start trading skills today — it\'s free.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),

              const SizedBox(height: 32),

              // Google Sign-Up button
              _GoogleButton(
                onTap: _handleGoogleSignUp,
                isLoading: auth.isLoading,
              ),

              const SizedBox(height: 20),

              // Divider
              Row(children: [
                const Expanded(child: Divider(color: AppColors.border)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('or sign up with email',
                      style: TextStyle(color: AppColors.textHint, fontSize: 13)),
                ),
                const Expanded(child: Divider(color: AppColors.border)),
              ]),

              const SizedBox(height: 20),

              // Form fields
              AppTextField(
                controller: _nameCtrl,
                label: 'Full Name',
                hint: 'John Doe',
                prefixIcon: Icons.person_outline_rounded,
                validator: (v) => Validators.required(v, 'Name'),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 14),

              AppTextField(
                controller: _emailCtrl,
                label: 'Email Address',
                hint: 'you@example.com',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: Validators.email,
              ),
              const SizedBox(height: 14),

              AppTextField(
                controller: _phoneCtrl,
                label: 'Phone (optional)',
                hint: '+1 234 567 8900',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: Validators.phone,
              ),
              const SizedBox(height: 14),

              AppTextField(
                controller: _passwordCtrl,
                label: 'Password',
                hint: 'At least 6 characters',
                prefixIcon: Icons.lock_outline_rounded,
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
                validator: Validators.password,
              ),

              const SizedBox(height: 16),

              // Terms checkbox
              Row(
                children: [
                  Checkbox(
                    value: _agreedToTerms,
                    activeColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4)),
                    onChanged: (v) => setState(() => _agreedToTerms = v ?? false),
                  ),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 13),
                        children: [
                          const TextSpan(text: 'I agree to the '),
                          TextSpan(
                            text: 'Terms of Service',
                            style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600),
                          ),
                          const TextSpan(text: ' and '),
                          TextSpan(
                            text: 'Privacy Policy',
                            style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Error
              if (auth.error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppColors.error, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(auth.error!,
                            style: const TextStyle(
                                color: AppColors.error, fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Sign Up button
              AppButton(
                label: 'Create Account',
                onTap: _handleSignUp,
                isLoading: auth.isLoading,
              ),

              const SizedBox(height: 20),

              // Login link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Already have an account? ',
                      style: TextStyle(color: AppColors.textSecondary)),
                  GestureDetector(
                    onTap: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    ),
                    child: const Text('Log In',
                        style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Google Button Widget ─────────────────────────────────
class _GoogleButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isLoading;

  const _GoogleButton({required this.onTap, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Google logo
            Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(shape: BoxShape.circle),
              child: const Text('G',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF4285F4))),
            ),
            const SizedBox(width: 10),
            const Text('Continue with Google',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }
}
