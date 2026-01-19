import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/theme/modern_theme.dart';
import '../../../data/models/founding_member.dart';
import '../../widgets/cached_image.dart';

class FoundingMembersScreen extends StatefulWidget {
  const FoundingMembersScreen({super.key});

  @override
  State<FoundingMembersScreen> createState() => _FoundingMembersScreenState();
}

class _FoundingMembersScreenState extends State<FoundingMembersScreen> {
  List<FoundingMember> _members = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final response = await SupabaseConfig.client
          .from('founding_members')
          .select()
          .eq('is_active', true)
          .order('display_order', ascending: true);

      setState(() {
        _members = (response as List)
            .map((json) => FoundingMember.fromJson(json))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      // Check if it's a table not found error
      if (e.toString().contains('relation') && e.toString().contains('does not exist')) {
        setState(() {
          _error = 'Founding members feature is not yet configured in the database.';
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Unable to load founding members. Please try again later.';
          _isLoading = false;
        });
      }
      debugPrint('Error loading founding members: $e');
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
                      const Color(0xFF8B5CF6),
                      const Color(0xFFFF6B9D),
                      ModernTheme.primaryOrange,
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
                              Iconsax.people5,
                              size: 48,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Founding Members',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Meet the visionaries behind BCA Association',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                            textAlign: TextAlign.center,
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
                      'Loading founding members...',
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
                      Iconsax.warning_2,
                      size: 64,
                      color: Theme.of(context).colorScheme.error.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading members',
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
                      onPressed: _loadMembers,
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
          else if (_members.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: ModernTheme.primaryOrange.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Iconsax.people,
                        size: 64,
                        color: ModernTheme.primaryOrange.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'No Members Found',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 48),
                      child: Text(
                        'Founding members information will be available soon',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final member = _members[index];
                    return _MemberCard(
                      member: member,
                      index: index,
                    ).animate().fadeIn(
                          duration: 400.ms,
                          delay: (index * 100).ms,
                        ).scale(begin: const Offset(0.8, 0.8));
                  },
                  childCount: _members.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  final FoundingMember member;
  final int index;

  const _MemberCard({
    required this.member,
    required this.index,
  });

  String _getInitials(String name) {
    final parts = name.split(' ').where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) {
      return parts[0].substring(0, 1.clamp(0, parts[0].length)).toUpperCase();
    }
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Gradient colors based on index
    final gradients = [
      [const Color(0xFFFF6B9D), const Color(0xFFFF9A3C)],
      [const Color(0xFF8B5CF6), const Color(0xFFFF6B9D)],
      [const Color(0xFF3B82F6), const Color(0xFF8B5CF6)],
      [ModernTheme.primaryOrange, const Color(0xFFFF6B9D)],
    ];
    final gradient = gradients[index % gradients.length];

    return GestureDetector(
      onTap: () {
        _showMemberDetails(context);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: gradient[0].withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            // Gradient Header
            Container(
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradient,
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
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.surface,
                        width: 4,
                      ),
                    ),
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: gradient,
                        ),
                      ),
                      child: member.avatarUrl != null
                          ? ClipOval(
                              child: CachedImage(
                                imageUrl: member.avatarUrl!,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorWidget: Center(
                                  child: Text(
                                    _getInitials(member.fullName),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : Center(
                              child: Text(
                                _getInitials(member.fullName),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Name
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      member.fullName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.3,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Role
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      member.role,
                      style: TextStyle(
                        fontSize: 12,
                        color: gradient[0],
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Social Links
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (member.email != null)
                        _SocialButton(
                          icon: Iconsax.sms,
                          color: const Color(0xFF4285F4),
                          onTap: () => _launchUrl('mailto:${member.email}'),
                        ),
                      if (member.phone != null)
                        _SocialButton(
                          icon: Iconsax.call,
                          color: const Color(0xFF34A853),
                          onTap: () => _launchUrl('tel:${member.phone}'),
                        ),
                      if (member.linkedinUrl != null)
                        _SocialButton(
                          icon: Iconsax.link,
                          color: const Color(0xFF0077B5),
                          onTap: () => _launchUrl(member.linkedinUrl!),
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

  void _showMemberDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Drag Handle
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),

                // Avatar
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [ModernTheme.primaryOrange, Color(0xFFFF9A3C)],
                    ),
                  ),
                  child: member.avatarUrl != null
                      ? ClipOval(
                          child: CachedImage(
                            imageUrl: member.avatarUrl!,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                            errorWidget: Center(
                              child: Text(
                                _getInitials(member.fullName),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            _getInitials(member.fullName),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                ),

                const SizedBox(height: 16),

                // Name
                Text(
                  member.fullName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                // Role
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: ModernTheme.primaryOrange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    member.role,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: ModernTheme.primaryOrange,
                    ),
                  ),
                ),

                if (member.bio != null) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      member.bio!,
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Contact Buttons
                if (member.email != null || member.phone != null) ...[
                  const Divider(),
                  const SizedBox(height: 16),
                  if (member.email != null)
                    _ContactButton(
                      icon: Iconsax.sms,
                      label: 'Email',
                      value: member.email!,
                      onTap: () => _launchUrl('mailto:${member.email}'),
                    ),
                  if (member.phone != null) ...[
                    const SizedBox(height: 12),
                    _ContactButton(
                      icon: Iconsax.call,
                      label: 'Phone',
                      value: member.phone!,
                      onTap: () => _launchUrl('tel:${member.phone}'),
                    ),
                  ],
                ],

                // Social Links
                if (member.linkedinUrl != null ||
                    member.facebookUrl != null ||
                    member.twitterUrl != null) ...[
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (member.linkedinUrl != null)
                        _LargeSocialButton(
                          icon: Iconsax.link,
                          label: 'LinkedIn',
                          color: const Color(0xFF0077B5),
                          onTap: () => _launchUrl(member.linkedinUrl!),
                        ),
                      if (member.facebookUrl != null) ...[
                        const SizedBox(width: 12),
                        _LargeSocialButton(
                          icon: Icons.facebook,
                          label: 'Facebook',
                          color: const Color(0xFF1877F2),
                          onTap: () => _launchUrl(member.facebookUrl!),
                        ),
                      ],
                      if (member.twitterUrl != null) ...[
                        const SizedBox(width: 12),
                        _LargeSocialButton(
                          icon: Icons.close, // Using close as placeholder for X/Twitter
                          label: 'Twitter',
                          color: const Color(0xFF1DA1F2),
                          onTap: () => _launchUrl(member.twitterUrl!),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SocialButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 16,
          color: color,
        ),
      ),
    );
  }
}

class _ContactButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _ContactButton({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
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

class _LargeSocialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _LargeSocialButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 24,
              color: color,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
