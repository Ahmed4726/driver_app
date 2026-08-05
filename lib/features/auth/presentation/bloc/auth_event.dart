import 'package:equatable/equatable.dart';

import '../../data/models/update_driver_request.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class LoginSubmitted extends AuthEvent {
  final String email;
  final String password;

  const LoginSubmitted({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [
        email,
        password,
      ];
}

class LogoutRequested extends AuthEvent {}

class CheckAuthentication extends AuthEvent {}

class UpdateDriverProfileSubmitted extends AuthEvent {
  final UpdateDriverRequest request;

  const UpdateDriverProfileSubmitted({
    required this.request,
  });

  @override
  List<Object?> get props => [request];
}

class ProfileUpdateSubmitted extends AuthEvent {
  final UpdateDriverRequest request;

  const ProfileUpdateSubmitted({
    required this.request,
  });

  @override
  List<Object?> get props => [request];
}