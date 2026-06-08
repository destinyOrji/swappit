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

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    try {
      final res = await _api.getDashboard();
      setState(() {
        _dashboard = res['dashboard'];
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _loadDashboard,
          child: CustomScrollView(
            slivers: [
              // App Bar
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
                            const Text('What will you swap today?',
                                style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 14)),
                          ],
                        ),
                      ),
                      // Notification bell
                      Stack(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.notifications_outlined,
                                color: AppColors.textPrimary, size: 26),
                            onPressed: () {},
                          ),
                          if ((_dashboard?['unread_notifications'] ?? 0) > 0)
                            Positioned(
                              right: 8,
                              top: 8,
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: AppColors.accent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 4),
                      // Avatar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: user?.photoUrl != null
                            ? CachedNetworkImage(
                                imageUrl: user!.photoUrl!,
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover)
                            : Container(
                                width: 40,
                                height: 40,
                                color: AppColors.primarySurface,
                                child: const Icon(Icons.person_rounded,
                                    color: AppColors.primary, size: 22)),
                      ),
                    ],
                  ),
                ),
              ),

              // Stats
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: _StatsRow(dashboard: _dashboard),
                ),
              ),

              // Section title
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
                  child: Text('Recommended for you',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                ),
              ),

              // Users list
              _isLoading
                  ? const SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(
                              color: AppColors.primary),
                        ),
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) {
                            final rec = (_dashboard?['recommended_users']
                                    as List? ??
                                []);
                            if (rec.isEmpty) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(32),
                                  child: Text('No recommendations yet. Add your wanted skills!',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: AppColors.textSecondary)),
                                ),
                              );
                            }
                            final u = UserModel.fromJson(rec[i]);
                            return UserCard(
                              user: u,
                              onTap: () {},
                              onTradeRequest: () {},
                            );
                          },
                          childCount: (_dashboard?['recommended_users'] as List? ?? []).length,
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

class _StatsRow extends StatelessWidget {
  final Map<String, dynamic>? dashboard;
  const _StatsRow({this.dashboard});

  @override
  Widget build(BuildContext context) {
    final stats = dashboard?['stats'] ?? {};
    return Row(
      children: [
        _StatCard(
          label: 'Completed',
          value: '${stats['completed_tasks'] ?? 0}',
          icon: Icons.check_circle_outline_rounded,
          color: AppColors.success,
        ),
        const SizedBox(width: 12),
        _StatCard(
          label: 'Pending',
          value: '${stats['pending_tasks'] ?? 0}',
          icon: Icons.hourglass_top_rounded,
          color: AppColors.warning,
        ),
        const SizedBox(width: 12),
        _StatCard(
          label: 'Rating',
          value: '${double.tryParse(stats['rating']?.toString() ?? '4.0')?.toStringAsFixed(1) ?? '4.0'}',
          icon: Icons.star_rounded,
          color: AppColors.primary,
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

  const _StatCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: color)),
            Text(label,
                style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
