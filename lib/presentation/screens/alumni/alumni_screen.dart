import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/modern_theme.dart';
import '../../../core/config/supabase_config.dart';

class AlumniScreen extends ConsumerStatefulWidget {
  const AlumniScreen({super.key});

  @override
  ConsumerState<AlumniScreen> createState() => _AlumniScreenState();
}

class _AlumniScreenState extends ConsumerState<AlumniScreen> {
  bool _loading = true;
  String _searchQuery = '';
  String _graduationYearFilter = 'all';
  List<Map<String, dynamic>> _alumni = [];
  List<int> _graduationYears = [];

  @override
  void initState() {
    super.initState();
    _fetchAlumni();
  }

  Future<void> _fetchAlumni() async {
    try {
      final response = await SupabaseConfig.client
          .from('profiles')
          .select()
          .eq('is_alumni', true)
          .order('graduation_year', ascending: false);

      if (mounted) {
        final alumniList = List<Map<String, dynamic>>.from(response);
        final years = <int>[];
        for (var a in alumniList) {
          if (a['graduation_year'] != null) {
            years.add(a['graduation_year'] as int);
          }
        }
        final uniqueYears = years.toSet().toList()..sort((a, b) => b.compareTo(a));

        setState(() {
          _alumni = alumniList;
          _graduationYears = uniqueYears;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  List<Map<String, dynamic>> get _filteredAlumni {
    return _alumni.where((member) {
      final fullName = member['full_name']?.toString() ?? '';
      final company = member['current_company']?.toString() ?? '';
      final matchesSearch = fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          company.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesYear = _graduationYearFilter == 'all' ||
          member['graduation_year']?.toString() == _graduationYearFilter;

      return matchesSearch && matchesYear;
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
    final companies = _alumni
        .where((a) => a['current_company'] != null)
        .map((a) => a['current_company'])
        .toSet()
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Iconsax.medal_star5, color: ModernTheme.primaryOrange),
            SizedBox(width: 12),
            Text('Alumni Directory'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchAlumni,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            icon: Iconsax.people5,
                            label: 'Total Alumni',
                            value: _alumni.length.toString(),
                            color: ModernTheme.primaryOrange,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            icon: Iconsax.building5,
                            label: 'Companies',
                            value: companies.toString(),
                            color: ModernTheme.accentOrange,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            icon: Iconsax.calendar5,
                            label: 'Grad Years',
                            value: _graduationYears.length.toString(),
                            color: ModernTheme.accentOrange,
                          ),
                        ),
                      ],
                    ).animate().fadeIn(duration: 300.ms),

                    const SizedBox(height: 24),

                    // Search Bar
                    TextField(
                      onChanged: (value) => setState(() => _searchQuery = value),
                      decoration: InputDecoration(
                        hintText: 'Search alumni by name or company...',
                        prefixIcon: const Icon(Iconsax.search_normal),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ).animate().fadeIn(duration: 300.ms, delay: 100.ms),

                    const SizedBox(height: 16),

                    // Graduation Year Filter
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _FilterChip(
                            label: 'All Years',
                            selected: _graduationYearFilter == 'all',
                            onTap: () => setState(() => _graduationYearFilter = 'all'),
                          ),
                          const SizedBox(width: 8),
                          ..._graduationYears.map((year) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: _FilterChip(
                                  label: 'Class of $year',
                                  selected: _graduationYearFilter == year.toString(),
                                  onTap: () =>
                                      setState(() => _graduationYearFilter = year.toString()),
                                ),
                              )),
                        ],
                      ),
                    ).animate().fadeIn(duration: 300.ms, delay: 200.ms),

                    const SizedBox(height: 16),

                    // Results Count
                    Text(
                      'Showing ${_filteredAlumni.length} of ${_alumni.length} alumni',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),

                    const SizedBox(height: 16),

                    // Alumni List
                    if (_filteredAlumni.isEmpty)
                      Center(
                        child: Column(
                          children: [
                            const SizedBox(height: 48),
                            Icon(
                              Iconsax.medal_star,
                              size: 64,
                              color: Theme.of(context).textTheme.bodySmall?.color,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No alumni found',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try adjusting your search or filters',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _filteredAlumni.length,
                        itemBuilder: (context, index) {
                          final alumni = _filteredAlumni[index];
                          return _AlumniCard(
                            alumni: alumni,
                            getInitials: _getInitials,
                            index: index,
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: selected ? ModernTheme.orangeGradient : null,
          color: selected ? null : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? Colors.transparent : Theme.of(context).dividerColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : null,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
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
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _AlumniCard extends StatelessWidget {
  final Map<String, dynamic> alumni;
  final String Function(String) getInitials;
  final int index;

  const _AlumniCard({
    required this.alumni,
    required this.getInitials,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final avatarUrl = alumni['avatar_url'];
    final fullName = alumni['full_name'] ?? 'Unknown';
    final jobTitle = alumni['job_title'];
    final currentCompany = alumni['current_company'];
    final graduationYear = alumni['graduation_year'];
    final batch = alumni['batch'];
    final bio = alumni['bio'];
    final skills = alumni['skills'] as List?;
    final level = alumni['level'] ?? 1;
    final xpPoints = alumni['xp_points'] ?? 0;
    final githubUrl = alumni['github_url'];
    final linkedinUrl = alumni['linkedin_url'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: ModernTheme.orangeGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: avatarUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.network(
                          avatarUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Center(
                            child: Text(
                              getInitials(fullName),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
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
                            fontSize: 18,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    if (jobTitle != null)
                      Text(
                        jobTitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: ModernTheme.primaryOrange,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    if (currentCompany != null)
                      Row(
                        children: [
                          Icon(
                            Iconsax.building,
                            size: 14,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              currentCompany,
                              style: Theme.of(context).textTheme.bodySmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Info
          Row(
            children: [
              if (graduationYear != null) ...[
                Icon(
                  Iconsax.calendar,
                  size: 14,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
                const SizedBox(width: 4),
                Text(
                  'Class of $graduationYear',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              if (batch != null) ...[
                const SizedBox(width: 16),
                Text(
                  'Batch: $batch',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),

          if (bio != null) ...[
            const SizedBox(height: 8),
            Text(
              bio,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          if (skills != null && skills.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ...skills.take(3).map((skill) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: ModernTheme.primaryOrange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        skill,
                        style: TextStyle(
                          fontSize: 11,
                          color: ModernTheme.primaryOrange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )),
                if (skills.length > 3)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).dividerColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '+${skills.length - 3}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ],

          const SizedBox(height: 12),

          // Footer
          Row(
            children: [
              if (githubUrl != null)
                _SocialButton(
                  icon: Iconsax.code,
                  onTap: () {},
                ),
              if (linkedinUrl != null) ...[
                const SizedBox(width: 8),
                _SocialButton(
                  icon: Iconsax.link,
                  onTap: () {},
                ),
              ],
              const Spacer(),
              Text(
                'Level $level • $xpPoints XP',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms, delay: (index * 50).ms).slideX(begin: 0.2);
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _SocialButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18),
      ),
    );
  }
}
