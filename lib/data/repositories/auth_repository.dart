import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/config/supabase_config.dart';

class AuthRepository {
  final SupabaseClient _client = SupabaseConfig.client;

  // Get current user
  User? get currentUser => _client.auth.currentUser;

  // Auth state stream
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // Sign in with email and password
  Future<AuthResponse> signIn(String email, String password) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // Sign up with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );
  }

  // Sign out
  Future<void> signOut() async {
    await _client.auth.signOut();
    
    // Clear saved credentials when user manually logs out
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('remember_me');
    await prefs.remove('saved_email');
    await prefs.remove('saved_password');
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  // Check if user is banned
  Future<Map<String, dynamic>?> checkBanStatus(String userId) async {
    try {
      final response = await _client.rpc(
        'check_user_ban_status',
        params: {'user_id_param': userId},
      );
      return response as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('Error checking ban status: $e');
      return null;
    }
  }
}
