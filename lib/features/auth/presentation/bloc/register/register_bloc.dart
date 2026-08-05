import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/auth_repository.dart';

import 'register_event.dart';
import 'register_state.dart';

class RegisterBloc extends Bloc<RegisterEvent, RegisterState> {
  final AuthRepository repository;

  RegisterBloc(this.repository) : super(RegisterInitial()) {
    on<RegisterSubmitted>(_register);
  }

  Future<void> _register(
    RegisterSubmitted event,
    Emitter<RegisterState> emit,
  ) async {
    emit(RegisterLoading());

    try {
      await repository.register(event.registration);

      emit(
        const RegisterSuccess(
          'Registration submitted successfully. Please wait for admin approval.',
        ),
      );
    } catch (e) {
      emit(RegisterFailure(e.toString()));
    }
  }
}