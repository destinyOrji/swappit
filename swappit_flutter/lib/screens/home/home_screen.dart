import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../../services/auth_provider.dart';
import '../../services/api_service.dart';
import '../../models/user_model.dart';
import '../../widgets/user_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _api = ApiService();
  Map<String, dynamic>? _dashboard;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() { _isLoading = true; _hasError = false; });
    try {
      final res = await _api.getDashboard();
      if (mounted) {
        setState(() {
          _dashboard = res['dashboard'];
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() { _isLoading = false; _hasError = true; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final recUsers = (_dashboard?['recommended_users'] as List? ?? []);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _loadDashboard,
          child: CustomScrollView(
            slivers: [
              // ── Header ──────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hi, ${user?.name.split(' ').first ?? 'there'} 👋',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const Text(
                              'What will you swap today?',
                              style: TextStyle(
                                  color: AppColors.textSecondary, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      Stack(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.notifications_outlined,
                                color: AppColors.textPrimary, size: 26),
                            onPressed: () {},
                          ),
                          if ((_dashboard?['unread_notifications'] ?? 0) > 0)
                            const Positioned(
                              right: 8,
                              top: 8,
                              child: CircleAvatar(
                                  radius: 5, backgroundColor: AppColors.accent),
                            ),
                        ],
                      ),
                      const SizedBox(width: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: user?.photoUrl != null
                            ? CachedNetworkImage(
                                imageUrl: user!.photoUrl!,
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                width: 40,
                                height: 40,
                                color: AppColors.primarySurface,
                                child: const Icon(Icons.person_rounded,
                                    color: AppColors.primary, size: 22),
                              ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Stats ────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: _StatsRow(dashboard: _dashboard),
                ),
              ),

              // ── No backend notice ────────────────────────
              if (_hasError)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: _InfoBanner(
                      message: 'Backend not connected. Start your Node.js server to see live data.',
                    ),
                  ),
                ),

              // ── Section title ────────────────────────────
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
                  child: Text(
                    'Recommended for you',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary),
                  ),
                ),
              ),

              // ── User list ────────────────────────────────
              if (_isLoading)
                const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  ),
                )
              else if (recUsers.isEmpty)
                const SliverToBoxAdapter(
                  child: _EmptyRecommendations(),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) {
                        final u = UserModel.fromJson(recUsers[i]);
                        return UserCard(
                          user: u,
                          onTap: () {},
                          onTradeRequest: () {},
                        );
                      },
                      childCount: recUsers.length,
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Stats row ────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final Map<String, dynamic>? dashboard;
  const _StatsRow({this.dashboard});

  @override
  Widget build(BuildContext context) {
    final stats = dashboard?['stats'] as Map? ?? {};
    return Row(
      children: [
        _StatCard(
          label: 'Completed',
          value: '${stats['completed_tasks'] ?? 0}',
          icon: Icons.check_circle_outline_rounded,
          color: AppColors.success,
          bgColor: const Color(0x1A10B981),
        ),
        const SizedBox(width: 10),
        _StatCard(
          label: 'Pending',
          value: '${stats['pending_tasks'] ?? 0}',
          icon: Icons.hourglass_top_rounded,
          color: AppColors.warning,
          bgColor: const Color(0x1AF59E0B),
        ),
        const SizedBox(width: 10),
        _StatCard(
          label: 'Rating',
          value: double.tryParse(stats['rating']?.toString() ?? '4.0')
                  ?.toStringAsFixed(1) ??
              '4.0',
          icon: Icons.star_rounded,
          color: AppColors.primary,
          bgColor: AppColors.primarySurface,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(value,
                style:
                    TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
            Text(label,
                style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _EmptyRecommendations extends StatelessWidget {
  const _EmptyRecommendations();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(Icons.people_outline_rounded, size: 56, color: AppColors.textHint),
          SizedBox(height: 12),
          Text(
            'No recommendations yet.\nAdd wanted skills to get matched!',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final String message;
  const _InfoBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primaryLight),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.primary, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style:
                    const TextStyle(color: AppColors.primary, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
