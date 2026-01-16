import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/modern_theme.dart';
import '../../../core/services/permission_service.dart';
import 'package:hive_flutter/hive_flutter.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends ConsumerState<NotificationSettingsScreen> {
  late Box _settingsBox;
  bool _loading = true;

  // Notification settings
  bool _pushNotifications = true;
  bool _emailNotifications = true;
  
  // Event notifications
  bool _eventReminders = true;
  bool _eventUpdates = true;
  bool _newEvents = true;
  
  // Forum notifications
  bool _forumReplies = true;
  bool _forumMentions = true;
  bool _forumUpvotes = false;
  
  // Achievement notifications
  bool _achievementUnlocked = true;
  bool _levelUp = true;
  bool _xpEarned = false;
  
  // System notifications
  bool _announcements = true;
  bool _systemUpdates = true;
  bool _maintenanceAlerts = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _settingsBox = await Hive.openBox('notification_settings');
    
    setState(() {
      _pushNotifications = _settingsBox.get('push_notifications', defaultValue: true);
      _emailNotifications = _settingsBox.get('email_notifications', defaultValue: true);
      
      _eventReminders = _settingsBox.get('event_reminders', defaultValue: true);
      _eventUpdates = _settingsBox.get('event_updates', defaultValue: true);
      _newEvents = _settingsBox.get('new_events', defaultValue: true);
      
      _forumReplies = _settingsBox.get('forum_replies', defaultValue: true);
      _forumMentions = _settingsBox.get('forum_mentions', defaultValue: true);
      _forumUpvotes = _settingsBox.get('forum_upvotes', defaultValue: false);
      
      _achievementUnlocked = _settingsBox.get('achievement_unlocked', defaultValue: true);
      _levelUp = _settingsBox.get('level_up', defaultValue: true);
      _xpEarned = _settingsBox.get('xp_earned', defaultValue: false);
      
      _announcements = _settingsBox.get('announcements', defaultValue: true);
      _systemUpdates = _settingsBox.get('system_updates', defaultValue: true);
      _maintenanceAlerts = _settingsBox.get('maintenance_alerts', defaultValue: true);
      
      _loading = false;
    });
  }

  Future<void> _saveSetting(String key, bool value) async {
    await _settingsBox.put(key, value);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notification Settings')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: ModernTheme.orangeGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Iconsax.notification5,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Stay Updated',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Customize your notification preferences',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms).scale(begin: const Offset(0.95, 0.95)),

          const SizedBox(height: 24),

          // Permission Check Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ModernTheme.primaryOrange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: ModernTheme.primaryOrange.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Iconsax.shield_tick,
                      color: ModernTheme.primaryOrange,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Notification Permission',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Make sure notification permission is enabled to receive alerts.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () async {
                    final hasPermission = await PermissionService().hasNotificationPermission();
                    if (hasPermission) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Notification permission is already enabled!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } else {
                      if (mounted) {
                        await PermissionService().requestNotificationPermission(context);
                      }
                    }
                  },
                  icon: const Icon(Iconsax.notification_bing),
                  label: const Text('Check Permission'),
                  style: FilledButton.styleFrom(
                    backgroundColor: ModernTheme.primaryOrange,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms).scale(begin: const Offset(0.95, 0.95)),

          const SizedBox(height: 24),

          // General Settings
          _buildSection(
            title: 'General',
            icon: Iconsax.setting_2,
            children: [
              _buildSwitchTile(
                title: 'Push Notifications',
                subtitle: 'Receive push notifications on your device',
                value: _pushNotifications,
                onChanged: (value) {
                  setState(() => _pushNotifications = value);
                  _saveSetting('push_notifications', value);
                },
                icon: Iconsax.notification,
              ),
              _buildSwitchTile(
                title: 'Email Notifications',
                subtitle: 'Receive notifications via email',
                value: _emailNotifications,
                onChanged: (value) {
                  setState(() => _emailNotifications = value);
                  _saveSetting('email_notifications', value);
                },
                icon: Iconsax.sms,
              ),
            ],
          ).animate().fadeIn(duration: 300.ms, delay: 100.ms).slideY(begin: 0.2),

          const SizedBox(height: 16),

          // Event Notifications
          _buildSection(
            title: 'Events',
            icon: Iconsax.calendar,
            children: [
              _buildSwitchTile(
                title: 'Event Reminders',
                subtitle: 'Get reminded before events start',
                value: _eventReminders,
                onChanged: (value) {
                  setState(() => _eventReminders = value);
                  _saveSetting('event_reminders', value);
                },
                icon: Iconsax.alarm,
              ),
              _buildSwitchTile(
                title: 'Event Updates',
                subtitle: 'Notifications about event changes',
                value: _eventUpdates,
                onChanged: (value) {
                  setState(() => _eventUpdates = value);
                  _saveSetting('event_updates', value);
                },
                icon: Iconsax.refresh,
              ),
              _buildSwitchTile(
                title: 'New Events',
                subtitle: 'Get notified when new events are posted',
                value: _newEvents,
                onChanged: (value) {
                  setState(() => _newEvents = value);
                  _saveSetting('new_events', value);
                },
                icon: Iconsax.add_circle,
              ),
            ],
          ).animate().fadeIn(duration: 300.ms, delay: 150.ms).slideY(begin: 0.2),

          const SizedBox(height: 16),

          // Forum Notifications
          _buildSection(
            title: 'Forum',
            icon: Iconsax.message_text,
            children: [
              _buildSwitchTile(
                title: 'Replies to Your Posts',
                subtitle: 'When someone replies to your post',
                value: _forumReplies,
                onChanged: (value) {
                  setState(() => _forumReplies = value);
                  _saveSetting('forum_replies', value);
                },
                icon: Iconsax.message,
              ),
              _buildSwitchTile(
                title: 'Mentions',
                subtitle: 'When someone mentions you',
                value: _forumMentions,
                onChanged: (value) {
                  setState(() => _forumMentions = value);
                  _saveSetting('forum_mentions', value);
                },
                icon: Iconsax.user_tag,
              ),
              _buildSwitchTile(
                title: 'Upvotes',
                subtitle: 'When your posts get upvoted',
                value: _forumUpvotes,
                onChanged: (value) {
                  setState(() => _forumUpvotes = value);
                  _saveSetting('forum_upvotes', value);
                },
                icon: Iconsax.like_1,
              ),
            ],
          ).animate().fadeIn(duration: 300.ms, delay: 200.ms).slideY(begin: 0.2),

          const SizedBox(height: 16),

          // Achievement Notifications
          _buildSection(
            title: 'Achievements & Gamification',
            icon: Iconsax.award,
            children: [
              _buildSwitchTile(
                title: 'Achievement Unlocked',
                subtitle: 'When you unlock a new achievement',
                value: _achievementUnlocked,
                onChanged: (value) {
                  setState(() => _achievementUnlocked = value);
                  _saveSetting('achievement_unlocked', value);
                },
                icon: Iconsax.medal_star,
              ),
              _buildSwitchTile(
                title: 'Level Up',
                subtitle: 'When you reach a new level',
                value: _levelUp,
                onChanged: (value) {
                  setState(() => _levelUp = value);
                  _saveSetting('level_up', value);
                },
                icon: Iconsax.cup,
              ),
              _buildSwitchTile(
                title: 'XP Earned',
                subtitle: 'When you earn experience points',
                value: _xpEarned,
                onChanged: (value) {
                  setState(() => _xpEarned = value);
                  _saveSetting('xp_earned', value);
                },
                icon: Iconsax.star,
              ),
            ],
          ).animate().fadeIn(duration: 300.ms, delay: 250.ms).slideY(begin: 0.2),

          const SizedBox(height: 16),

          // System Notifications
          _buildSection(
            title: 'System',
            icon: Iconsax.setting,
            children: [
              _buildSwitchTile(
                title: 'Announcements',
                subtitle: 'Important announcements from admins',
                value: _announcements,
                onChanged: (value) {
                  setState(() => _announcements = value);
                  _saveSetting('announcements', value);
                },
                icon: Iconsax.speaker,
              ),
              _buildSwitchTile(
                title: 'System Updates',
                subtitle: 'App updates and new features',
                value: _systemUpdates,
                onChanged: (value) {
                  setState(() => _systemUpdates = value);
                  _saveSetting('system_updates', value);
                },
                icon: Iconsax.refresh_circle,
              ),
              _buildSwitchTile(
                title: 'Maintenance Alerts',
                subtitle: 'Scheduled maintenance notifications',
                value: _maintenanceAlerts,
                onChanged: (value) {
                  setState(() => _maintenanceAlerts = value);
                  _saveSetting('maintenance_alerts', value);
                },
                icon: Iconsax.setting_3,
              ),
            ],
          ).animate().fadeIn(duration: 300.ms, delay: 300.ms).slideY(begin: 0.2),

          const SizedBox(height: 24),

          // Info Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ModernTheme.primaryOrange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: ModernTheme.primaryOrange.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Iconsax.info_circle,
                  color: ModernTheme.primaryOrange,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Your notification preferences are saved locally and will be synced across devices.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms, delay: 350.ms),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ModernTheme.primaryOrange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: ModernTheme.primaryOrange, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return ListTile(
      leading: Icon(icon, color: ModernTheme.primaryOrange),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeTrackColor: ModernTheme.primaryOrange,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}
