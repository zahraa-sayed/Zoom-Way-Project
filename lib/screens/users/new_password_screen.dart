import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// CUBIT
class PasswordCubit extends Cubit<PasswordState> {
  PasswordCubit() : super(PasswordState());

  void updatePassword(String password) {
    final hasMinLength = password.length >= 8;
    final hasUppercase = password.contains(RegExp(r'[A-Z]'));
    final hasLowercase = password.contains(RegExp(r'[a-z]'));
    final hasDigit = password.contains(RegExp(r'[0-9]'));
    final hasSpecialChar = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

    final isStrong = hasMinLength &&
        hasUppercase &&
        hasLowercase &&
        hasDigit &&
        hasSpecialChar;

    emit(state.copyWith(
      password: password,
      isPasswordValid: hasMinLength,
      isPasswordStrong: isStrong,
    ));
  }

  void updateConfirmPassword(String confirmPassword) {
    emit(state.copyWith(
      confirmPassword: confirmPassword,
      doPasswordsMatch: confirmPassword == state.password,
    ));
  }

  void togglePasswordVisibility() {
    emit(state.copyWith(
      isPasswordVisible: !state.isPasswordVisible,
    ));
  }

  void toggleConfirmPasswordVisibility() {
    emit(state.copyWith(
      isConfirmPasswordVisible: !state.isConfirmPasswordVisible,
    ));
  }

  void submitPassword() {
    if (!state.isPasswordValid || !state.doPasswordsMatch) return;

    emit(state.copyWith(isSubmitting: true));

    // Simulate API call
    Future.delayed(const Duration(seconds: 1), () {
      // Handle success - typically navigate away or show success message
      emit(state.copyWith(
        isSubmitting: false,
        isSubmitSuccess: true,
      ));
    });
  }
}

class PasswordState {
  final String password;
  final String confirmPassword;
  final bool isPasswordVisible;
  final bool isConfirmPasswordVisible;
  final bool isPasswordValid;
  final bool isPasswordStrong;
  final bool doPasswordsMatch;
  final bool isSubmitting;
  final bool isSubmitSuccess;

  PasswordState({
    this.password = '',
    this.confirmPassword = '',
    this.isPasswordVisible = false,
    this.isConfirmPasswordVisible = false,
    this.isPasswordValid = false,
    this.isPasswordStrong = false,
    this.doPasswordsMatch = false,
    this.isSubmitting = false,
    this.isSubmitSuccess = false,
  });

  PasswordState copyWith({
    String? password,
    String? confirmPassword,
    bool? isPasswordVisible,
    bool? isConfirmPasswordVisible,
    bool? isPasswordValid,
    bool? isPasswordStrong,
    bool? doPasswordsMatch,
    bool? isSubmitting,
    bool? isSubmitSuccess,
  }) {
    return PasswordState(
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      isPasswordVisible: isPasswordVisible ?? this.isPasswordVisible,
      isConfirmPasswordVisible:
          isConfirmPasswordVisible ?? this.isConfirmPasswordVisible,
      isPasswordValid: isPasswordValid ?? this.isPasswordValid,
      isPasswordStrong: isPasswordStrong ?? this.isPasswordStrong,
      doPasswordsMatch: doPasswordsMatch ?? this.doPasswordsMatch,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSubmitSuccess: isSubmitSuccess ?? this.isSubmitSuccess,
    );
  }
}

// SCREEN
class NewPasswordScreen extends StatelessWidget {
  const NewPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PasswordCubit(),
      child: const Scaffold(
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: NewPasswordView(),
          ),
        ),
      ),
    );
  }
}

// VIEW
class NewPasswordView extends StatelessWidget {
  const NewPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Back button
        IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
          padding: EdgeInsets.zero,
          alignment: Alignment.centerLeft,
        ),
        const SizedBox(height: 20),

        // Title
        const Text(
          'Enter new password',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),

        // Password fields
        const PasswordInputField(),
        const SizedBox(height: 16),
        const ConfirmPasswordInputField(),
        const SizedBox(height: 24),

        // Submit button
        BlocBuilder<PasswordCubit, PasswordState>(
          buildWhen: (previous, current) =>
              previous.isSubmitting != current.isSubmitting ||
              previous.isPasswordValid != current.isPasswordValid ||
              previous.doPasswordsMatch != current.doPasswordsMatch,
          builder: (context, state) {
            final bool isEnabled = state.isPasswordValid &&
                state.doPasswordsMatch &&
                !state.isSubmitting;

            return SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isEnabled
                    ? () => context.read<PasswordCubit>().submitPassword()
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF40C4AC),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      const Color(0xFF40C4AC).withOpacity(0.6),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: state.isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Submit',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
              ),
            );
          },
        ),
      ],
    );
  }
}

// PASSWORD FIELD
class PasswordInputField extends StatelessWidget {
  const PasswordInputField({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PasswordCubit, PasswordState>(
      buildWhen: (previous, current) =>
          previous.isPasswordVisible != current.isPasswordVisible ||
          previous.isPasswordValid != current.isPasswordValid,
      builder: (context, state) {
        return TextField(
          obscureText: !state.isPasswordVisible,
          decoration: InputDecoration(
            hintText: 'Password',
            prefixIcon: const Icon(
              Icons.lock_outlined,
              color: Colors.black54,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                state.isPasswordVisible
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: Colors.black54,
              ),
              onPressed: () =>
                  context.read<PasswordCubit>().togglePasswordVisibility(),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(28),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(28),
              borderSide: const BorderSide(color: Colors.black12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(28),
              borderSide: const BorderSide(color: Color(0xFF40C4AC)),
            ),
          ),
          onChanged: (value) =>
              context.read<PasswordCubit>().updatePassword(value),
        );
      },
    );
  }
}

// CONFIRM PASSWORD FIELD
class ConfirmPasswordInputField extends StatelessWidget {
  const ConfirmPasswordInputField({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PasswordCubit, PasswordState>(
      buildWhen: (previous, current) =>
          previous.isConfirmPasswordVisible !=
              current.isConfirmPasswordVisible ||
          previous.doPasswordsMatch != current.doPasswordsMatch,
      builder: (context, state) {
        return TextField(
          obscureText: !state.isConfirmPasswordVisible,
          decoration: InputDecoration(
            hintText: 'Confirm Password',
            prefixIcon: const Icon(
              Icons.lock_outlined,
              color: Colors.black54,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                state.isConfirmPasswordVisible
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: Colors.black54,
              ),
              onPressed: () => context
                  .read<PasswordCubit>()
                  .toggleConfirmPasswordVisibility(),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(28),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(28),
              borderSide: const BorderSide(color: Colors.black12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(28),
              borderSide: const BorderSide(color: Color(0xFF40C4AC)),
            ),
          ),
          onChanged: (value) =>
              context.read<PasswordCubit>().updateConfirmPassword(value),
        );
      },
    );
  }
}

