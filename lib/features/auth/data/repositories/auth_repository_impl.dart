import 'package:expense_ai_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepositoryImpl implements AuthRepository {
  final GoTrueClient _supabaseAuth;

  AuthRepositoryImpl(this._supabaseAuth);

  @override
  User? get currentUser => _supabaseAuth.currentUser;

  @override
  Stream<AuthState> get authStateChanges => _supabaseAuth.onAuthStateChange;

  @override
  Future<void> signUp(String email, String password) async {
    await _supabaseAuth.signUp(email: email, password: password);
  }

  @override
  Future<void> signIn(String email, String password) async {
    await _supabaseAuth.signInWithPassword(email: email, password: password);
  }

  @override
  Future<void> signOut() async {
    await _supabaseAuth.signOut();
  }
}
