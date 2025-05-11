import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:zoom_way/data/api/driver_api_services.dart';
import 'package:zoom_way/logic/cubit/driver_state.dart';


// Cubit for document verification
class DocumentVerificationCubit extends Cubit<DocumentVerificationState> {
  final DriverApiService _apiService = DriverApiService();
  final Map<String, dynamic> registrationData;
  final Map<int, File?> previousDocuments;
  Map<int, File?> additionalDocuments = {};

  DocumentVerificationCubit({
    required this.registrationData,
    required this.previousDocuments,
  }) : super(const DocumentVerificationInitial(0));

 Future<void> uploadDocument(int documentType) async {
    emit(DocumentVerificationUploading(state.uploadedCount));

    final ImagePicker picker = ImagePicker();

    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (image != null) {
        final File file = File(image.path);

        // Check file size (limit to 5MB)
        final fileSize = await file.length();
        if (fileSize > 5 * 1024 * 1024) {
          emit(DocumentVerificationError(
              "File is too large. Maximum size is 5MB.", state.uploadedCount));
          return;
        }

        // Check file type (only images are allowed)
        final String? mimeType = lookupMimeType(image.path);
        if (mimeType == null || !mimeType.startsWith('image/')) {
          emit(DocumentVerificationError(
              "Only image files are allowed.", state.uploadedCount));
          return;
        }

        additionalDocuments[documentType] = file;

        final newUploadedCount = state.uploadedCount + 1;
        emit(DocumentVerificationInitial(newUploadedCount));
      } else {
        // User canceled the picker
        emit(DocumentVerificationInitial(state.uploadedCount));
      }
    } catch (e) {
      emit(DocumentVerificationError(
          "Error selecting document: ${e.toString()}", state.uploadedCount));
    }
  }
  Future<Map<String, dynamic>> proceedToNextStep() async {
    if (state.uploadedCount < 3) {
      emit(DocumentVerificationError(
          "Please upload all required documents", state.uploadedCount));
      return {'success': false};
    }

    emit(const DocumentVerificationUploading(3));

    try {
      // Combine all documents for the API call
      final allDocuments = {...previousDocuments, ...additionalDocuments};

      // Use the registration data passed in through the constructor
      // instead of hardcoding values

      // Call the API registration method
      final result = await _apiService.registerDriver(
        name:
            "${registrationData['first_name']} ${registrationData['last_name']}",
        email: registrationData['email'],
        phoneNumber: registrationData['phone_number'] ?? '',
        carModel: registrationData['car_model'] ?? '',
        password: registrationData['password'],
        passwordConfirmation: registrationData['password_confirmation'],
        address: registrationData['address'] ?? '',
        licenseNumber: registrationData['license_number'] ?? '',
        drivingExperience: registrationData['driving_experience'] ?? '',
        licensePlate: registrationData['license_plate'] ?? '',
        carColor: registrationData['car_color'] ?? '',
        manufacturingYear: registrationData['manufacturing_year'] ?? '',
        // Map document files to the appropriate parameters
        idCardFront: allDocuments[0] ?? File(''),
        idCardBack: allDocuments[1] ?? File(''),
        licenseFront: allDocuments[2] ?? File(''),
        licenseBack: previousDocuments[0] ?? File(''),
        drivingLicenseFront: previousDocuments[1] ?? File(''),
        drivingLicenseBack: previousDocuments[2] ?? File(''),
      );

      if (result['success']) {
        emit(const DocumentVerificationComplete(3));
        return {'success': true, 'data': result['data']};
      } else {
        emit(DocumentVerificationError(
            result['message'] ?? "Registration failed", state.uploadedCount));
        return {'success': false, 'message': result['message']};
      }
    } catch (e) {
      emit(DocumentVerificationError(
          "Registration error: ${e.toString()}", state.uploadedCount));
      return {'success': false, 'message': e.toString()};
    }
  }
}
