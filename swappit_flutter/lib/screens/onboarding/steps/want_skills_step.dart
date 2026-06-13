import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/user_model.dart';
import '../../../services/api_service.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/skill_chip.dart';

class WantSkillsStep extends StatefulWidget {
  final void Function(List<int> skillIds) onFinish;
  const WantSkillsStep({super.key, required this.onFinish});

  @override
  State<WantSkillsStep> createState() => _WantSkillsStepState();
}

class _WantSkillsStepState extends State<WantSkillsStep> {
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
          Text('What do you want to learn?',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  )),
          const SizedBox(height: 8),
          const Text(
              'Pick skills you\'d like to receive in a trade. This helps us match you.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
          const SizedBox(height: 20),

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

          if (_selected.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('${_selected.length} selected',
                  style: const TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
            ),

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
                              selectedColor: AppColors.accent,
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
            label: 'Finish Setup',
            onTap: () => widget.onFinish(_selected.toList()),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
