import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';
import '../../../core/theme/modern_theme.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/services/cache_service.dart';
import '../../../core/services/connectivity_service.dart';

class HallOfFameScreen extends ConsumerStatefulWidget {
  const HallOfFameScreen({super.key});

  @override
  ConsumerState<HallOfFameScreen> createState() => _HallOfFameScreenState();
}

class _HallOfFameScreenState extends ConsumerState<HallOfFameScreen> {
  Map<String, dynamic>? _stats;
  List<Map<String, dynamic>> _recentAchievements = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Check connectivity
      final connectivityService = ConnectivityService();
      final isOnline = await connectivityService.isOnline();

      // Try to load from cache first
      final cacheKey = 'hall_of_fame_${user.id}';
      if (CacheService.has(cacheKey) && CacheService.isCacheValid(cacheKey, maxAge: const Duration(hours: 1))) {
        final cachedData = CacheService.get<String>(cacheKey);
        if (cachedData != null) {
          final data = jsonDecode(cachedData);
          setState(() {
            _stats = Map<String, dynamic>.from(data['stats']);
            _recentAchievements = (data['achievements'] as List).cast<Map<String, dynamic>>();
            _isLoading = false;
          });
          
          // If online, refresh in background
          if (isOnline) {
            _fetchFreshData(user.id, cacheKey);
          }
          return;
        }
      }

      // If no cache or offline, try to fetch fresh data
      if (!isOnline) {
        throw Exception('NO_INTERNET');
      }

