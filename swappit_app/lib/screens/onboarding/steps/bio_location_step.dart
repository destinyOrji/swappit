import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_text_field.dart';

class BioLocationStep extends StatefulWidget {
  final void Function(String? bio, String? location) onNext;
  const BioLocationStep({super.key, required this.onNext});

  @override
  State<BioLocationStep> createState() => _BioLocationStepState();
}

class _BioLocationStepState extends State<BioLocationStep> {
  final _bioCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();

  @override
  void dispose() {
    _bioCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text('Tell us about you',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  )),
          const SizedBox(height: 8),
          const Text('A short bio and your city help others connect with you.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
          const SizedBox(height: 32),

          AppTextField(
            controller: _locationCtrl,
            label: 'Your City / Location',
            hint: 'e.g. New York, USA',
            prefixIcon: Icons.location_on_outlined,
          ),
          const SizedBox(height: 16),

          // Bio field
          TextFormField(
            controller: _bioCtrl,
            maxLines: 4,
            maxLength: 200,
            decoration: InputDecoration(
              labelText: 'Short Bio',
              hintText: 'e.g. I\'m a web developer who loves music...',
              filled: true,
              fillColor: AppColors.surfaceVariant,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
              hintStyle: const TextStyle(color: AppColors.textHint),
              counterStyle: const TextStyle(color: AppColors.textHint),
            ),
          ),

          const Spacer(),

          AppButton(
            label: 'Continue',
            onTap: () => widget.onNext(
              _bioCtrl.text.trim().isEmpty ? null : _bioCtrl.text.trim(),
              _locationCtrl.text.trim().isEmpty
                  ? null
                  : _locationCtrl.text.trim(),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
