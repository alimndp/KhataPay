import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/api_service.dart';
import '../services/supabase_service.dart';

// Supabase client provider
final supabaseProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// ApiService provider
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService(ref.watch(supabaseProvider));
});

// SupabaseService provider
final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService();
});

// Auth state provider
final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(supabaseServiceProvider).authStateChanges;
});

// Current user provider
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(supabaseServiceProvider).currentUser;
});

// Current profile provider
final currentProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  return ref.watch(apiServiceProvider).getCurrentProfile();
});

// Current user role provider
final currentUserRoleProvider = FutureProvider<String?>((ref) async {
  return ref.watch(apiServiceProvider).getCurrentUserRole();
});

// Is business owner provider
final isBusinessOwnerProvider = Provider<bool>((ref) {
  final role = ref.watch(currentUserRoleProvider).valueOrNull;
  return role == 'business_owner';
});

// Is finance or HR provider
final isStaffProvider = Provider<bool>((ref) {
  final role = ref.watch(currentUserRoleProvider).valueOrNull;
  return role == 'business_owner' || role == 'finance' || role == 'hr';
});