import 'package:equatable/equatable.dart';
import '../../models/user_model.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginRequested({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

class AuthSignupRequested extends AuthEvent {
  final String email;
  final String password;
  final String fullName;
  final String username;

  const AuthSignupRequested({
    required this.email,
    required this.password,
    required this.fullName,
    required this.username,
  });

  @override
  List<Object?> get props => [email, password, fullName, username];
}

class AuthLogoutRequested extends AuthEvent {}

class AuthCheckRequested extends AuthEvent {}

class AuthUserChanged extends AuthEvent {
  final UserModel? user;

  const AuthUserChanged({required this.user});

  @override
  List<Object?> get props => [user];
}