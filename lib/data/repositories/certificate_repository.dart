import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../../core/config/supabase_config.dart';
import '../models/certificate.dart';

class CertificateRepository {
  final SupabaseClient _client = SupabaseConfig.client;

  // Get user certificates
  Future<List<Certificate>> getUserCertificates() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final response = await _client
          .from('certificates')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List).map((e) => Certificate.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error fetching certificates: $e');
      return [];
    }
  }

  // Get all certificates (for admin)
  Future<List<Certificate>> getAllCertificates({int limit = 50}) async {
    try {
      final response = await _client
          .from('certificates')
          .select()
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List).map((e) => Certificate.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error fetching all certificates: $e');
      return [];
    }
  }

  // Get certificate by ID
  Future<Certificate?> getCertificateById(String id) async {
    try {
      final response = await _client
          .from('certificates')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;
      return Certificate.fromJson(response);
    } catch (e) {
      debugPrint('Error fetching certificate: $e');
      return null;
    }
  }

  // Verify certificate by verification code
  Future<Certificate?> verifyCertificate(String verificationCode) async {
    try {
      final response = await _client
          .from('certificates')
          .select()
          .eq('verification_code', verificationCode)
          .maybeSingle();

      if (response == null) return null;
      return Certificate.fromJson(response);
    } catch (e) {
      debugPrint('Error verifying certificate: $e');
      return null;
    }
  }
}
