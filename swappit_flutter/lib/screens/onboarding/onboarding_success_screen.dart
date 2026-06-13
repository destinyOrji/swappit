import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class OnboardingSuccessScreen extends StatelessWidget {
  const OnboardingSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(
                  color: Color(0x33FFFFFF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded, size: 56, color: Colors.white),
              ),
              const SizedBox(height: 32),

              const Text(
                "You're all set!",
                style: TextStyle(
                    fontSize: 34, fontWeight: FontWeight.w800, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              const Text(
                "Welcome to Swappit. Your profile is ready — start trading skills with amazing people.",
                style: TextStyle(
                    fontSize: 16, color: Color(0xD9FFFFFF), height: 1.5),
                textAlign: TextAlign.center,
              ),

              const Spacer(),

              ElevatedButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
                child: const Text('Explore Swappit'),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
