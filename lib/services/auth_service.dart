import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/user_model.dart';

class AuthService {
  final _supabase = SupabaseConfig.client;

  User? get currentUser => _supabase.auth.currentUser;

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String username,
  }) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {'username': username},
    );

    if (response.user != null) {
      // Create user profile in users table
      await _supabase.from('users').insert({
        'id': response.user!.id,
        'email': email,
        'username': username,
        'skill_level': 'beginner',
        'dietary_restrictions': [],
        'chef_score': 0.0,
      });
    }

    return response;
  }

  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  Future<UserModel?> getCurrentUserProfile() async {
    final user = currentUser;
    if (user == null) return null;

    final response = await _supabase
        .from('users')
        .select()
        .eq('id', user.id)
        .single();

    return UserModel.fromJson(response);
  }

  Future<UserModel> updateUserProfile({
    String? displayName,
    String? bio,
    String? profilePictureUrl,
    String? skillLevel,
    List<String>? dietaryRestrictions,
    List<String>? cuisinePreferences,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception('User not authenticated');

    final updates = <String, dynamic>{};
    if (displayName != null) updates['display_name'] = displayName;
    if (bio != null) updates['bio'] = bio;
    if (profilePictureUrl != null) updates['profile_picture_url'] = profilePictureUrl;
    if (skillLevel != null) updates['skill_level'] = skillLevel;
    if (dietaryRestrictions != null) updates['dietary_restrictions'] = dietaryRestrictions;
    if (cuisinePreferences != null) updates['cuisine_preferences'] = cuisinePreferences;
    updates['updated_at'] = DateTime.now().toIso8601String();

    await _supabase
        .from('users')
        .update(updates)
        .eq('id', user.id);

    final response = await _supabase
        .from('users')
        .select()
        .eq('id', user.id)
        .single();

    return UserModel.fromJson(response);
  }
}
