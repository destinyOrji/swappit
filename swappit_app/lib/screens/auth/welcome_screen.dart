import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(flex: 2),

              // Logo / Illustration area
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.swap_horiz_rounded,
                      size: 64, color: Colors.white),
                ),
              ),

              const SizedBox(height: 32),

              // Headline
              const Text(
                'Trade Skills,\nNot Money.',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.15,
                ),
              ),

              const SizedBox(height: 16),

              Text(
                'Swap what you know for what you need. No cash, just community.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.85),
                  height: 1.5,
                ),
              ),

              const Spacer(flex: 3),

              // CTA Buttons
              ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SignUpScreen()),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
                child: const Text('Get Started'),
              ),

              const SizedBox(height: 12),

              OutlinedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white, width: 1.5),
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
                child: const Text('I already have an account'),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
