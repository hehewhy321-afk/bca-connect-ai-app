import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/services/cache_service.dart';
import '../../../core/services/connectivity_service.dart';
import '../../widgets/cached_image.dart';
import 'dart:convert';

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
    const cacheKey = 'community_members_cache';
    
    // Try to load from cache first
    try {
      final cached = CacheService.get<String>(cacheKey);
      if (cached != null) {
        final List<dynamic> jsonList = jsonDecode(cached);
        final membersList = jsonList.map((e) => Map<String, dynamic>.from(e)).toList();
        
        // Extract unique batches
        final batches = <String>{};
        for (final member in membersList) {
          if (member['batch'] != null) {
            batches.add(member['batch'].toString());
          }
        }
        
        if (mounted) {
          setState(() {
            _members = membersList;
            _availableBatches = batches.toList()..sort();
            _loading = false;
          });
        }
        
        debugPrint('Loaded ${membersList.length} community members from cache');
      }
    } catch (e) {
      debugPrint('Error loading community members from cache: $e');
    }
    
    // Check connectivity
    final connectivity = ConnectivityService();
    final isOnline = await connectivity.isOnline();
    
    if (!isOnline) {
      // If offline and we have cached data, we're done
      if (_members.isNotEmpty) {
        debugPrint('Offline: Using cached community members');
        return;
      }
      // If offline and no cache, show error
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Iconsax.wifi_square, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text('No internet connection')),
              ],
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }
    
    // Fetch from network
    try {
      final response = await SupabaseConfig.client
          .from('profiles')
          .select('*, graduation_year, current_company, job_title')
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
        
        // Cache the results
        await CacheService.set(
          cacheKey,
          jsonEncode(membersList),
          duration: CacheKeys.longCache,
        );
        
        setState(() {
          _members = membersList;
          _availableBatches = batches.toList()..sort();
          _loading = false;
        });
        
        debugPrint('Fetched and cached ${membersList.length} community members');
      }
    } catch (e) {
      debugPrint('Error fetching community members: $e');
      if (mounted) {
        setState(() => _loading = false);
        // If we have cached data, don't show error
        if (_members.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Iconsax.danger, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Error loading members: ${e.toString()}')),
                ],
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
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
    if (name.isEmpty) return 'U';
    
    final initials = name
        .split(' ')
        .where((n) => n.isNotEmpty)
        .map((n) => n[0])
        .join('')
        .toUpperCase();
    
    if (initials.isEmpty) return name[0].toUpperCase();
    if (initials.length == 1) return initials;
    return initials.substring(0, 2);
  }

  @override
  Widget build(BuildContext context) {
    final students = _members.where((m) => m['is_alumni'] != true).length;
    final alumni = _members.where((m) => m['is_alumni'] == true).length;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Iconsax.search_normal,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              style: TextStyle(color: theme.colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: 'Search by name, batch, or skills...',
                hintStyle: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
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
    final theme = Theme.of(context);
    
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
          color: selected ? null : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: selected 
              ? Colors.transparent 
              : theme.colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : theme.colorScheme.onSurface.withValues(alpha: 0.7),
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildAdvancedFilters() {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _batchFilter,
                isExpanded: true,
                dropdownColor: theme.colorScheme.surface,
                style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14),
                icon: Icon(Iconsax.arrow_down_1, color: theme.colorScheme.onSurface.withValues(alpha: 0.6), size: 16),
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
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _semesterFilter,
                isExpanded: true,
                dropdownColor: theme.colorScheme.surface,
                style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14),
                icon: Icon(Iconsax.arrow_down_1, color: theme.colorScheme.onSurface.withValues(alpha: 0.6), size: 16),
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
    final theme = Theme.of(context);
    
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
          Text(
            'No Members Found',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
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
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersGrid() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
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

  Future<void> _launchUrl(BuildContext context, String url) async {
    try {
      // Add https:// if protocol is missing
      String urlString = url.trim();
      if (!urlString.startsWith('http://') && !urlString.startsWith('https://')) {
        urlString = 'https://$urlString';
      }
      
      final uri = Uri.parse(urlString);
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open link: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAlumni = member['is_alumni'] == true;
    final avatarUrl = member['avatar_url'] as String?;
    final fullName = (member['full_name'] ?? 'Unknown').toString();
    final email = (member['email'] ?? '').toString();
    final batch = member['batch']?.toString();
    final semester = member['semester'];
    final bio = member['bio']?.toString();
    final level = member['level'] ?? 1;
    final xpPoints = member['xp_points'] ?? 0;
    final githubUrl = member['github_url']?.toString();
    final linkedinUrl = member['linkedin_url']?.toString();
    final skills = member['skills'] is List 
        ? (member['skills'] as List).map((s) => s.toString()).toList()
        : <String>[];
    
    // Alumni-specific fields
    final graduationYear = member['graduation_year'];
    final currentCompany = member['current_company']?.toString();
    final jobTitle = member['job_title']?.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFDA7809).withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section with Avatar and Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFFDA7809).withValues(alpha: 0.08),
                    const Color(0xFFFF9500).withValues(alpha: 0.03),
                  ],
                ),
              ),
              child: Row(
                children: [
                  // Avatar with glow effect
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFDA7809).withValues(alpha: 0.3),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFDA7809), Color(0xFFFF9500)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: avatarUrl != null
                          ? CachedImage(
                              imageUrl: avatarUrl,
                              width: 64,
                              height: 64,
                              fit: BoxFit.cover,
                              borderRadius: BorderRadius.circular(16),
                              errorWidget: Center(
                                child: Text(
                                  getInitials(fullName),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
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
                                  fontSize: 20,
                                ),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Name and Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fullName,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            letterSpacing: -0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            if (batch != null && batch.isNotEmpty) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  batch,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (isAlumni) const SizedBox(width: 6),
                            ],
                            if (isAlumni)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: const Text(
                                  'Alumni',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Level Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFDA7809), Color(0xFFFF9500)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFDA7809).withValues(alpha: 0.4),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Iconsax.award5,
                          size: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$level',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Semester (for students only)
                  if (!isAlumni && semester != null) ...[
                    Row(
                      children: [
                        Icon(
                          Iconsax.book_1,
                          size: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Semester $semester',
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Alumni-specific information
                  if (isAlumni) ...[
                    // Job Title
                    if (jobTitle != null && jobTitle.isNotEmpty) ...[
                      Row(
                        children: [
                          Icon(
                            Iconsax.briefcase,
                            size: 14,
                            color: const Color(0xFF8B5CF6),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              jobTitle,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF8B5CF6),
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    
                    // Current Company
                    if (currentCompany != null && currentCompany.isNotEmpty) ...[
                      Row(
                        children: [
                          Icon(
                            Iconsax.building,
                            size: 14,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              currentCompany,
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    
                    // Graduation Year
                    if (graduationYear != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Iconsax.medal_star,
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Class of $graduationYear',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],

                  // Bio
                  if (bio != null && bio.isNotEmpty) ...[
                    Text(
                      bio,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                  ],

                  // XP Points
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Iconsax.star5,
                          size: 16,
                          color: Colors.amber[400],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$xpPoints XP',
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Skills
                  if (skills.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ...skills.take(3).map((skill) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFFDA7809).withValues(alpha: 0.2),
                                ),
                              ),
                              child: Text(
                                skill,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.onSurface,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            )),
                        if (skills.length > 3)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFDA7809), Color(0xFFFF9500)],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '+${skills.length - 3}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],

                  // Social Links
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      if (githubUrl != null && githubUrl.trim().isNotEmpty)
                        Expanded(
                          child: InkWell(
                            onTap: () => _launchUrl(context, githubUrl),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Iconsax.code_circle,
                                    size: 18,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'GitHub',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Theme.of(context).colorScheme.onSurface,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      if (githubUrl != null && githubUrl.trim().isNotEmpty && 
                          linkedinUrl != null && linkedinUrl.trim().isNotEmpty)
                        const SizedBox(width: 8),
                      if (linkedinUrl != null && linkedinUrl.trim().isNotEmpty)
                        Expanded(
                          child: InkWell(
                            onTap: () => _launchUrl(context, linkedinUrl),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Iconsax.profile_2user,
                                    size: 18,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'LinkedIn',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Theme.of(context).colorScheme.onSurface,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      if ((githubUrl != null && githubUrl.trim().isNotEmpty) || 
                          (linkedinUrl != null && linkedinUrl.trim().isNotEmpty))
                        const SizedBox(width: 8),
                      if (email.isNotEmpty)
                        Expanded(
                          child: InkWell(
                            onTap: () => _launchUrl(context, 'mailto:$email'),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Iconsax.sms,
                                    size: 18,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Email',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Theme.of(context).colorScheme.onSurface,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
    ).animate().fadeIn(duration: 300.ms, delay: (index * 50).ms).slideY(begin: 0.1, end: 0);
  }
}
