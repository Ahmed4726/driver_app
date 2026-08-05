import 'package:equatable/equatable.dart';

import '../../../data/models/driver_registration.dart';

abstract class RegisterEvent extends Equatable {
  const RegisterEvent();

  @override
  List<Object?> get props => [];
}

class RegisterSubmitted extends RegisterEvent {

  final DriverRegistration registration;

  const RegisterSubmitted(
    this.registration,
  );

  @override
  List<Object?> get props => [registration];
}