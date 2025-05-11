import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zoom_way/data/api/passengers_api_service.dart';
import 'package:zoom_way/screens/users/map_screen.dart';

// CUBIT
class VerificationCubit extends Cubit<VerificationState> {
  final String name;
  final String email;
  final String phone;
  final String address;
  final String password;
  final String passwordConfirmation;
  final String userType;

  VerificationCubit({
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.password,
    required this.passwordConfirmation,
    required this.userType,
  }) : super(VerificationState());

  Future<void> confirmCode() async {
    emit(state.copyWith(isVerifying: true));

    try {
      final response = await ApiService.verifyOtp(
        otp: state.code,
        name: name,
        email: email,
        phoneNumber: phone,
        address: address,
        password: password,
        passwordConfirmation: passwordConfirmation,
        userType: userType,
      );

      emit(state.copyWith(isVerifying: false));

      if (response != null) {
        // Store the token from the response
        if (response['token'] != null) {
          await ApiService.setAuthToken(response['token']);
        }
        emit(state.copyWith(isSuccess: true));
      } else {
        emit(state.copyWith(errorMessage: 'Invalid OTP'));
      }
    } catch (e) {
      emit(state.copyWith(
        isVerifying: false,
        errorMessage: 'Verification failed: ${e.toString()}',
      ));
    }
  }

  void updateCode(String value) {
    emit(state.copyWith(code: value));
  }

  void requestNewOtp() {
    emit(state.copyWith(isRequesting: true));
    // Add actual API call logic here
    Future.delayed(const Duration(seconds: 1), () {
      emit(state.copyWith(isRequesting: false));
    });
  }
}

class VerificationState {
  final String code;
  final bool isRequesting;
  final bool isVerifying;
  final bool isSuccess;
  final String? errorMessage;

  VerificationState({
    this.code = '',
    this.isRequesting = false,
    this.isVerifying = false,
    this.isSuccess = false,
    this.errorMessage,
  });

  VerificationState copyWith({
    String? code,
    bool? isRequesting,
    bool? isVerifying,
    bool? isSuccess,
    String? errorMessage,
  }) {
    return VerificationState(
      code: code ?? this.code,
      isRequesting: isRequesting ?? this.isRequesting,
      isVerifying: isVerifying ?? this.isVerifying,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// MAIN SCREEN
class VerificationCodeScreen extends StatelessWidget {
  final String email;
  final String name;
  final String phone;
  final String address;
  final String password;
  final String passwordConfirmation;
  final String userType;

  const VerificationCodeScreen({
    super.key,
    required this.email,
    required this.name,
    required this.phone,
    required this.address,
    required this.password,
    required this.passwordConfirmation,
    required this.userType,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => VerificationCubit(
        name: name,
        email: email,
        phone: phone,
        address: address,
        password: password,
        passwordConfirmation: passwordConfirmation,
        userType: userType,
      ),
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: VerificationCodeView(email: email),
          ),
        ),
      ),
    );
  }
}

// VIEW
class VerificationCodeView extends StatelessWidget {
  final String email;

  const VerificationCodeView({
    super.key,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    return BlocListener<VerificationCubit, VerificationState>(
        listener: (context, state) {
          if (state.isSuccess) {
            // Navigate to map screen instead of login screen
            Navigator.push(context, MaterialPageRoute(builder: (context)=>const MapScreen()));
          }
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage!)),
            );
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back button
            BackButton(
              onPressed: () => Navigator.of(context).pop(),
            ),
            const SizedBox(height: 40),

            // Title and description
            const Center(
              child: Text(
                'Verification Code',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),

            Center(
              child: Text(
                'Code has been send to ${_maskEmail(email)}',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // OTP Input Section
            const OtpInputSection(),

            // Request new OTP button
            Center(
              child: BlocBuilder<VerificationCubit, VerificationState>(
                buildWhen: (previous, current) =>
                    previous.isRequesting != current.isRequesting,
                builder: (context, state) {
                  return TextButton(
                    onPressed: state.isRequesting
                        ? null
                        : () =>
                            context.read<VerificationCubit>().requestNewOtp(),
                    child: state.isRequesting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            'Request new otp',
                            style: TextStyle(
                              color: Colors.black87,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                  );
                },
              ),
            ),

            const Spacer(),

            // Confirm button
            BlocBuilder<VerificationCubit, VerificationState>(
              buildWhen: (previous, current) =>
                  previous.isVerifying != current.isVerifying,
              builder: (context, state) {
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: state.isVerifying
                        ? null
                        : () => context.read<VerificationCubit>().confirmCode(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF40C4AC),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: state.isVerifying
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Confirm',
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
        ));
  }

  String _maskEmail(String email) {
    if (email.isEmpty) return '';

    final parts = email.split('@');
    if (parts.length != 2) return email;

    final username = parts[0];
    final domain = parts[1];

    if (username.length <= 2) {
      return '****@$domain';
    }

    return '${username[0]}*****@$domain';
  }
}

// OTP INPUT COMPONENT
class OtpInputSection extends StatefulWidget {
  const OtpInputSection({super.key});

  @override
  State<OtpInputSection> createState() => _OtpInputSectionState();
}

class _OtpInputSectionState extends State<OtpInputSection> {
  // In _OtpInputSectionState
  final List<TextEditingController> _controllers = List.generate(
    6, // Changed from 5 to 6
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    6, // Changed from 5 to 6
    (_) => FocusNode(),
  );

  @override
  void initState() {
    super.initState();
    // Update focus listeners for 6 fields
    for (int i = 0; i < 5; i++) {
      // Changed from 4 to 5
      _controllers[i].addListener(() {
        if (_controllers[i].text.length == 1) {
          _focusNodes[i + 1].requestFocus();
        }
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        6,
        (index) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2.0),
          child: SizedBox(
            width: 50,
            height: 50,
            child: TextField(
              controller: _controllers[index],
              focusNode: _focusNodes[index],
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 1,
              decoration: InputDecoration(
                counterText: '',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                contentPadding: EdgeInsets.zero,
              ),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              onChanged: (value) {
                if (value.isEmpty && index > 0) {
                  _focusNodes[index - 1].requestFocus();
                }

                // Update the combined code in the cubit
                final code = _controllers.map((c) => c.text).join();
                context.read<VerificationCubit>().updateCode(code);
              },
            ),
          ),
        ),
      ),
    );
  }
}
