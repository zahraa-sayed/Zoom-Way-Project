import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Cubit for managing new password creation
class NewPasswordCubit extends Cubit<NewPasswordState> {
  NewPasswordCubit() : super(NewPasswordInitial());

  void resetPassword({
    required String password,
    required String confirmPassword,
  }) {
    // Input validation
    if (password.isEmpty || confirmPassword.isEmpty) {
      emit(NewPasswordError('Please fill in both password fields'));
      return;
    }

    if (password.length < 8) {
      emit(NewPasswordError('Password must be at least 8 characters'));
      return;
    }

    if (password != confirmPassword) {
      emit(NewPasswordError('Passwords do not match'));
      return;
    }

    // Start loading
    emit(NewPasswordLoading());

    // Simulate API call to reset password
    Future.delayed(const Duration(seconds: 2), () {
      // Success case
      emit(NewPasswordSuccess('Password reset successfully'));

      // In real app, you would handle errors:
      // emit(NewPasswordError('Failed to reset password'));
    });
  }
}

// States
abstract class NewPasswordState {}

class NewPasswordInitial extends NewPasswordState {}

class NewPasswordLoading extends NewPasswordState {}

class NewPasswordSuccess extends NewPasswordState {
  final String message;
  NewPasswordSuccess(this.message);
}

class NewPasswordError extends NewPasswordState {
  final String error;
  NewPasswordError(this.error);
}

class NewPasswordScreen extends StatelessWidget {
  const NewPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => NewPasswordCubit(),
      child: const NewPasswordView(),
    );
  }
}

class NewPasswordView extends StatefulWidget {
  const NewPasswordView({super.key});

  @override
  State<NewPasswordView> createState() => _NewPasswordViewState();
}

class _NewPasswordViewState extends State<NewPasswordView> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button
              _buildBackButton(context),

              const SizedBox(height: 16),

              // Title
              const Text(
                'Enter new password',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF0F2B3F),
                ),
              ),

              const SizedBox(height: 24),

              // Password field
              _buildPasswordField(),

              const SizedBox(height: 16),

              // Confirm password field
              _buildConfirmPasswordField(),

              const SizedBox(height: 24),

              // Submit button
              _buildSubmitButton(),

              // Status message
              _buildStatusMessage(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: const Icon(
        Icons.arrow_back,
        color: Colors.black54,
        size: 24,
      ),
    );
  }

  Widget _buildPasswordField() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        controller: _passwordController,
        obscureText: _obscurePassword,
        decoration: InputDecoration(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          hintText: 'Password',
          hintStyle: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 14,
          ),
          border: InputBorder.none,
          prefixIcon: Icon(
            Icons.lock_outline,
            color: Colors.grey.shade600,
            size: 20,
          ),
          suffixIcon: GestureDetector(
            onTap: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
            child: Icon(
              _obscurePassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: Colors.grey.shade600,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmPasswordField() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        controller: _confirmPasswordController,
        obscureText: _obscureConfirmPassword,
        decoration: InputDecoration(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          hintText: 'Confirm Password',
          hintStyle: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 14,
          ),
          border: InputBorder.none,
          prefixIcon: Icon(
            Icons.lock_outline,
            color: Colors.grey.shade600,
            size: 20,
          ),
          suffixIcon: GestureDetector(
            onTap: () {
              setState(() {
                _obscureConfirmPassword = !_obscureConfirmPassword;
              });
            },
            child: Icon(
              _obscureConfirmPassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: Colors.grey.shade600,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return BlocBuilder<NewPasswordCubit, NewPasswordState>(
      buildWhen: (previous, current) =>
          current is NewPasswordLoading || previous is NewPasswordLoading,
      builder: (context, state) {
        final isLoading = state is NewPasswordLoading;

        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isLoading
                ? null
                : () {
                    final cubit = context.read<NewPasswordCubit>();
                    cubit.resetPassword(
                      password: _passwordController.text,
                      confirmPassword: _confirmPasswordController.text,
                    );
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF40C4AA),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 0,
              disabledBackgroundColor: const Color(0xFF40C4AA).withOpacity(0.6),
            ),
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Submit',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildStatusMessage() {
    return BlocBuilder<NewPasswordCubit, NewPasswordState>(
      buildWhen: (previous, current) =>
          current is NewPasswordSuccess || current is NewPasswordError,
      builder: (context, state) {
        if (state is NewPasswordSuccess) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              state.message,
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          );
        } else if (state is NewPasswordError) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              state.error,
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
