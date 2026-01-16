import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/config/supabase_config.dart';

class CommunityScreen extends ConsumerStatefulWidget {
  const CommunityScreen({super.key});

  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen> {
  bool _loading = true;
  String _searchQuery = '';
  String _filterType = 'all'; // all, students, alumni
  String _batchFilter = 'all';
  String _semesterFilter = 'all';
  List<Map<String, dynamic>> _members = [];
  List<String> _availableBatches = [];

  @override
  void initState() {
    super.initState();
    _fetchMembers();
  }

  Future<void> _fetchMembers() async {
    try {
      final response = await SupabaseConfig.client
          .from('profiles')
          .select()
          .order('xp_points', ascending: false);

      if (mounted) {
        final membersList = List<Map<String, dynamic>>.from(response);
        
        // Extract unique batches and skills
        final batches = <String>{};
        final skills = <String>{};
        
        for (final member in membersList) {
          if (member['batch'] != null) {
            batches.add(member['batch'].toString());
          }
          if (member['skills'] != null && member['skills'] is List) {
            skills.addAll((member['skills'] as List).map((s) => s.toString()));
          }
        }
        
        setState(() {
          _members = membersList;
          _availableBatches = batches.toList()..sort();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  List<Map<String, dynamic>> get _filteredMembers {
    return _members.where((member) {
      final fullName = member['full_name']?.toString() ?? '';
      final batch = member['batch']?.toString() ?? '';
      final semester = member['semester']?.toString() ?? '';
      final skills = member['skills'] is List 
          ? (member['skills'] as List).map((s) => s.toString().toLowerCase()).toList()
          : <String>[];
      
      final matchesSearch = fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          batch.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          skills.any((skill) => skill.contains(_searchQuery.toLowerCase()));
      
      final isAlumni = member['is_alumni'] == true;
      final matchesFilter = _filterType == 'all' ||
          (_filterType == 'alumni' && isAlumni) ||
          (_filterType == 'students' && !isAlumni);
      
      final matchesBatch = _batchFilter == 'all' || batch == _batchFilter;
      
      final matchesSemester = _semesterFilter == 'all' || semester == _semesterFilter;

      return matchesSearch && matchesFilter && matchesBatch && matchesSemester;
    }).toList();
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
  Widget build(BuildContext context) {
    final students = _members.where((m) => m['is_alumni'] != true).length;
    final alumni = _members.where((m) => m['is_alumni'] == true).length;

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Purple Gradient Header
                _buildGradientHeader(context, students, alumni),
                
                // Main Content
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _fetchMembers,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Search Bar
                          _buildSearchBar(),
                          
                          const SizedBox(height: 16),

                          // Filter Chips Row 1
                          _buildFilterChips(),

                          const SizedBox(height: 12),

                          // Advanced Filters Row 2
                          _buildAdvancedFilters(),

                          const SizedBox(height: 24),

                          // Members Grid
                          if (_filteredMembers.isEmpty)
                            _buildEmptyState()
                          else
                            _buildMembersGrid(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildGradientHeader(BuildContext context, int students, int alumni) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFDA7809), // Orange
            Color(0xFFFF9500), // Lighter orange
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Iconsax.people,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Community',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Connect with students & alumni',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Stats Row
              Row(
                children: [
                  Expanded(
                    child: _buildHeaderStat(
                      icon: Iconsax.people,
                      label: 'Total',
                      value: _members.length.toString(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildHeaderStat(
                      icon: Iconsax.book,
                      label: 'Students',
                      value: students.toString(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildHeaderStat(
                      icon: Iconsax.medal_star,
                      label: 'Alumni',
                      value: alumni.toString(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderStat({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Iconsax.search_normal,
            color: Colors.grey[500],
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search by name, batch, or skills...',
                hintStyle: TextStyle(color: Colors.grey[600]),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.2);
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip('All', _filterType == 'all', () {
            setState(() => _filterType = 'all');
          }),
          const SizedBox(width: 8),
          _buildFilterChip('Students', _filterType == 'students', () {
            setState(() => _filterType = 'students');
          }),
          const SizedBox(width: 8),
          _buildFilterChip('Alumni', _filterType == 'alumni', () {
            setState(() => _filterType = 'alumni');
          }),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 100.ms);
  }

  Widget _buildFilterChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          gradient: selected
            ? const LinearGradient(
                colors: [Color(0xFFDA7809), Color(0xFFFF9500)],
              )
            : null,
          color: selected ? null : const Color(0xFF1F1F1F),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected 
              ? Colors.transparent 
              : Colors.grey.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.grey[400],
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildAdvancedFilters() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.withValues(alpha: 0.2),
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _batchFilter,
                isExpanded: true,
                dropdownColor: const Color(0xFF1A1A1A),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                icon: Icon(Iconsax.arrow_down_1, color: Colors.grey[500], size: 16),
                items: [
                  const DropdownMenuItem(
                    value: 'all',
                    child: Text('All Batches'),
                  ),
                  ..._availableBatches.map((batch) => 
                    DropdownMenuItem(value: batch, child: Text(batch))
                  ),
                ],
                onChanged: (value) => setState(() => _batchFilter = value ?? 'all'),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.withValues(alpha: 0.2),
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _semesterFilter,
                isExpanded: true,
                dropdownColor: const Color(0xFF1A1A1A),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                icon: Icon(Iconsax.arrow_down_1, color: Colors.grey[500], size: 16),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All Semesters')),
                  DropdownMenuItem(value: '1', child: Text('Semester 1')),
                  DropdownMenuItem(value: '2', child: Text('Semester 2')),
                  DropdownMenuItem(value: '3', child: Text('Semester 3')),
                  DropdownMenuItem(value: '4', child: Text('Semester 4')),
                  DropdownMenuItem(value: '5', child: Text('Semester 5')),
                  DropdownMenuItem(value: '6', child: Text('Semester 6')),
                  DropdownMenuItem(value: '7', child: Text('Semester 7')),
                  DropdownMenuItem(value: '8', child: Text('Semester 8')),
                ],
                onChanged: (value) => setState(() => _semesterFilter = value ?? 'all'),
              ),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 300.ms, delay: 150.ms);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 48),
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFDA7809).withValues(alpha: 0.1),
                  const Color(0xFFFF9500).withValues(alpha: 0.05),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Iconsax.people,
              size: 80,
              color: const Color(0xFFDA7809).withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Members Found',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Try adjusting your search or filter criteria',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[400],
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: _filteredMembers.length,
      itemBuilder: (context, index) {
        final member = _filteredMembers[index];
        return _MemberCard(
          member: member,
          getInitials: _getInitials,
          index: index,
        );
      },
    );
  }
}

class _MemberCard extends StatelessWidget {
  final Map<String, dynamic> member;
  final String Function(String) getInitials;
  final int index;

  const _MemberCard({
    required this.member,
    required this.getInitials,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final isAlumni = member['is_alumni'] == true;
    final avatarUrl = member['avatar_url'];
    final fullName = member['full_name'] ?? 'Unknown';
    final batch = member['batch'];
    final semester = member['semester'];
    final bio = member['bio'];
    final level = member['level'] ?? 1;
    final xpPoints = member['xp_points'] ?? 0;
    final githubUrl = member['github_url'];
    final linkedinUrl = member['linkedin_url'];
    final skills = member['skills'] is List 
        ? (member['skills'] as List).map((s) => s.toString()).toList()
        : <String>[];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Avatar and Level
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFDA7809).withValues(alpha: 0.1),
                  const Color(0xFFFF9500).withValues(alpha: 0.05),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFDA7809), Color(0xFFFF9500)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: avatarUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            avatarUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Center(
                              child: Text(
                                getInitials(fullName),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            getInitials(fullName),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                ),
                const Spacer(),
                // Level Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Iconsax.award,
                        size: 12,
                        color: Color(0xFFDA7809),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$level',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFDA7809),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    fullName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 6),

                  // Alumni Badge or Batch/Semester
                  if (isAlumni)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFDA7809), Color(0xFFFF9500)],
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Alumni',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    )
                  else
                    Row(
                      children: [
                        if (batch != null)
                          Flexible(
                            child: Text(
                              batch,
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 10,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        if (semester != null) ...[
                          if (batch != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Container(
                                width: 2,
                                height: 2,
                                decoration: BoxDecoration(
                                  color: Colors.grey[600],
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          Text(
                            'S$semester',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ],
                    ),

                  // Bio
                  if (bio != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      bio,
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 10,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  // Skills
                  if (skills.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: skills.take(2).map((skill) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2A2A),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          skill,
                          style: TextStyle(
                            fontSize: 8,
                            color: Colors.grey[300],
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      )).toList(),
                    ),
                  ],

                  const Spacer(),

                  // Footer - XP and Social
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // XP
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2A2A2A),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Iconsax.star,
                                size: 10,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  '$xpPoints',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: Colors.grey[300],
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Social Icons
                      if (githubUrl != null && githubUrl.isNotEmpty) ...[
                        const SizedBox(width: 4),
                        _SocialIconButton(
                          icon: Iconsax.code,
                          url: githubUrl,
                        ),
                      ],
                      if (linkedinUrl != null && linkedinUrl.isNotEmpty) ...[
                        const SizedBox(width: 4),
                        _SocialIconButton(
                          icon: Iconsax.link,
                          url: linkedinUrl,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms, delay: (index * 50).ms).scale(begin: const Offset(0.95, 0.95));
  }
}

class _SocialIconButton extends StatelessWidget {
  final IconData icon;
  final String url;

  const _SocialIconButton({
    required this.icon,
    required this.url,
  });

  Future<void> _launchUrl(BuildContext context) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open link: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _launchUrl(context),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          size: 12,
          color: Colors.grey[400],
        ),
      ),
    );
  }
}
