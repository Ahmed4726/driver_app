import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/login_request.dart';
import '../../data/repositories/auth_repository.dart';

import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository repository;

  AuthBloc(this.repository) : super(AuthInitial()) {
    on<LoginSubmitted>(_login);

    on<LogoutRequested>(_logout);

    on<CheckAuthentication>(_checkAuthentication);

    on<UpdateDriverProfileSubmitted>(_updateDriverProfile);

    on<ProfileUpdateSubmitted>(_updateProfile);
  }

  Future<void> _login(
    LoginSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final response = await repository.login(
        LoginRequest(
          email: event.email,
          password: event.password,
        ),
      );

      emit(AuthAuthenticated(response.user));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _logout(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await repository.logout();

    emit(AuthUnauthenticated());
  }

  Future<void> _updateDriverProfile(
    UpdateDriverProfileSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final user = await repository.updateDriverProfile(event.request);

      emit(AuthUpdateSuccessful(user));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _updateProfile(
    ProfileUpdateSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final user = await repository.updateProfile(event.request);

      emit(AuthUpdateSuccessful(user));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _checkAuthentication(
    CheckAuthentication event,
    Emitter<AuthState> emit,
  ) async {
    final loggedIn = await repository.isLoggedIn();

    if (!loggedIn) {
      emit(AuthUnauthenticated());
      return;
    }

    emit(AuthLoading());

    try {
      final user = await repository.profile();

      emit(AuthAuthenticated(user));
    } catch (_) {
      try {
        await repository.logout();
      } catch (_) {
        // Ignore logout errors here; user is already unauthenticated.
      }

      emit(AuthUnauthenticated());
    }
  }
}