      await _fetchFreshData(user.id, cacheKey);
    } catch (e) {
      // User-friendly error messages
      String errorMessage;
      if (e.toString().contains('NO_INTERNET')) {
        errorMessage = 'No internet connection. Please check your network and try again.';
      } else if (e.toString().contains('User not authenticated')) {
        errorMessage = 'Please log in to view your achievements.';
      } else if (e.toString().contains('relation') || e.toString().contains('does not exist')) {
        errorMessage = 'Achievements feature is not yet configured. Please check back later.';
      } else {
        errorMessage = 'Unable to load achievements. Please try again later.';
      }
      
      setState(() {
        _error = errorMessage;
        _isLoading = false;
      });
      debugPrint('Error loading hall of fame: $e');
    }
  }

  Future<void> _fetchFreshData(String userId, String cacheKey) async {
    try {
      // Fetch profile stats
      final profileResponse = await SupabaseConfig.client
          .from('profiles')
          .select('xp_points, level')
          .eq('user_id', userId)
          .maybeSingle();

      // Fetch user achievements count
      final achievementsCountResponse = await SupabaseConfig.client
          .from('user_achievements')
          .select('achievement_id')
          .eq('user_id', userId);

      // Fetch total achievements count
      final totalAchievementsResponse = await SupabaseConfig.client
          .from('achievements')
          .select('id');

      // Fetch recent achievements with details
      final recentResponse = await SupabaseConfig.client
          .from('user_achievements')
          .select('''
            earned_at,
            achievements (
              id,
              name,
              description,
              icon,
              xp_reward,
              category
            )
          ''')
          .eq('user_id', userId)
          .order('earned_at', ascending: false)
          .limit(6);

      final stats = {
        'level': profileResponse?['level'] ?? 1,
        'xp_points': profileResponse?['xp_points'] ?? 0,
        'earned_count': (achievementsCountResponse as List).length,
        'total_count': (totalAchievementsResponse as List).length,
      };
      final achievements = (recentResponse as List).cast<Map<String, dynamic>>();

      // Cache the data
      await CacheService.set(
        cacheKey,
        jsonEncode({
          'stats': stats,
          'achievements': achievements,
        }),
        duration: const Duration(hours: 1),
      );

      setState(() {
        _stats = stats;
        _recentAchievements = achievements;
        _isLoading = false;
      });
    } catch (e) {
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          // App Bar with Gradient
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      ModernTheme.primaryOrange,
                      const Color(0xFFFF6B9D),
                      const Color(0xFF8B5CF6),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    // Decorative circles
                    Positioned(
                      top: -50,
                      right: -50,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -30,
                      left: -30,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                    // Content
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 40),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Iconsax.cup5,
                              size: 48,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Hall of Fame',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your Achievements & Progress',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Content
          if (_isLoading)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      color: ModernTheme.primaryOrange,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Loading your achievements...',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            )
          else if (_error != null)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _error!.contains('internet') ? Iconsax.wifi_square : Iconsax.warning_2,
                      size: 64,
                      color: Theme.of(context).colorScheme.error.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _error!.contains('internet') ? 'No Internet Connection' : 'Error Loading',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        _error!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _loadData,
                      icon: const Icon(Iconsax.refresh),
                      label: const Text('Retry'),
                      style: FilledButton.styleFrom(
                        backgroundColor: ModernTheme.primaryOrange,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Stats Cards
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Iconsax.cup,
                          label: 'Level',
                          value: '${_stats!['level']}',
                          color: ModernTheme.primaryOrange,
                        ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.2),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          icon: Iconsax.star5,
                          label: 'Total XP',
                          value: '${_stats!['xp_points']}',
                          color: const Color(0xFFFFD700),
                        ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideX(begin: -0.2),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _StatCard(
                    icon: Iconsax.medal_star,
                    label: 'Achievements',
                    value: '${_stats!['earned_count']}/${_stats!['total_count']}',
                    color: const Color(0xFF8B5CF6),
                    progress: _stats!['total_count'] > 0
                        ? (_stats!['earned_count'] / _stats!['total_count'])
                        : 0.0,
                  ).animate().fadeIn(duration: 400.ms, delay: 200.ms).slideX(begin: -0.2),

                  const SizedBox(height: 32),

                  // Recent Achievements Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent Achievements',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => context.push('/achievements'),
                        icon: const Icon(Iconsax.arrow_right_3, size: 16),
                        label: const Text('View All'),
                        style: TextButton.styleFrom(
                          foregroundColor: ModernTheme.primaryOrange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Recent Achievements List
                  if (_recentAchievements.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Iconsax.medal_star,
                            size: 48,
                            color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No Achievements Yet',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Start participating in activities to earn achievements',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  else
                    ..._recentAchievements.asMap().entries.map((entry) {
                      final index = entry.key;
                      final achievement = entry.value;
                      return _AchievementCard(
                        achievement: achievement,
                        index: index,
                      ).animate().fadeIn(
                            duration: 400.ms,
                            delay: (index * 100).ms,
                          ).slideX(begin: 0.2);
                    }),

                  const SizedBox(height: 24),

                  // View All Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => context.push('/achievements'),
                      icon: const Icon(Iconsax.cup),
                      label: const Text('View All Achievements'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ModernTheme.primaryOrange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ).animate().fadeIn(duration: 400.ms, delay: 600.ms).scale(begin: const Offset(0.95, 0.95)),
                ]),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final double? progress;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.1),
            color.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: color,
                ),
              ),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (progress != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: color.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 6,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final Map<String, dynamic> achievement;
  final int index;

  const _AchievementCard({
    required this.achievement,
    required this.index,
  });

  Color _getCategoryColor(String? category) {
    if (category == null) return const Color(0xFF8B5CF6);
    
    switch (category.toLowerCase()) {
      case 'social':
        return const Color(0xFF3B82F6);
      case 'academic':
        return const Color(0xFF10B981);
      case 'participation':
        return ModernTheme.primaryOrange;
      case 'special':
        return const Color(0xFFFFD700);
      default:
        return const Color(0xFF8B5CF6);
    }
  }

  @override
  Widget build(BuildContext context) {
    final achievementData = achievement['achievements'] as Map<String, dynamic>?;
    if (achievementData == null) return const SizedBox.shrink();

    final color = _getCategoryColor(achievementData['category'] as String?);
    final earnedAt = DateTime.parse(achievement['earned_at'] as String);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.1),
            color.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                achievementData['icon'] as String? ?? '🏆',
                style: const TextStyle(fontSize: 24),
              ),
            ),
            const SizedBox(width: 16),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    achievementData['name'] as String? ?? 'Achievement',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    achievementData['description'] as String? ?? '',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Iconsax.star5,
                              size: 12,
                              color: color,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '+${achievementData['xp_reward']} XP',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatDate(earnedAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    }
  }
}
