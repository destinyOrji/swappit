import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/validators.dart';
import '../../services/auth_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import 'signup_screen.dart';

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

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final success =
        await auth.login(_emailCtrl.text.trim(), _passwordCtrl.text);

    if (mounted && success) {
      final isProfileComplete = auth.user?.isProfileComplete ?? false;
      Navigator.pushReplacementNamed(
          context, isProfileComplete ? '/home' : '/onboarding');
    }
  }

  Future<void> _handleGoogleLogin() async {
    final auth = context.read<AuthProvider>();
    final result = await auth.signInWithGoogle();
    if (mounted && result != null) {
      final isNewUser = result['isNewUser'] == true;
      final isProfileComplete = result['isProfileComplete'] == true;
      Navigator.pushReplacementNamed(
        context,
        (isNewUser || !isProfileComplete) ? '/onboarding' : '/home',
      );
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
              Text('Welcome Back',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      )),
              const SizedBox(height: 6),
              const Text('Log in to continue trading skills.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
              const SizedBox(height: 32),

              // Google sign-in
              _GoogleButton(onTap: _handleGoogleLogin, isLoading: auth.isLoading),
              const SizedBox(height: 20),

              Row(children: [
                const Expanded(child: Divider(color: AppColors.border)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('or login with email',
                      style: const TextStyle(
                          color: AppColors.textHint, fontSize: 13)),
                ),
                const Expanded(child: Divider(color: AppColors.border)),
              ]),
              const SizedBox(height: 20),

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
                controller: _passwordCtrl,
                label: 'Password',
                hint: 'Your password',
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

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: const Text('Forgot Password?'),
                ),
              ),

              // Error
              if (auth.error != null) ...[
                const SizedBox(height: 8),
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

              AppButton(
                label: 'Log In',
                onTap: _handleLogin,
                isLoading: auth.isLoading,
              ),

              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account? ",
                      style: TextStyle(color: AppColors.textSecondary)),
                  GestureDetector(
                    onTap: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const SignUpScreen()),
                    ),
                    child: const Text('Sign Up',
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
            const Text('G',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF4285F4))),
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
