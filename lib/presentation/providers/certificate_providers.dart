import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/certificate.dart';
import '../../data/repositories/certificate_repository.dart';

// Provider for all certificates
final allCertificatesProvider = FutureProvider<List<Certificate>>((ref) async {
  final repo = CertificateRepository();
  return await repo.getUserCertificates();
});

// State providers for search and filters
final certificateSearchQueryProvider = StateProvider<String>((ref) => '');
final certificateSelectedYearProvider = StateProvider<String>((ref) => 'all');
final certificateSelectedCategoryProvider = StateProvider<String>((ref) => 'all');

// Filtered certificates provider
final filteredCertificatesProvider = Provider<AsyncValue<List<Certificate>>>((ref) {
  final certificatesAsync = ref.watch(allCertificatesProvider);
  final searchQuery = ref.watch(certificateSearchQueryProvider).toLowerCase();
  final selectedYear = ref.watch(certificateSelectedYearProvider);
  final selectedCategory = ref.watch(certificateSelectedCategoryProvider);

  return certificatesAsync.whenData((certificates) {
    return certificates.where((certificate) {
      final matchesSearch = certificate.title.toLowerCase().contains(searchQuery) ||
          (certificate.description?.toLowerCase().contains(searchQuery) ?? false) ||
          certificate.verificationCode.toLowerCase().contains(searchQuery);
      
      final matchesYear = selectedYear == 'all' ||
          certificate.issueDate.year.toString() == selectedYear;
      
      // Category matching - use the categoryName from the joined data
      final certificateCategory = certificate.categoryName?.toLowerCase() ?? '';
      final matchesCategory = selectedCategory == 'all' ||
          certificateCategory == selectedCategory;
      
      return matchesSearch && matchesYear && matchesCategory;
    }).toList();
  });
});
