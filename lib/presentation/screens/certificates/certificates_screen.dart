import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/models/certificate.dart';
import '../../providers/certificate_providers.dart';
import '../../widgets/skeleton_loader.dart';

class CertificatesScreen extends ConsumerStatefulWidget {
  const CertificatesScreen({super.key});

  @override
  ConsumerState<CertificatesScreen> createState() => _CertificatesScreenState();
}

class _CertificatesScreenState extends ConsumerState<CertificatesScreen> {
  String _selectedYear = 'all';
  String _selectedCategory = 'all';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _viewCertificate() async {
    final url = Uri.parse('https://mmamc-bca.vercel.app/dashboard/certificates');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open certificate viewer'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredCertificatesAsync = ref.watch(filteredCertificatesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: Column(
        children: [
          // Purple Gradient Header
          _buildGradientHeader(context),
          
          // Search Bar
          _buildSearchBar(),
          
          // Filter Chips
          _buildFilterChips(),
          
          // Certificates List
          Expanded(
            child: filteredCertificatesAsync.when(
              data: (certificates) => _buildCertificatesList(certificates),
              loading: () => _buildLoadingState(),
              error: (error, stack) => _buildErrorState(error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientHeader(BuildContext context) {
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
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Iconsax.award,
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
                      'My Certificates',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Your achievements & awards',
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
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 16),
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
              controller: _searchController,
              onChanged: (value) {
                setState(() {});
                ref.read(certificateSearchQueryProvider.notifier).state = value;
              },
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search certificates...',
                hintStyle: TextStyle(color: Colors.grey[600]),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: Icon(Icons.close, color: Colors.grey[500], size: 20),
              onPressed: () {
                setState(() {
                  _searchController.clear();
                });
                ref.read(certificateSearchQueryProvider.notifier).state = '';
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Column(
      children: [
        // Year filters
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              _buildChip('All Years', 'all', true),
              const SizedBox(width: 8),
              Consumer(
                builder: (context, ref, child) {
                  final allCerts = ref.watch(allCertificatesProvider);
                  return allCerts.when(
                    data: (certs) {
                      final years = certs.map((c) => c.issueDate.year.toString()).toSet().toList();
                      years.sort((a, b) => b.compareTo(a));
                      return Row(
                        children: years.map((year) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _buildChip(year, year, true),
                        )).toList(),
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (e, stack) => const SizedBox.shrink(),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Category filters
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              _buildChip('All Categories', 'all', false),
              const SizedBox(width: 8),
              _buildChip('Competition', 'competition', false),
              const SizedBox(width: 8),
              _buildChip('Course', 'course', false),
              const SizedBox(width: 8),
              _buildChip('Hackathon', 'hackathon', false),
              const SizedBox(width: 8),
              _buildChip('Seminar', 'seminar', false),
              const SizedBox(width: 8),
              _buildChip('Sports', 'sports', false),
              const SizedBox(width: 8),
              _buildChip('Volunteer', 'volunteer', false),
              const SizedBox(width: 8),
              _buildChip('Workshop', 'workshop', false),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildChip(String label, String value, bool isYear) {
    final isSelected = isYear 
      ? _selectedYear == value 
      : _selectedCategory == value;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isYear) {
            _selectedYear = value;
            ref.read(certificateSelectedYearProvider.notifier).state = value;
          } else {
            _selectedCategory = value;
            ref.read(certificateSelectedCategoryProvider.notifier).state = value;
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
            ? const LinearGradient(
                colors: [Color(0xFFDA7809), Color(0xFFFF9500)],
              )
            : null,
          color: isSelected ? null : const Color(0xFF1F1F1F),
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: isSelected 
              ? Colors.transparent 
              : Colors.grey.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[400],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildCertificatesList(List<Certificate> certificates) {
    if (certificates.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      itemCount: certificates.length,
      itemBuilder: (context, index) {
        return _CertificateCard(
          certificate: certificates[index],
          onView: _viewCertificate,
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF14B8A6).withValues(alpha: 0.1),
                  const Color(0xFF06B6D4).withValues(alpha: 0.05),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Iconsax.award,
              size: 80,
              color: const Color(0xFF14B8A6).withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Certificates Yet',
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
              'Participate in events and activities to earn certificates!',
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

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 3,
      itemBuilder: (context, index) => const Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: EventCardSkeleton(),
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.info_circle, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          const Text(
            'Oops! Something went wrong',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[400]),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => ref.invalidate(allCertificatesProvider),
            icon: const Icon(Iconsax.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF14B8A6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CertificateCard extends StatelessWidget {
  final Certificate certificate;
  final VoidCallback onView;

  const _CertificateCard({
    required this.certificate,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.fromARGB(255, 1, 30, 26), // Teal
            Color.fromARGB(255, 17, 33, 36), // Cyan
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Header with icon and badge
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Iconsax.award,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Certificate',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Iconsax.document_download,
                            color: Colors.white.withValues(alpha: 0.8),
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Downloadable',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 12,
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
          
          // Content section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFF1A1A1A),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  certificate.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                if (certificate.description != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    certificate.description!,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                
                const SizedBox(height: 16),
                
                // Info chips
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2A2A),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Colors.grey.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Iconsax.calendar,
                            color: Color(0xFF14B8A6),
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            DateFormat('MMM dd, yyyy').format(certificate.issueDate),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2A2A),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Colors.grey.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Iconsax.shield_tick,
                              color: Color(0xFF14B8A6),
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                certificate.verificationCode,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // View Certificate button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onView,
                    icon: const Icon(Iconsax.eye, size: 18),
                    label: const Text('View Certificate'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDA7809),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
