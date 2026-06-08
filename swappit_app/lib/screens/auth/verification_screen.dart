import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pinput/pinput.dart';
import '../../core/theme/app_theme.dart';
import '../../services/auth_provider.dart';
import '../../widgets/app_button.dart';

class VerificationScreen extends StatefulWidget {
  final String email;
  const VerificationScreen({super.key, required this.email});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final _pinCtrl = TextEditingController();
  int _resendCountdown = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_resendCountdown == 0) {
        t.cancel();
      } else {
        setState(() => _resendCountdown--);
      }
    });
  }

  @override
  void dispose() {
    _pinCtrl.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _handleVerify() async {
    if (_pinCtrl.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the 6-digit code')),
      );
      return;
    }
    final auth = context.read<AuthProvider>();
    final success = await auth.verifyOtp(widget.email, _pinCtrl.text);
    if (mounted && success) {
      Navigator.pushReplacementNamed(context, '/onboarding');
    }
  }

  Future<void> _handleResend() async {
    if (_resendCountdown > 0) return;
    final auth = context.read<AuthProvider>();
    // call resendOtp via api directly (not in provider, but you can add it)
    setState(() => _resendCountdown = 60);
    _startCountdown();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('OTP resent to your email')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    final defaultPinTheme = PinTheme(
      width: 56,
      height: 56,
      textStyle: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyDecorationWith(
      border: Border.all(color: AppColors.primary, width: 2),
      color: AppColors.primarySurface,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            // Icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.mark_email_read_outlined,
                  color: AppColors.primary, size: 32),
            ),
            const SizedBox(height: 20),

            Text('Verify Email',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    )),
            const SizedBox(height: 8),
            RichText(
              text: TextSpan(
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 15, height: 1.5),
                children: [
                  const TextSpan(text: 'We sent a 6-digit code to\n'),
                  TextSpan(
                    text: widget.email,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // PIN input
            Center(
              child: Pinput(
                controller: _pinCtrl,
                length: 6,
                defaultPinTheme: defaultPinTheme,
                focusedPinTheme: focusedPinTheme,
                onCompleted: (_) => _handleVerify(),
              ),
            ),

            const SizedBox(height: 32),

            // Error
            if (auth.error != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(children: [
                  const Icon(Icons.error_outline, color: AppColors.error, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(auth.error!,
                        style: const TextStyle(
                            color: AppColors.error, fontSize: 13)),
                  ),
                ]),
              ),

            AppButton(
              label: 'Verify',
              onTap: _handleVerify,
              isLoading: auth.isLoading,
            ),

            const SizedBox(height: 20),

            // Resend
            Center(
              child: GestureDetector(
                onTap: _resendCountdown == 0 ? _handleResend : null,
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 14),
                    children: [
                      const TextSpan(
                        text: "Didn't get a code? ",
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      TextSpan(
                        text: _resendCountdown > 0
                            ? 'Resend in ${_resendCountdown}s'
                            : 'Resend',
                        style: TextStyle(
                          color: _resendCountdown > 0
                              ? AppColors.textHint
                              : AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
