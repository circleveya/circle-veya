import 'package:equatable/equatable.dart';

class AuthUser extends Equatable {
  const AuthUser({
    required this.id,
    required this.email,
    this.username,
  });

  final String id;
  final String email;
  final String? username;

  @override
  List<Object?> get props => [id, email, username];
}
