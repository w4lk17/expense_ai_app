import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:expense_ai_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:expense_ai_app/features/auth/domain/repositories/auth_repository.dart';

// Provider pour le Repository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(Supabase.instance.client.auth);
});

// Provider qui expose l'état de l'authentification (User ou null)
final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

// Provider pratique pour récupérer l'utilisateur actuel directement
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.asData?.value.session?.user;
});
