import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/theme/modern_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    // Show confirmation dialog
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await SupabaseConfig.client.auth.signOut();
      if (context.mounted) {
        context.go('/auth/login');
      }
    }
  }

  String _getInitials(String name) {
    return name
        .split(' ')
        .map((n) => n.isNotEmpty ? n[0] : '')
        .join('')
        .toUpperCase()
        .substring(0, 2.clamp(0, name.length));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = SupabaseConfig.client.auth.currentUser;
    final userProfileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Iconsax.edit,
              color: ModernTheme.primaryOrange,
            ),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: userProfileAsync.when(
        data: (profile) => SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Profile Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    // Avatar
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: ModernTheme.orangeGradient,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: profile?.avatarUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.network(
                                profile!.avatarUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Center(
                                  child: Text(
                                    _getInitials(profile.fullName),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : Center(
                              child: Text(
                                _getInitials(profile?.fullName ?? user?.email ?? 'User'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Name
                    Text(
                      profile?.fullName ?? user?.email?.split('@').first ?? 'User',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    
                    // Email
                    Text(
                      user?.email ?? '',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    
                    if (profile != null) ...[
                      const SizedBox(height: 20),
                      // Stats Row
                      Row(
                        children: [
                          _StatItem(
                            icon: Iconsax.award,
                            label: 'Level',
                            value: '${profile.level}',
                            color: ModernTheme.primaryOrange,
                          ),
                          _StatItem(
                            icon: Iconsax.star5,
                            label: 'XP Points',
                            value: '${profile.xpPoints}',
                            color: ModernTheme.accentOrange,
                          ),
                          if (profile.isAlumni == true)
                            _StatItem(
                              icon: Iconsax.medal_star5,
                              label: 'Alumni',
                              value: '${profile.graduationYear}',
                              color: Colors.purple,
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.2),
              
              const SizedBox(height: 32),

              // Account Section
              _SectionHeader(title: 'Account'),
              const SizedBox(height: 12),
              _MenuGroup(
                children: [
                  _ModernMenuItem(
                    icon: Iconsax.medal_star,
                    title: 'My Certificates',
                    onTap: () => context.push('/certificates'),
                  ),
                  _ModernMenuItem(
                    icon: Iconsax.calendar_1,
                    title: 'My Events',
                    onTap: () => context.push('/events'),
                  ),
                  _ModernMenuItem(
                    icon: Iconsax.bookmark,
                    title: 'Saved Posts',
                    onTap: () => context.push('/forum'),
                  ),
                  _ModernMenuItem(
                    icon: Iconsax.document_download,
                    title: 'Downloads',
                    onTap: () => context.push('/resources'),
                  ),
                ],
              ).animate().fadeIn(duration: 500.ms, delay: 100.ms).slideX(begin: 0.2),

              const SizedBox(height: 24),

              // Preferences Section
              _SectionHeader(title: 'Preferences'),
              const SizedBox(height: 12),
              _MenuGroup(
                children: [
                  // Theme Toggle
                  Container(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: ModernTheme.primaryOrange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Iconsax.moon,
                            size: 20,
                            color: ModernTheme.primaryOrange,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Dark Mode',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ),
                        Consumer(
                          builder: (context, ref, child) {
                            final themeMode = ref.watch(themeModeProvider);
                            final isDark = themeMode == ThemeMode.dark;
                            return Switch(
                              value: isDark,
                              onChanged: (value) {
                                ref.read(themeModeProvider.notifier).setThemeMode(
                                  value ? ThemeMode.dark : ThemeMode.light,
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  _ModernMenuItem(
                    icon: Iconsax.notification,
                    title: 'Notifications',
                    onTap: () => context.push('/notification-settings'),
                  ),
                  _ModernMenuItem(
                    icon: Iconsax.security_safe,
                    title: 'Privacy & Security',
                    onTap: () => context.push('/settings'),
                  ),
                ],
              ).animate().fadeIn(duration: 500.ms, delay: 200.ms).slideX(begin: 0.2),

              const SizedBox(height: 24),

              // Support Section
              _SectionHeader(title: 'Support'),
              const SizedBox(height: 12),
              _MenuGroup(
                children: [
                  _ModernMenuItem(
                    icon: Iconsax.message_question,
                    title: 'Help Center',
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Row(
                            children: [
                              Icon(Iconsax.message_question),
                              SizedBox(width: 12),
                              Text('Help & Support'),
                            ],
                          ),
                          content: const Text(
                            'Need help? Contact our support team:\n\n'
                            '📧 Email: support@bcammamc.edu.np\n'
                            '📞 Phone: +977-XXX-XXXX\n'
                            '🕒 Hours: 9 AM - 5 PM (Mon-Fri)',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  _ModernMenuItem(
                    icon: Iconsax.info_circle,
                    title: 'About BCA MMAMC',
                    onTap: () {
                      showAboutDialog(
                        context: context,
                        applicationName: 'BCA MMAMC',
                        applicationVersion: '1.0.0',
                        applicationIcon: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: ModernTheme.orangeGradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Iconsax.book_1,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        children: const [
                          Text('Official mobile app for BCA students at MMAMC'),
                          SizedBox(height: 8),
                          Text('Stay connected with your academic journey!'),
                        ],
                      );
                    },
                  ),
                ],
              ).animate().fadeIn(duration: 500.ms, delay: 300.ms).slideX(begin: 0.2),

              const SizedBox(height: 32),

              // Logout Button
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.error.withValues(alpha: 0.2),
                  ),
                ),
                child: InkWell(
                  onTap: () => _handleLogout(context, ref),
                  borderRadius: BorderRadius.circular(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Iconsax.logout,
                          size: 20,
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Logout',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Theme.of(context).colorScheme.error,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const Spacer(),
                      Icon(
                        Iconsax.arrow_right_3,
                        size: 16,
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 500.ms, delay: 400.ms).slideY(begin: 0.2),

              const SizedBox(height: 32),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Iconsax.warning_2,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading profile',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: () => ref.invalidate(userProfileProvider),
                icon: const Icon(Iconsax.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Divider(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
          ),
        ),
      ],
    );
  }
}

class _MenuGroup extends StatelessWidget {
  final List<Widget> children;

  const _MenuGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: children,
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ModernMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ModernMenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ModernTheme.primaryOrange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 20,
                color: ModernTheme.primaryOrange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
            Icon(
              Iconsax.arrow_right_3,
              size: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
