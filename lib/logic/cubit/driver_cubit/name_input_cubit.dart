import 'package:flutter_bloc/flutter_bloc.dart';

// State class for NameInputCubit
class NameInputState {
  final String firstName;
  final String lastName;
  final bool isFormValid;

  NameInputState({
    required this.firstName,
    required this.lastName,
    required this.isFormValid,
  });

  // Creates a copy of the current state with the provided values
  NameInputState copyWith({
    String? firstName,
    String? lastName,
    bool? isFormValid,
  }) {
    return NameInputState(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      isFormValid: isFormValid ?? this.isFormValid,
    );
  }
}

// Cubit to manage name input state
class NameInputCubit extends Cubit<NameInputState> {
  // Store the registration data from previous screens
  final Map<String, String> registrationData;

  // Constructor takes registration data from previous screens
  NameInputCubit({required this.registrationData})
      : super(NameInputState(
          firstName: '',
          lastName: '',
          isFormValid: false,
        ));

  // Update first name and validate form
  void updateFirstName(String firstName) {
    final isValid = firstName.isNotEmpty && state.lastName.isNotEmpty;
    emit(state.copyWith(
      firstName: firstName,
      isFormValid: isValid,
    ));
  }

  // Update last name and validate form
  void updateLastName(String lastName) {
    final isValid = state.firstName.isNotEmpty && lastName.isNotEmpty;
    emit(state.copyWith(
      lastName: lastName,
      isFormValid: isValid,
    ));
  }

  // Validate all fields are properly filled
  bool validateForm() {
    return state.firstName.isNotEmpty && state.lastName.isNotEmpty;
  }

  // Get complete form data for next screen
  Map<String, String> getFormData() {
    // Combine existing registration data with name information
    return {
      ...registrationData,
      'first_name': state.firstName,
      'last_name': state.lastName,
    };
  }
}
