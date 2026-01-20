import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/modern_theme.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/constants/easter_eggs.dart';
import '../../widgets/easter_egg_widget.dart';

class AchievementsScreen extends ConsumerStatefulWidget {
  const AchievementsScreen({super.key});

  @override
  ConsumerState<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends ConsumerState<AchievementsScreen> {
  bool _loading = true;
  int _level = 1;
  int _xpPoints = 0;
  int _earnedCount = 0;
  int _totalCount = 0;
  List<Map<String, dynamic>> _achievements = [];
  List<String> _userAchievements = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) return;

      // Fetch profile
      final profileResponse = await SupabaseConfig.client
          .from('profiles')
          .select('xp_points, level')
          .eq('user_id', user.id)
          .maybeSingle();

      // Fetch achievements
      final achievementsResponse = await SupabaseConfig.client
          .from('achievements')
          .select()
          .order('xp_reward', ascending: true);

      // Fetch user achievements
      final userAchievementsResponse = await SupabaseConfig.client
          .from('user_achievements')
          .select('achievement_id')
          .eq('user_id', user.id);

      if (mounted) {
        final achievementsList = List<Map<String, dynamic>>.from(achievementsResponse);
        final userAchievementsList = <String>[];
        for (var e in userAchievementsResponse as List) {
          userAchievementsList.add(e['achievement_id'] as String);
        }
        
        setState(() {
          _level = profileResponse?['level'] ?? 1;
          _xpPoints = profileResponse?['xp_points'] ?? 0;
          _achievements = achievementsList;
          _userAchievements = userAchievementsList;
          _earnedCount = _userAchievements.length;
          _totalCount = _achievements.length;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  bool _isEarned(String achievementId) {
    return _userAchievements.contains(achievementId);
  }

  @override
  Widget build(BuildContext context) {
    final currentXpProgress = _xpPoints % 100;
    final levelProgress = (currentXpProgress / 100) * 100;
    final progressPercent = _totalCount > 0 ? (_earnedCount / _totalCount) * 100 : 0;

    // Group achievements by category
    final categories = <String>{};
    for (var achievement in _achievements) {
      categories.add(achievement['category'] ?? 'general');
    }

    return Scaffold(
      appBar: AppBar(
        title: EasterEggWidget(
          soundFile: EasterEggs.achievements.soundFile,
          emoji: EasterEggs.achievements.emoji,
          message: EasterEggs.achievements.message,
          child: const Text('Achievements'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.refresh),
            onPressed: () {
              setState(() => _loading = true);
              _fetchData();
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats Cards
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            icon: Iconsax.cup5,
                            label: 'Level',
                            value: _level.toString(),
                            gradient: ModernTheme.orangeGradient,
                            progress: levelProgress,
                            subtitle: '$currentXpProgress/100 XP',
                          ).animate().fadeIn(duration: 500.ms).slideX(begin: -0.2),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            icon: Iconsax.chart5,
                            label: 'Total XP',
                            value: _xpPoints.toString(),
                            color: ModernTheme.accentOrange,
                          ).animate().fadeIn(duration: 500.ms, delay: 100.ms).slideX(begin: -0.2),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _StatCard(
                      icon: Iconsax.award5,
                      label: 'Achievements',
                      value: '$_earnedCount/$_totalCount',
                      color: ModernTheme.primaryOrange,
                      progress: progressPercent.toDouble(),
                      isWide: true,
                    ).animate().fadeIn(duration: 500.ms, delay: 200.ms).slideY(begin: 0.2),
                    
                    const SizedBox(height: 32),

                    // Achievements by Category
                    ...categories.map((category) {
                      final categoryAchievements = _achievements
                          .where((a) => (a['category'] ?? 'general') == category)
                          .toList();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${category[0].toUpperCase()}${category.substring(1)} Achievements',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 16),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.85,
                            ),
                            itemCount: categoryAchievements.length,
                            itemBuilder: (context, index) {
                              final achievement = categoryAchievements[index];
                              final earned = _isEarned(achievement['id']);
                              return _AchievementCard(
                                achievement: achievement,
                                earned: earned,
                                index: index,
                              );
                            },
                          ),
                          const SizedBox(height: 32),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Gradient? gradient;
  final Color? color;
  final double? progress;
  final String? subtitle;
  final bool isWide;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    this.gradient,
    this.color,
    this.progress,
    this.subtitle,
    this.isWide = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: gradient,
        color: gradient == null ? Theme.of(context).cardColor : null,
        borderRadius: BorderRadius.circular(20),
        border: gradient == null
            ? Border.all(color: Theme.of(context).dividerColor)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: gradient != null
                      ? Colors.white.withValues(alpha: 0.2)
                      : color?.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: gradient != null ? Colors.white : color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: gradient != null
                            ? Colors.white.withValues(alpha: 0.8)
                            : Theme.of(context).textTheme.bodySmall?.color,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      value,
                      style: TextStyle(
                        color: gradient != null ? Colors.white : null,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (progress != null) ...[
            const SizedBox(height: 12),
            if (subtitle != null)
              Text(
                subtitle!,
                style: TextStyle(
                  color: gradient != null
                      ? Colors.white.withValues(alpha: 0.8)
                      : Theme.of(context).textTheme.bodySmall?.color,
                  fontSize: 12,
                ),
              ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress! / 100,
                minHeight: 6,
                backgroundColor: gradient != null
                    ? Colors.white.withValues(alpha: 0.2)
                    : Theme.of(context).dividerColor,
                valueColor: AlwaysStoppedAnimation(
                  gradient != null ? Colors.white : color,
                ),
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
  final bool earned;
  final int index;

  const _AchievementCard({
    required this.achievement,
    required this.earned,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: earned
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  ModernTheme.primaryOrange.withValues(alpha: 0.1),
                  ModernTheme.accentOrange.withValues(alpha: 0.1),
                ],
              )
            : null,
        color: earned ? null : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: earned
              ? ModernTheme.primaryOrange.withValues(alpha: 0.3)
              : Theme.of(context).dividerColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                achievement['icon'] ?? '🏆',
                style: TextStyle(
                  fontSize: 40,
                  color: earned ? null : Colors.grey,
                ),
              ),
              if (!earned)
                Icon(
                  Iconsax.lock,
                  size: 16,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            achievement['name'] ?? '',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: earned ? null : Colors.grey,
                ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            achievement['description'] ?? '',
            style: Theme.of(context).textTheme.bodySmall,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: earned
                  ? ModernTheme.accentOrange.withValues(alpha: 0.2)
                  : Theme.of(context).dividerColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Iconsax.star5,
                  size: 12,
                  color: earned ? ModernTheme.accentOrange : Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  '+${achievement['xp_reward'] ?? 0} XP',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: earned ? ModernTheme.accentOrange : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms, delay: (index * 50).ms).scale(begin: const Offset(0.9, 0.9));
  }
}
