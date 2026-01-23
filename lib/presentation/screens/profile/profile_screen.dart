import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../../core/config/supabase_config.dart';
import '../../widgets/cached_image.dart';
import '../../../core/theme/modern_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../ai/image_gallery_screen.dart';
import '../contact/contact_screen.dart';
import '../feedback/feedback_screen.dart';
import '../../../core/services/app_update_service.dart';
import 'hall_of_fame_screen.dart';
import 'founding_members_screen.dart';
import '../../../core/constants/easter_eggs.dart';
import '../../widgets/easter_egg_widget.dart';

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

  Future<void> _checkForUpdates(BuildContext context) async {
    // Show checking dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Checking for updates...'),
          ],
        ),
      ),
    );

    try {
      final updateInfo = await AppUpdateService.checkForUpdates();

      if (context.mounted) {
        Navigator.pop(context); // Close checking dialog

        if (updateInfo != null) {
          // Show update available dialog
          _showUpdateDialog(context, updateInfo);
        } else {
          // No update available
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(child: Text('You\'re using the latest version!')),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close checking dialog
        
        String errorMessage;
        Color errorColor = Colors.red;
        IconData errorIcon = Icons.error_outline;
        
        final errorString = e.toString();
        if (errorString.contains('UPDATE_DISABLED')) {
          errorMessage = 'Update check is not configured yet. Please check back later.';
          errorIcon = Icons.info_outline;
          errorColor = Colors.blue;
        } else if (errorString.contains('NO_INTERNET')) {
          errorMessage = 'No internet connection. Please check your network.';
          errorIcon = Icons.wifi_off;
          errorColor = Colors.orange;
        } else if (errorString.contains('TIMEOUT')) {
          errorMessage = 'Request timed out. Please try again.';
          errorIcon = Icons.access_time;
          errorColor = Colors.orange;
        } else if (errorString.contains('NO_RELEASES')) {
          errorMessage = 'No releases found. Please check back later.';
          errorIcon = Icons.info_outline;
          errorColor = Colors.blue;
        } else if (errorString.contains('SERVER_ERROR')) {
          errorMessage = 'Server error. Please try again later.';
          errorIcon = Icons.cloud_off;
        } else {
          errorMessage = 'Unable to check for updates. Please try again later.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(errorIcon, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text(errorMessage)),
              ],
            ),
            backgroundColor: errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _showUpdateDialog(BuildContext context, UpdateInfo updateInfo) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4CAF50), Color(0xFF8BC34A)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Iconsax.refresh_circle, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Update Available',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Version info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          'v${updateInfo.currentVersion}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const Icon(Icons.arrow_forward, color: ModernTheme.primaryOrange),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Latest',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          'v${updateInfo.latestVersion}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4CAF50),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Release date
              Row(
                children: [
                  Icon(
                    Iconsax.calendar,
                    size: 16,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Released: ${DateFormat('MMM dd, yyyy').format(updateInfo.publishedAt)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Release notes
              Text(
                'What\'s New:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
                  ),
                ),
                child: Text(
                  updateInfo.releaseNotes,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: isDark ? Colors.grey.shade300 : Colors.black87,
                  ),
                  maxLines: 8,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 16),
              
              // Download options
              Text(
                'Choose your device architecture:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              
              // 64-bit option
              if (updateInfo.apkUrl64 != null)
                InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    AppUpdateService.downloadAndInstall(context, updateInfo.apkUrl64!);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          ModernTheme.primaryOrange.withValues(alpha: 0.2),
                          ModernTheme.primaryOrange.withValues(alpha: 0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: ModernTheme.primaryOrange.withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Iconsax.mobile, color: ModernTheme.primaryOrange),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '64-bit (Recommended)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              Text(
                                'For newer devices • ${AppUpdateService.formatBytes(updateInfo.apkSize64 ?? 0)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Iconsax.arrow_down_1, color: ModernTheme.primaryOrange),
                      ],
                    ),
                  ),
                ),
              
              if (updateInfo.apkUrl64 != null && updateInfo.apkUrl32 != null)
                const SizedBox(height: 8),
              
              // 32-bit option
              if (updateInfo.apkUrl32 != null)
                InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    AppUpdateService.downloadAndInstall(context, updateInfo.apkUrl32!);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.blue.withValues(alpha: 0.2),
                          Colors.blue.withValues(alpha: 0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.blue.withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Iconsax.mobile, color: Colors.blue),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '32-bit',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              Text(
                                'For older devices • ${AppUpdateService.formatBytes(updateInfo.apkSize32 ?? 0)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Iconsax.arrow_down_1, color: Colors.blue),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: ModernTheme.primaryOrange,
            ),
            child: const Text('Later'),
          ),
        ],
      ),
    );
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
        data: (profile) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(userProfileProvider);
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Profile Card - Completely Redesigned
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.05),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    // Colorful Gradient Header
                    Container(
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            ModernTheme.primaryOrange,
                            const Color(0xFFFF6B9D),
                            const Color(0xFF8B5CF6),
                            const Color(0xFF3B82F6),
                          ],
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                    ),
                    
                    // Avatar overlapping header
                    Transform.translate(
                      offset: const Offset(0, -40),
                      child: Column(
                        children: [
                          EasterEggWidget(
                            soundFile: EasterEggs.settings.soundFile,
                            emoji: EasterEggs.settings.emoji,
                            message: EasterEggs.settings.message,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF1A1A1A),
                                  width: 4,
                                ),
                              ),
                              child: Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [ModernTheme.primaryOrange, Color(0xFFFF9A3C)],
                                  ),
                                ),
                                child: profile?.avatarUrl != null
                                    ? ClipOval(
                                        child: CachedImage(
                                          imageUrl: profile!.avatarUrl!,
                                          width: 80,
                                          height: 80,
                                          fit: BoxFit.cover,
                                          errorWidget: Center(
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
                            ),
                          ),
                          
                          const SizedBox(height: 12),
                          
                          // Name
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              profile?.fullName ?? user?.email?.split('@').first ?? 'User',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          
                          const SizedBox(height: 4),
                          
                          // Role/Batch
                          Text(
                            profile?.batch ?? 'BCA Student',
                            style: TextStyle(
                              fontSize: 14,
                              color: ModernTheme.primaryOrange,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Skills chips
                          if (profile != null && profile.skills.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 6,
                                runSpacing: 6,
                                children: profile.skills.take(4).map((skill) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2A2A2A),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.1),
                                      ),
                                    ),
                                    child: Text(
                                      skill,
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.9),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          
                          const SizedBox(height: 16),
                          
                          // Stats Row
                          if (profile != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _CompactStatItem(
                                    icon: Iconsax.star5,
                                    value: '${profile.level}',
                                    label: 'Level',
                                    color: ModernTheme.primaryOrange,
                                  ),
                                  Container(
                                    width: 1,
                                    height: 40,
                                    color: Colors.white.withValues(alpha: 0.1),
                                  ),
                                  _CompactStatItem(
                                    icon: Iconsax.award5,
                                    value: '${profile.xpPoints}',
                                    label: 'XP',
                                    color: const Color(0xFFFFD700),
                                  ),
                                  if (profile.semester != null) ...[
                                    Container(
                                      width: 1,
                                      height: 40,
                                      color: Colors.white.withValues(alpha: 0.1),
                                    ),
                                    _CompactStatItem(
                                      icon: Iconsax.book_1,
                                      value: '${profile.semester}',
                                      label: 'Semester',
                                      color: const Color(0xFF8B5CF6),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          
                          const SizedBox(height: 20),
                          
                          // Edit Profile Button
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => context.push('/settings'),
                                icon: const Icon(Iconsax.edit_2, size: 18),
                                label: const Text('Edit Profile'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: ModernTheme.primaryOrange,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
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
                    icon: Iconsax.cup,
                    title: 'Hall of Fame',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HallOfFameScreen(),
                        ),
                      );
                    },
                  ),
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
                    icon: Iconsax.gallery,
                    title: 'AI Gallery',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ImageGalleryScreen(),
                        ),
                      );
                    },
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
                    icon: Iconsax.people,
                    title: 'Founding Members',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FoundingMembersScreen(),
                        ),
                      );
                    },
                  ),
                  _ModernMenuItem(
                    icon: Iconsax.refresh_circle,
                    title: 'Check for Updates',
                    onTap: () => _checkForUpdates(context),
                  ),
                  _ModernMenuItem(
                    icon: Iconsax.message,
                    title: 'Contact Us',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ContactScreen(),
                        ),
                      );
                    },
                  ),
                  _ModernMenuItem(
                    icon: Iconsax.lamp_charge,
                    title: 'Request Feature / Feedback',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FeedbackScreen(),
                        ),
                      );
                    },
                  ),
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
                            '📧 Email: mmamcbcaassociation@gmail.com\n'
                            '📞 Phone: +977-9800923746\n'
                            '🕒 Hours: 10 AM - 5 PM (Sun-Fri)',
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

              // Developer Credits
              EasterEggWidget(
                soundFile: EasterEggs.developerCredits.soundFile,
                emoji: EasterEggs.developerCredits.emoji,
                message: EasterEggs.developerCredits.message,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        ModernTheme.primaryOrange.withValues(alpha: 0.1),
                        const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: ModernTheme.primaryOrange.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Iconsax.code_1,
                            size: 16,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Developed by',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Saif Ali',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: ModernTheme.primaryOrange,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Instagram Link
                          InkWell(
                            onTap: () async {
                              final uri = Uri.parse('https://www.instagram.com/me_saifali/');
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri, mode: LaunchMode.externalApplication);
                              }
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFF58529), Color(0xFFDD2A7B), Color(0xFF8134AF)],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Iconsax.instagram,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // GitHub Link
                          InkWell(
                            onTap: () async {
                              final uri = Uri.parse('https://github.com/mesaifali');
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri, mode: LaunchMode.externalApplication);
                              }
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.onSurface,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Iconsax.code,
                                color: Theme.of(context).colorScheme.surface,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 500.ms, delay: 450.ms).scale(begin: const Offset(0.95, 0.95)),
              ),

              const SizedBox(height: 24),

              // Logout Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => _handleLogout(context, ref),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Iconsax.logout, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        'Logout',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 500.ms, delay: 500.ms).slideY(begin: 0.2),

              const SizedBox(height: 32),
            ],
          ),
        ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) {
          // Check if it's a network error
          final isNetworkError = error.toString().contains('No internet connection') ||
              error.toString().contains('SocketException') ||
              error.toString().contains('Failed host lookup');

          // Try to get user info from auth even if profile fails
          final user = SupabaseConfig.client.auth.currentUser;
          
          // If we have basic user info, show a minimal profile with error banner
          if (user != null) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Error Banner
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isNetworkError
                          ? Colors.orange.withValues(alpha: 0.1)
                          : Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isNetworkError
                            ? Colors.orange.withValues(alpha: 0.3)
                            : Theme.of(context).colorScheme.error.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isNetworkError ? Iconsax.wifi_square : Iconsax.warning_2,
                          color: isNetworkError ? Colors.orange : Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isNetworkError ? 'Offline Mode' : 'Profile Load Error',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isNetworkError ? Colors.orange : Theme.of(context).colorScheme.error,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isNetworkError
                                    ? 'Some features may be limited'
                                    : 'Unable to load full profile',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Iconsax.refresh),
                          onPressed: () => ref.invalidate(userProfileProvider),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Basic Profile Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [ModernTheme.primaryOrange, Color(0xFFFF9A3C)],
                            ),
                          ),
                          child: Center(
                            child: Text(
                              _getInitials(user.email?.split('@').first ?? 'User'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          user.email?.split('@').first ?? 'User',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          user.email ?? '',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Limited Menu Options
                  _SectionHeader(title: 'Account'),
                  const SizedBox(height: 12),
                  _MenuGroup(
                    children: [
                      _ModernMenuItem(
                        icon: Iconsax.setting_2,
                        title: 'Settings',
                        onTap: () => context.push('/settings'),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => _handleLogout(context, ref),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.error,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Iconsax.logout, size: 20),
                          const SizedBox(width: 12),
                          Text(
                            'Logout',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          
          // If no user at all, show full error
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isNetworkError ? Iconsax.wifi_square : Iconsax.warning_2,
                  size: 64,
                  color: isNetworkError
                      ? Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5)
                      : Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  isNetworkError ? 'No Internet Connection' : 'Error loading profile',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    isNetworkError
                        ? 'Please check your internet connection'
                        : 'Unable to load your profile',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => ref.invalidate(userProfileProvider),
                  icon: const Icon(Iconsax.refresh),
                  label: const Text('Retry'),
                  style: FilledButton.styleFrom(
                    backgroundColor: ModernTheme.primaryOrange,
                  ),
                ),
              ],
            ),
          );
        },
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

class _CompactStatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _CompactStatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.6),
          ),
        ),
      ],
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
