import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/user_model.dart';
import '../../../services/api_service.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/skill_chip.dart';

class OfferSkillsStep extends StatefulWidget {
  final void Function(List<int> skillIds) onNext;
  const OfferSkillsStep({super.key, required this.onNext});

  @override
  State<OfferSkillsStep> createState() => _OfferSkillsStepState();
}

class _OfferSkillsStepState extends State<OfferSkillsStep> {
  final _api = ApiService();
  final _searchCtrl = TextEditingController();
  List<SkillModel> _allSkills = [];
  List<SkillModel> _filtered = [];
  final Set<int> _selected = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSkills();
    _searchCtrl.addListener(_onSearch);
  }

  Future<void> _loadSkills() async {
    try {
      final res = await _api.getAllSkills();
      final skills = (res['skills'] as List)
          .map((s) => SkillModel.fromJson(s))
          .toList();
      setState(() {
        _allSkills = skills;
        _filtered = skills;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  void _onSearch() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? _allSkills
          : _allSkills.where((s) => s.name.toLowerCase().contains(q)).toList();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
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
          Text('What can you offer?',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  )),
          const SizedBox(height: 8),
          const Text('Select skills you can teach or provide to others.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
          const SizedBox(height: 20),

          // Search
          TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Search skills...',
              prefixIcon: const Icon(Icons.search, color: AppColors.textHint),
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
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          const SizedBox(height: 16),

          // Selected count
          if (_selected.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('${_selected.length} selected',
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
            ),

          // Skills chips
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _filtered
                        .map((skill) => SkillChip(
                              label: skill.name,
                              isSelected: _selected.contains(skill.id),
                              onTap: () => setState(() {
                                if (_selected.contains(skill.id)) {
                                  _selected.remove(skill.id);
                                } else {
                                  _selected.add(skill.id);
                                }
                              }),
                            ))
                        .toList(),
                  ),
          ),

          const SizedBox(height: 16),
          AppButton(
            label: _selected.isEmpty ? 'Skip for now' : 'Continue',
            onTap: () => widget.onNext(_selected.toList()),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
