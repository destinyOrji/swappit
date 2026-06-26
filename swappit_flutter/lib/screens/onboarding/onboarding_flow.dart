import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../services/auth_provider.dart';
import '../../services/api_service.dart';
import 'steps/profile_photo_step.dart';
import 'steps/bio_location_step.dart';
import 'steps/offer_skills_step.dart';
import 'steps/want_skills_step.dart';
import 'onboarding_success_screen.dart';

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final _pageCtrl = PageController();
  int _currentStep = 0;
  final int _totalSteps = 4;

  // Collected data
  String? _bio;
  String? _location;
  List<int> _offeredSkillIds = [];
  List<int> _wantedSkillIds = [];

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _pageCtrl.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep--);
    }
  }

  Future<void> _finish() async {
    final auth = context.read<AuthProvider>();
    final api = ApiService();

    // Save bio & location
    if (_bio != null || _location != null) {
      await auth.updateProfile({'bio': _bio, 'location': _location});
    }

    // Save skills
    if (_offeredSkillIds.isNotEmpty || _wantedSkillIds.isNotEmpty) {
      await api.updateSkills(_offeredSkillIds, _wantedSkillIds);
    }

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingSuccessScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Step ${_currentStep + 1} of $_totalSteps',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (_currentStep < _totalSteps - 1)
                        TextButton(
                          onPressed: _finish,
                          child: const Text('Skip',
                              style: TextStyle(color: AppColors.textSecondary)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: (_currentStep + 1) / _totalSteps,
                    backgroundColor: AppColors.border,
                    color: AppColors.primary,
                    minHeight: 4,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ),

            // Page content
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  ProfilePhotoStep(onNext: _nextStep),
                  BioLocationStep(
                    onNext: (bio, location) {
                      _bio = bio;
                      _location = location;
                      _nextStep();
                    },
                  ),
                  OfferSkillsStep(
                    onNext: (skillIds) {
                      _offeredSkillIds = skillIds;
                      _nextStep();
                    },
                  ),
                  WantSkillsStep(
                    onFinish: (skillIds) {
                      _wantedSkillIds = skillIds;
                      _finish();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
