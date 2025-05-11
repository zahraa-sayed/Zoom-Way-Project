

// Enhanced VehicleDetailsCubit with error handling
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zoom_way/screens/driver/document_upload_screen.dart';
import 'package:zoom_way/utils/validation_error_snackbar.dart';

class VehicleDetailsCubit extends Cubit<VehicleDetailsState> {
  VehicleDetailsCubit()
      : super(VehicleDetailsState(
          carModel: '',
          licensePlate: '',
          carColor: '',
          manufacturingYear: '',
          licenseNumber: '',
          drivingExperience: '',
          address: '',
          phoneNumber: '',
          isFormValid: false,
          fieldErrors: {},
        ));

  void updateField(String field, String value) {
    // Create a copy of the current state
    final Map<String, dynamic> updatedState = {
      'carModel': state.carModel,
      'licensePlate': state.licensePlate,
      'carColor': state.carColor,
      'manufacturingYear': state.manufacturingYear,
      'licenseNumber': state.licenseNumber,
      'drivingExperience': state.drivingExperience,
      'address': state.address,
      'phoneNumber': state.phoneNumber,
    };

    // Update the specific field
    updatedState[field] = value;

    // Validate the specific field and create field errors map
    final Map<String, String?> fieldErrors = Map.from(state.fieldErrors);
    fieldErrors[field] = validateField(field, value);

    // Check if all required fields are filled and valid
    final bool isValid = updatedState.values.every((val) => val.isNotEmpty) &&
        fieldErrors.values.every((error) => error == null);

    // Emit the new state
    emit(VehicleDetailsState(
      carModel: updatedState['carModel'],
      licensePlate: updatedState['licensePlate'],
      carColor: updatedState['carColor'],
      manufacturingYear: updatedState['manufacturingYear'],
      licenseNumber: updatedState['licenseNumber'],
      drivingExperience: updatedState['drivingExperience'],
      address: updatedState['address'],
      phoneNumber: updatedState['phoneNumber'],
      isFormValid: isValid,
      fieldErrors: fieldErrors,
    ));
  }

  // Field-specific validation
  String? validateField(String field, String value) {
    if (value.isEmpty) {
      return 'This field is required';
    }

    switch (field) {
      case 'manufacturingYear':
        final yearPattern = RegExp(r'^\d{4}$');
        if (!yearPattern.hasMatch(value)) {
          return 'Enter a valid 4-digit year';
        }
        final year = int.tryParse(value);
        if (year == null || year < 1900 || year > DateTime.now().year) {
          return 'Enter a valid year between 1900 and ${DateTime.now().year}';
        }
        break;

      case 'phoneNumber':
        final phonePattern = RegExp(r'^\d{10,15}$');
        if (!phonePattern.hasMatch(value)) {
          return 'Enter a valid phone number';
        }
        break;

      case 'drivingExperience':
        final experienceValue = int.tryParse(value);
        if (experienceValue == null ||
            experienceValue < 0 ||
            experienceValue > 70) {
          return 'Enter a valid number of years';
        }
        break;
    }

    return null;
  }

  // Validate all fields at once (for form submission)
  Map<String, String?> validateAllFields() {
    final Map<String, String?> errors = {};

    errors['carModel'] = validateField('carModel', state.carModel);
    errors['licensePlate'] = validateField('licensePlate', state.licensePlate);
    errors['carColor'] = validateField('carColor', state.carColor);
    errors['manufacturingYear'] =
        validateField('manufacturingYear', state.manufacturingYear);
    errors['licenseNumber'] =
        validateField('licenseNumber', state.licenseNumber);
    errors['drivingExperience'] =
        validateField('drivingExperience', state.drivingExperience);
    errors['address'] = validateField('address', state.address);
    errors['phoneNumber'] = validateField('phoneNumber', state.phoneNumber);

    // Update state with all validation errors
    emit(VehicleDetailsState(
      carModel: state.carModel,
      licensePlate: state.licensePlate,
      carColor: state.carColor,
      manufacturingYear: state.manufacturingYear,
      licenseNumber: state.licenseNumber,
      drivingExperience: state.drivingExperience,
      address: state.address,
      phoneNumber: state.phoneNumber,
      isFormValid: errors.values.every((error) => error == null),
      fieldErrors: errors,
    ));

    return errors;
  }

  // Prepare data for the next screen
  Map<String, String> getFormData() {
    return {
      'car_model': state.carModel,
      'license_plate': state.licensePlate,
      'car_color': state.carColor,
      'manufacturing_year': state.manufacturingYear,
      'license_number': state.licenseNumber,
      'driving_experience': state.drivingExperience,
      'address': state.address,
      'phone_number': state.phoneNumber,
    };
  }
}

