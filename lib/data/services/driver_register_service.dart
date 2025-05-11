import 'dart:io';

import 'package:zoom_way/data/api/driver_api_services.dart';

class DriverRegistrationService {
  final DriverApiService _apiService = DriverApiService();

  // Method to register driver with all collected information
  Future<Map<String, dynamic>> registerDriver({
    required Map<String, dynamic> userData,
    required Map<int, File?> documentFiles,
  }) async {
    try {
      // Validate user data
      if (!_validateUserData(userData)) {
        return {
          'success': false,
          'message': 'Required user data is missing or invalid',
        };
      }

      // Validate document files
      final missingDocuments = _validateDocumentFiles(documentFiles);
      if (missingDocuments.isNotEmpty) {
        return {
          'success': false,
          'message':
              'Missing required document${missingDocuments.length > 1 ? 's' : ''}: ${missingDocuments.join(', ')}',
        };
      }

      // Extract user data from the collected information
      final String fullName =
          "${userData['first_name']} ${userData['last_name']}";

      // Create a complete registration request
      final result = await _apiService.registerDriver(
        name: fullName,
        email: userData['email'] ?? '',
        phoneNumber: userData['phone_number'] ?? '',
        carModel: userData['car_model'] ?? '',
        password: userData['password'] ?? '',
        passwordConfirmation: userData['password_confirmation'] ?? '',
        address: userData['address'] ?? '',
        licenseNumber: userData['license_number'] ?? '',
        drivingExperience: userData['driving_experience'] ?? '',
        licensePlate: userData['license_plate'] ?? '',
        carColor: userData['car_color'] ?? '',
        manufacturingYear: userData['manufacturing_year'] ?? '',
        // Map document files to the appropriate parameters
        idCardFront: documentFiles[0] ?? File(''),
        idCardBack: documentFiles[1] ?? File(''),
        licenseFront: documentFiles[3] ?? File(''),
        licenseBack: documentFiles[4] ?? File(''),
        drivingLicenseFront: documentFiles[5] ?? File(''),
        drivingLicenseBack: documentFiles[6] ?? File(''),
      );

      return result;
    } catch (e) {
      return {
        'success': false,
        'message': 'Registration error: ${e.toString()}',
      };
    }
  }

  // Validate user data for required fields
  bool _validateUserData(Map<String, dynamic> userData) {
    final requiredFields = [
      'first_name',
      'last_name',
      'email',
      'password',
      'password_confirmation',
    ];

    // Check for missing required fields
    for (var field in requiredFields) {
      if (!userData.containsKey(field) ||
          userData[field] == null ||
          userData[field].toString().isEmpty) {
        return false;
      }
    }

    // Validate password matches confirmation
    if (userData['password'] != userData['password_confirmation']) {
      return false;
    }

    // Additional validation could be added here

    return true;
  }

  // Validate document files and return a list of missing documents
  List<String> _validateDocumentFiles(Map<int, File?> documentFiles) {
    final List<String> missingDocuments = [];
    final Map<int, String> requiredDocuments = {
      0: 'ID Card Front',
      1: 'ID Card Back',
      3: 'License Front',
      4: 'License Back',
      5: 'Driving License Front',
      6: 'Driving License Back',
    };

    requiredDocuments.forEach((index, name) {
      if (!documentFiles.containsKey(index) ||
          documentFiles[index] == null ||
          !documentFiles[index]!.existsSync()) {
        missingDocuments.add(name);
      }
    });

    return missingDocuments;
  }
}
