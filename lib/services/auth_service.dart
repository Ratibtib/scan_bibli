import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static SupabaseClient get _client => Supabase.instance.client;

  static User? get currentUser => _client.auth.currentUser;
  static bool get isLoggedIn => currentUser != null;

  static Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  static Future<String?> signIn(String email, String password) async {
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
      return null;
    } on AuthException catch (e) {
      return _translateError(e.message);
    } catch (e) {
      return e.toString();
    }
  }

  static Future<String?> signUp(String email, String password) async {
    try {
      await _client.auth.signUp(email: email, password: password);
      return null;
    } on AuthException catch (e) {
      return _translateError(e.message);
    } catch (e) {
      return e.toString();
    }
  }

  static Future<void> signOut() async {
    await _client.auth.signOut();
  }

  static String _translateError(String msg) {
    if (msg.contains('Invalid login credentials')) return 'Email ou mot de passe incorrect.';
    if (msg.contains('Email not confirmed')) return 'Confirmez votre email avant de vous connecter.';
    if (msg.contains('User already registered')) return 'Un compte existe déjà avec cet email.';
    if (msg.contains('Password should be')) return 'Mot de passe trop court (6 caractères min).';
    if (msg.contains('Unable to validate')) return 'Email invalide.';
    return msg;
  }
}
