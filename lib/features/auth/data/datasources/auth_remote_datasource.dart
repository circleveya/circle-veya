import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException, AuthUser;

import '../../../../core/errors/exceptions.dart';

class AuthRemoteDatasource {
  AuthRemoteDatasource(this._client);

  final SupabaseClient _client;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  User? get currentUser => _client.auth.currentUser;

  Future<User> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'username': username},
      );

      final user = response.user;
      if (user == null) {
        throw const AppAuthException('Registrierung fehlgeschlagen.');
      }

      return user;
    } on AuthApiException catch (error) {
      throw AppAuthException(error.message);
    } catch (_) {
      throw const AppAuthException('Registrierung fehlgeschlagen.');
    }
  }

  Future<User> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = response.user;
      if (user == null) {
        throw const AppAuthException('Anmeldung fehlgeschlagen.');
      }

      return user;
    } on AuthApiException catch (error) {
      throw AppAuthException(error.message);
    } catch (_) {
      throw const AppAuthException('Anmeldung fehlgeschlagen.');
    }
  }

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } on AuthApiException catch (error) {
      throw AppAuthException(error.message);
    }
  }
}
