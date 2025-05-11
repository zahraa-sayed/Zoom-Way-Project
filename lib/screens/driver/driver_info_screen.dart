import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zoom_way/logic/cubit/driver_cubit/name_input_cubit.dart';
import 'package:zoom_way/screens/driver/vhicle_information_screen.dart';

class DriverInfoScreen extends StatelessWidget {
  final Map<String, String> registrationData;

  const DriverInfoScreen({
    super.key,
    required this.registrationData,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => NameInputCubit(registrationData: registrationData),
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        body: const SafeArea(
          child: NameInputView(),
        ),
      ),
    );
  }
}

class NameInputView extends StatelessWidget {
  const NameInputView({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          // First name input field
          const NameInputField(
            label: 'First Name (English)',
            initialValue: '',
            fieldType: NameFieldType.firstName,
          ),
          const SizedBox(height: 16),
          // Last name input field
          const NameInputField(
            label: 'Last Name (English)',
            initialValue: '',
            fieldType: NameFieldType.lastName,
          ),
          const Spacer(),
          // Driver Center Information text
          const Center(
            child: Text(
              'Driver Center Information',
              style: TextStyle(
                color: Colors.redAccent,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Next button
          BlocBuilder<NameInputCubit, NameInputState>(
            builder: (context, state) {
              return SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: state.isFormValid
                      ? () {
                          // Get data and navigate to the next screen (Vehicle Info)
                          final formData =
                              context.read<NameInputCubit>().getFormData();

                          // Navigate to the Vehicle Info screen with the collected data
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  VehicleInfoScreen(previousFormData: formData),
                            ),
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3EB8A5),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    disabledBackgroundColor: Colors.grey.shade300,
                  ),
                  child: const Text(
                    'Next',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// Enum for field type
enum NameFieldType { firstName, lastName }

// COMPONENTS
class NameInputField extends StatelessWidget {
  final String label;
  final String initialValue;
  final NameFieldType fieldType;

  const NameInputField({
    super.key,
    required this.label,
    required this.initialValue,
    required this.fieldType,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NameInputCubit, NameInputState>(
      builder: (context, state) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextFormField(
            initialValue: initialValue,
            onChanged: (value) {
              if (fieldType == NameFieldType.firstName) {
                context.read<NameInputCubit>().updateFirstName(value);
              } else {
                context.read<NameInputCubit>().updateLastName(value);
              }
            },
            style: const TextStyle(
              fontSize: 16,
            ),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        );
      },
    );
  }
}