// Updated VehicleDetailsState to include field errors
class VehicleDetailsState {
  final String carModel;
  final String licensePlate;
  final String carColor;
  final String manufacturingYear;
  final String licenseNumber;
  final String drivingExperience;
  final String address;
  final String phoneNumber;
  final bool isFormValid;
  final Map<String, String?> fieldErrors;

  VehicleDetailsState({
    required this.carModel,
    required this.licensePlate,
    required this.carColor,
    required this.manufacturingYear,
    required this.licenseNumber,
    required this.drivingExperience,
    required this.address,
    required this.phoneNumber,
    required this.isFormValid,
    this.fieldErrors = const {},
  });
}
class VehicleInfoScreen extends StatelessWidget {
  final Map<String, String> previousFormData;

  const VehicleInfoScreen({
    super.key,
    required this.previousFormData,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => VehicleDetailsCubit(),
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text('Vehicle Details',
              style: TextStyle(color: Colors.black)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SafeArea(
          child: VehicleInfoView(previousFormData: previousFormData),
        ),
      ),
    );
  }
}

class VehicleInfoView extends StatelessWidget {
  final Map<String, String> previousFormData;

  const VehicleInfoView({super.key, required this.previousFormData});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFormField(
                    context,
                    label: 'Car Model',
                    field: 'carModel',
                    hint: 'Enter your car model (e.g., Toyota Camry)',
                  ),
                  const SizedBox(height: 16),
                  _buildFormField(
                    context,
                    label: 'License Plate',
                    field: 'licensePlate',
                    hint: 'Enter your license plate number',
                  ),
                  const SizedBox(height: 16),
                  _buildFormField(
                    context,
                    label: 'Car Color',
                    field: 'carColor',
                    hint: 'Enter your car color',
                  ),
                  const SizedBox(height: 16),
                  _buildFormField(
                    context,
                    label: 'Manufacturing Year',
                    field: 'manufacturingYear',
                    hint: 'Enter manufacturing year',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  _buildFormField(
                    context,
                    label: 'License Number',
                    field: 'licenseNumber',
                    hint: 'Enter your license number',
                  ),
                  const SizedBox(height: 16),
                  _buildFormField(
                    context,
                    label: 'Driving Experience (Years)',
                    field: 'drivingExperience',
                    hint: 'Enter years of driving experience',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  _buildFormField(
                    context,
                    label: 'Address',
                    field: 'address',
                    hint: 'Enter your full address',
                  ),
                  const SizedBox(height: 16),
                  _buildFormField(
                    context,
                    label: 'Phone Number',
                    field: 'phoneNumber',
                    hint: 'Enter your phone number',
                    keyboardType: TextInputType.phone,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
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
          // Update the Next button in your VehicleInfoView class
          BlocBuilder<VehicleDetailsCubit, VehicleDetailsState>(
            builder: (context, state) {
              return SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Validate all fields before proceeding
                    final errors =
                        context.read<VehicleDetailsCubit>().validateAllFields();

                    // Show errors if any
                    if (!state.isFormValid) {
                      ValidationErrorSnackbar.showMultipleErrors(context,
                          errors: errors);
                      return;
                    }

                    // Get vehicle data
                    final vehicleData =
                        context.read<VehicleDetailsCubit>().getFormData();

                    // Combine with previous form data to build complete registration data
                    final completeFormData = {
                      ...previousFormData,
                      ...vehicleData,
                    };

                    // Navigate to document upload
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DocumentUploadScreen(
                          formData: completeFormData,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3EB8A5),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Next',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              );
            },
          ),        ],
      ),
    );
  }
Widget _buildFormField(
    BuildContext context, {
    required String label,
    required String field,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return BlocBuilder<VehicleDetailsCubit, VehicleDetailsState>(
      builder: (context, state) {
        final errorText = state.fieldErrors[field];

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextFormField(
            onChanged: (value) {
              context.read<VehicleDetailsCubit>().updateField(field, value);
            },
            keyboardType: keyboardType,
            style: const TextStyle(fontSize: 16),
            decoration: InputDecoration(
              labelText: label,
              hintText: hint,
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
                borderSide: BorderSide(
                    color: errorText != null ? Colors.red : Colors.transparent),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                    color: errorText != null ? Colors.red : Colors.transparent),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                    color: errorText != null ? Colors.red : Colors.teal),
              ),
              filled: true,
              fillColor: Colors.white,
              errorText: errorText,
              errorStyle: const TextStyle(fontSize: 12),
            ),
          ),
        );
      },
    );
  }
}
