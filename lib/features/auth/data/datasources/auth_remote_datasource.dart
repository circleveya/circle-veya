import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

import '../../../../core/auth/auth_error_messages.dart';
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
    String userType = 'standard',
  }) async {
    try {
      final safeType =
          userType == 'event' || userType == 'company' ? 'event' : 'standard';
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'username': username,
          'user_type': safeType,
        },
      );

      final user = response.user;
      if (user == null) {
        throw const AppAuthException('Registrierung fehlgeschlagen.');
      }

      return user;
    } on AuthException catch (error) {
      throw AppAuthException(mapSupabaseAuthException(error));
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('CircleVeya signUp error: $error\n$stackTrace');
      }
      throw AppAuthException(formatAuthError(error));
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
        if (response.session == null) {
          throw const AppAuthException(
            'Bitte bestätige zuerst deine E-Mail-Adresse (Link in deinem Postfach).',
          );
        }
        throw const AppAuthException('Anmeldung fehlgeschlagen.');
      }

      return user;
    } on AuthException catch (error) {
      throw AppAuthException(mapSupabaseAuthException(error));
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('CircleVeya signIn error: $error\n$stackTrace');
      }
      throw AppAuthException(formatAuthError(error));
    }
  }

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } on AuthException catch (error) {
      throw AppAuthException(mapSupabaseAuthException(error));
    } catch (error) {
      throw AppAuthException(formatAuthError(error));
    }
  }
}
