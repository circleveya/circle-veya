import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';

/// Fallback wenn Supabase nicht konfiguriert ist (lokale UI-Entwicklung/Tests).
class UnconfiguredAuthRepository implements AuthRepository {
  const UnconfiguredAuthRepository();

  static const _message =
      'Supabase ist nicht konfiguriert. Bitte SUPABASE_URL und '
      'SUPABASE_ANON_KEY setzen.';

  @override
  Stream<AuthUser?> get authStateChanges => Stream.value(null);

  @override
  AuthUser? get currentUser => null;

  @override
  Future<AuthUser> signIn({
    required String email,
    required String password,
  }) {
    throw UnsupportedError(_message);
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<AuthUser> signUp({
    required String email,
    required String password,
    required String username,
  }) {
    throw UnsupportedError(_message);
  }
}
