import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:zoom_way/models/document_item.dart';

// Define DocumentUploadState if not already defined
class DocumentUploadState {
  final List<DocumentItem> documents;
  final int completedDocuments;
  final int totalDocuments;
  final String? errorMessage;
  final bool isLoading;

  DocumentUploadState({
    required this.documents,
    required this.completedDocuments,
    required this.totalDocuments,
    this.errorMessage,
    this.isLoading = false,
  });

  // Create a copy with updated values
  DocumentUploadState copyWith({
    List<DocumentItem>? documents,
    int? completedDocuments,
    int? totalDocuments,
    String? errorMessage,
    bool? isLoading,
  }) {
    return DocumentUploadState(
      documents: documents ?? this.documents,
      completedDocuments: completedDocuments ?? this.completedDocuments,
      totalDocuments: totalDocuments ?? this.totalDocuments,
      errorMessage: errorMessage, // Pass null to clear error
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class DocumentUploadCubit extends Cubit<DocumentUploadState> {
  Map<String, String> registrationData = {};
  Map<int, File?> documentFiles = {};

  DocumentUploadCubit()
      : super(DocumentUploadState(
          documents: [
            DocumentItem(title: 'Driver\'s License Front'),
            DocumentItem(title: 'Driver\'s License Back'),
            DocumentItem(title: 'Vehicle Registration'),
          ],
          completedDocuments: 0,
          totalDocuments: 3,
        ));

  // Set registration data from previous screen
  void setRegistrationData(Map<String, String> data) {
    try {
      registrationData = Map<String, String>.from(data);
    } catch (e) {
      emit(state.copyWith(
        errorMessage: 'Error loading registration data: ${e.toString()}',
      ));
    }
  }

  // Pick a document from gallery and upload it
 // Enhanced document upload error handling in DocumentUploadCubit
  // Enhanced pickAndUploadDocument method
  Future<void> pickAndUploadDocument(int index) async {
    emit(state.copyWith(
      isLoading: true,
      errorMessage: null,
    ));

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (image == null) {
        // User canceled the picker
        emit(state.copyWith(
          isLoading: false,
        ));
        return;
      }

      // Check file size (limit to 5MB for example)
      final File file = File(image.path);
      final fileSize = await file.length();
      if (fileSize > 5 * 1024 * 1024) {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: 'File is too large. Maximum size is 5MB.',
        ));
        return;
      }

      // Check file type (only images are allowed)
      final String? mimeType = lookupMimeType(image.path);
      if (mimeType == null || !mimeType.startsWith('image/')) {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: 'Only image files are allowed.',
        ));
        return;
      }

      // Store file reference in documentFiles map
      documentFiles[index] = file;

      // Process uploaded file and update document status
      final updatedDocuments = List<DocumentItem>.from(state.documents);
      updatedDocuments[index] = updatedDocuments[index].copyWith(
        isUploaded: true,
        filePath: image.path,
      );

      emit(state.copyWith(
        documents: updatedDocuments,
        isLoading: false,
        completedDocuments: state.completedDocuments + 1,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to upload document: ${e.toString()}',
      ));
    }
  }  // Proceed to next screen
  Future<Map<String, dynamic>> proceedToNextScreen() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      // Validate all documents are uploaded
      if (documentFiles.length < state.totalDocuments) {
        emit(state.copyWith(
          errorMessage: 'Please upload all required documents.',
          isLoading: false,
        ));

        return {
          'success': false,
          'message': 'Please upload all required documents.',
        };
      }

      // Validate each file exists and is accessible
      for (var entry in documentFiles.entries) {
        final file = entry.value;
        if (file == null || !await file.exists()) {
          emit(state.copyWith(
            errorMessage:
                'Document ${entry.key + 1} is missing or inaccessible.',
            isLoading: false,
          ));

          return {
            'success': false,
            'message': 'Document ${entry.key + 1} is missing or inaccessible.',
          };
        }
      }

      // Validate registration data contains required fields
      if (!_validateRegistrationData()) {
        emit(state.copyWith(
          errorMessage:
              'Registration data is incomplete. Please go back and fill all required fields.',
          isLoading: false,
        ));

        return {
          'success': false,
          'message': 'Registration data is incomplete.',
        };
      }

      // All documents uploaded, proceed to next screen
      emit(state.copyWith(isLoading: false));

      return {
        'success': true,
        'registrationData': registrationData,
        'documentFiles': documentFiles,
      };
    } catch (e) {
      emit(state.copyWith(
        errorMessage: 'Unexpected error: ${e.toString()}',
        isLoading: false,
      ));

      return {
        'success': false,
        'message': 'Unexpected error: ${e.toString()}',
      };
    }
  }

  // Validate the registration data has all required fields
  bool _validateRegistrationData() {
    final requiredFields = [
      'email',
      'password',
      'password_confirmation',
      // Add other required fields as needed
    ];

    for (var field in requiredFields) {
      if (!registrationData.containsKey(field) ||
          registrationData[field] == null ||
          registrationData[field]!.isEmpty) {
        return false;
      }
    }

    return true;
  }
}
