import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../../services/auth_provider.dart';
import '../../widgets/skill_chip.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Header
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.surface,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 16),
                      // Avatar
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(50),
                            child: user.photoUrl != null
                                ? CachedNetworkImage(
                                    imageUrl: user.photoUrl!,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover)
                                : Container(
                                    width: 80,
                                    height: 80,
                                    color: Colors.white.withOpacity(0.2),
                                    child: const Icon(Icons.person_rounded,
                                        size: 44, color: Colors.white)),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: AppColors.accent,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white, width: 2),
                              ),
                              child: const Icon(Icons.edit,
                                  size: 12, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(user.name,
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white)),
                          if (user.verified) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.verified_rounded,
                                size: 18, color: Colors.white),
                          ],
                        ],
                      ),
                      if (user.location != null)
                        Text(user.location!,
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: Colors.white),
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      title: const Text('Log out?'),
                      content: const Text('Are you sure you want to log out?'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel')),
                        TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Log out',
                                style: TextStyle(color: AppColors.error))),
                      ],
                    ),
                  );
                  if (confirmed == true && context.mounted) {
                    await context.read<AuthProvider>().logout();
                    Navigator.pushReplacementNamed(context, '/');
                  }
                },
              ),
            ],
          ),

          // Stats
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _stat('${user.completedTasks}', 'Trades Done'),
                  Container(width: 1, height: 40, color: AppColors.border),
                  _stat('${user.pendingTasks}', 'Pending'),
                  Container(width: 1, height: 40, color: AppColors.border),
                  _stat(user.rating.toStringAsFixed(1), 'Rating ⭐'),
                ],
              ),
            ),
          ),

          // Bio
          if (user.bio != null && user.bio!.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('About',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: AppColors.textPrimary)),
                      const SizedBox(height: 6),
                      Text(user.bio!,
                          style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                              height: 1.5)),
                    ],
                  ),
                ),
              ),
            ),

          // Skills Offered
          if (user.skillsOffered.isNotEmpty)
            SliverToBoxAdapter(
              child: _SkillsSection(
                title: 'Skills I Offer 🎓',
                skills: user.skillsOffered.map((s) => s.name).toList(),
                color: AppColors.primary,
              ),
            ),

          // Skills Wanted
          if (user.skillsWanted.isNotEmpty)
            SliverToBoxAdapter(
              child: _SkillsSection(
                title: 'Skills I Want 🌱',
                skills: user.skillsWanted.map((s) => s.name).toList(),
                color: AppColors.accent,
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  Widget _stat(String value, String label) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary)),
        Text(label,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 12)),
      ],
    );
  }
}

class _SkillsSection extends StatelessWidget {
  final String title;
  final List<String> skills;
  final Color color;

  const _SkillsSection(
      {required this.title, required this.skills, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: skills
                .map((s) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(30),
                        border:
                            Border.all(color: color.withOpacity(0.3)),
                      ),
                      child: Text(s,
                          style: TextStyle(
                              fontSize: 13,
                              color: color,
                              fontWeight: FontWeight.w500)),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}
