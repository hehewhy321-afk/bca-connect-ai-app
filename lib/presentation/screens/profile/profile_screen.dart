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
      ),
      body: userProfileAsync.when(
        data: (profile) => SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Profile Header - Ultra Compact
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A1A1A), Color(0xFF2D2D2D)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    // Avatar with Glow Effect
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Glow effect
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: ModernTheme.primaryOrange.withValues(alpha: 0.3),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                        ),
                        // Avatar Container
                        Container(
                          width: 75,
                          height: 75,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [ModernTheme.primaryOrange, Color(0xFFFF9A3C)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1),
                              width: 2,
                            ),
                          ),
                          child: profile?.avatarUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
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
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Name with Edit Button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [Colors.white, Color(0xFFCCCCCC)],
                              ).createShader(bounds),
                              child: Text(
                                profile?.fullName ?? user?.email?.split('@').first ?? 'User',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: -0.3,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => context.push('/settings'),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: ModernTheme.primaryOrange.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: ModernTheme.primaryOrange.withValues(alpha: 0.3),
                                ),
                              ),
                              child: const Icon(
                                Iconsax.edit_2,
                                color: ModernTheme.primaryOrange,
                                size: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    
                    // Email with Icon
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Iconsax.sms,
                            size: 10,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            user?.email ?? '',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 11,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Stats Row - Ultra Compact
                    if (profile != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            _ModernStatCard(
                              icon: Iconsax.award5,
                              label: 'Level',
                              value: '${profile.level}',
                              gradient: const LinearGradient(
                                colors: [Color(0xFF2D2D2D), Color(0xFF3D3D3D)],
                              ),
                              iconColor: ModernTheme.primaryOrange,
                            ),
                            const SizedBox(width: 10),
                            _ModernStatCard(
                              icon: Iconsax.star5,
                              label: 'XP Points',
                              value: '${profile.xpPoints}',
                              gradient: const LinearGradient(
                                colors: [Color(0xFF2D2D2D), Color(0xFF3D3D3D)],
                              ),
                              iconColor: const Color(0xFFFFD700),
                            ),
                          ],
                        ),
                      ),
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.95, 0.95)),
              
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
                    onTap: () => context.push('/my-events'),
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

class _ModernStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Gradient gradient;
  final Color iconColor;

  const _ModernStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.gradient,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.white.withValues(alpha: 0.6),
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
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
