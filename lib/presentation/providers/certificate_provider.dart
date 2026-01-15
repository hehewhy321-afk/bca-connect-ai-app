import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/certificate_repository.dart';
import '../../data/models/certificate.dart';
import '../../data/mock/mock_data.dart';

// Certificate Repository Provider
final certificateRepositoryProvider = Provider<CertificateRepository>((ref) {
  return CertificateRepository();
});

// User Certificates Provider with Mock Data Fallback
final userCertificatesProvider = FutureProvider<List<Certificate>>((ref) async {
  try {
    final certificates = await ref.watch(certificateRepositoryProvider).getUserCertificates();
    // If no certificates from backend, use mock data
    if (certificates.isEmpty) {
      return MockData.getMockCertificates();
    }
    return certificates;
  } catch (e) {
    debugPrint('Error loading certificates, using mock data: $e');
    // Return mock data on error
    return MockData.getMockCertificates();
  }
});

// Certificate Detail Provider
final certificateDetailProvider = FutureProvider.family<Certificate?, String>((ref, id) async {
  try {
    return await ref.watch(certificateRepositoryProvider).getCertificateById(id);
  } catch (e) {
    debugPrint('Error loading certificate detail: $e');
    return null;
  }
});

