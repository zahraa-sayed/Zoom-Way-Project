import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Verification Code Cubit
class VerificationCodeCubit extends Cubit<VerificationCodeState> {
  VerificationCodeCubit() : super(VerificationCodeInitial());

  void verifyCode(String code) {
    emit(VerificationCodeLoading());

    Future.delayed(const Duration(seconds: 2), () {
      if (code.length == 6) {
        emit(VerificationCodeSuccess());
      } else {
        emit(VerificationCodeError("Invalid verification code"));
      }
    });
  }

  void resendCode() {
    emit(VerificationCodeResending());

    // Simulate resending code
    Future.delayed(const Duration(seconds: 1), () {
      emit(VerificationCodeResent("New code sent successfully"));

      // Return to initial state after showing success message
      Future.delayed(const Duration(seconds: 2), () {
        emit(VerificationCodeInitial());
      });
    });
  }
}

// States
abstract class VerificationCodeState {}

class VerificationCodeInitial extends VerificationCodeState {}

class VerificationCodeLoading extends VerificationCodeState {}

class VerificationCodeSuccess extends VerificationCodeState {}

class VerificationCodeError extends VerificationCodeState {
  final String message;
  VerificationCodeError(this.message);
}

class VerificationCodeResending extends VerificationCodeState {}

class VerificationCodeResent extends VerificationCodeState {
  final String message;
  VerificationCodeResent(this.message);
}

class VerificationCodeScreen extends StatelessWidget {
  final String? email;

  const VerificationCodeScreen({
    super.key,
    this.email, required String name, required String phone, required String address, required String password, required String passwordConfirmation, required String userType,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => VerificationCodeCubit(),
      child: VerificationCodeView(email: email ?? ''),
    );
  }
}

class VerificationCodeView extends StatefulWidget {
  final String email;

  const VerificationCodeView({
    super.key,
    required this.email,
  });

  @override
  State<VerificationCodeView> createState() => _VerificationCodeViewState();
}

class _VerificationCodeViewState extends State<VerificationCodeView> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());

  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  // Get the full verification code from all fields
  String get _completeCode {
    return _controllers.map((controller) => controller.text).join();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button
              _buildBackButton(context),

              const SizedBox(height: 24),

              // Header section
              _buildHeader(),

              const SizedBox(height: 32),

              // OTP input fields
              _buildVerificationCodeFields(),

              const SizedBox(height: 16),

              // Resend OTP button
              _buildResendButton(),

              const SizedBox(height: 24),

              // Confirm button
              _buildConfirmButton(context),

              // Status message
              _buildStatusMessage(),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.arrow_back_ios,
          size: 16,
          color: Colors.black54,
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Center(
          child: Text(
            'Forget Password',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F2B3F),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Code has been send to ${_maskEmail(widget.email)}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  String _maskEmail(String email) {
    if (email.isEmpty) return "******@gmail.com";

    final parts = email.split('@');
    if (parts.length != 2) return email;

    final username = parts[0];
    final domain = parts[1];

    if (username.length <= 2) {
      return "$username@$domain";
    }

    final maskedUsername =
        username.substring(0, 2) + '*' * (username.length - 2);
    return "$maskedUsername@$domain";
  }

  Widget _buildVerificationCodeFields() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(
        6,
        (index) => _buildSingleDigitField(index),
      ),
    );
  }

  Widget _buildSingleDigitField(int index) {
    return SizedBox(
      width: 40,
      height: 48,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        decoration: InputDecoration(
          counterText: '',
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF40C4AA), width: 2),
          ),
        ),
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
        ],
        onChanged: (value) {
          if (value.isNotEmpty && index < 5) {
            // Move to next field
            _focusNodes[index + 1].requestFocus();
          } else if (value.isEmpty && index > 0) {
            // Move to previous field on backspace
            _focusNodes[index - 1].requestFocus();
          }

          // If all fields are filled, can attempt verification automatically
          if (_completeCode.length == 6) {
            // Optional: Auto-verify when all digits entered
            // context.read<VerificationCodeCubit>().verifyCode(_completeCode);
          }
        },
      ),
    );
  }

  Widget _buildResendButton() {
    return Center(
      child: TextButton(
        onPressed: () {
          context.read<VerificationCodeCubit>().resendCode();
        },
        child: Text(
          'Request new otp',
          style: TextStyle(
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: BlocBuilder<VerificationCodeCubit, VerificationCodeState>(
        buildWhen: (previous, current) =>
            current is VerificationCodeLoading ||
            previous is VerificationCodeLoading,
        builder: (context, state) {
          final isLoading = state is VerificationCodeLoading;

          return ElevatedButton(
            onPressed: isLoading
                ? null
                : () {
                    context
                        .read<VerificationCodeCubit>()
                        .verifyCode(_completeCode);
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF40C4AA),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
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
                    'Confirm',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildStatusMessage() {
    return BlocBuilder<VerificationCodeCubit, VerificationCodeState>(
      buildWhen: (previous, current) =>
          current is VerificationCodeError || current is VerificationCodeResent,
      builder: (context, state) {
        if (state is VerificationCodeError) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Text(
                state.message,
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          );
        } else if (state is VerificationCodeResent) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Text(
                state.message,
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
