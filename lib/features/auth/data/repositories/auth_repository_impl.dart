import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._datasource);

  final AuthRemoteDatasource _datasource;

  @override
  Stream<AuthUser?> get authStateChanges {
    return _datasource.authStateChanges.map((state) {
      final user = state.session?.user;
      return user == null ? null : _mapUser(user);
    });
  }

  @override
  AuthUser? get currentUser {
    final user = _datasource.currentUser;
    return user == null ? null : _mapUser(user);
  }

  @override
  Future<AuthUser> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      final user = await _datasource.signUp(
        email: email,
        password: password,
        username: username,
      );
      return _mapUser(user);
    } on AppAuthException catch (error) {
      throw AuthFailure(error.message);
    }
  }

  @override
  Future<AuthUser> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final user = await _datasource.signIn(
        email: email,
        password: password,
      );
      return _mapUser(user);
    } on AppAuthException catch (error) {
      throw AuthFailure(error.message);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _datasource.signOut();
    } on AppAuthException catch (error) {
      throw AuthFailure(error.message);
    }
  }

  AuthUser _mapUser(User user) {
    return AuthUser(
      id: user.id,
      email: user.email ?? '',
      username: user.userMetadata?['username'] as String?,
    );
  }
}
