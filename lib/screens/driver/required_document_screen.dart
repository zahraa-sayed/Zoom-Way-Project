import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zoom_way/logic/cubit/driver_cubit.dart';
import 'package:zoom_way/logic/cubit/driver_state.dart';
import 'package:zoom_way/screens/driver/registration_pending_screen.dart';


class RequiredDocumentsScreen extends StatelessWidget {
  final Map<String, dynamic> registrationData;
  final Map<int, File?> documentFiles;

  const RequiredDocumentsScreen({
    super.key,
    required this.registrationData,
    required this.documentFiles,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DocumentVerificationCubit(
        registrationData: registrationData,
        previousDocuments: documentFiles,
      ),
      child: const RequiredDocumentsView(),
    );
  }
}

class RequiredDocumentsView extends StatelessWidget {
  const RequiredDocumentsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 20),
              _buildDocumentsList(context),
              const Spacer(),
              _buildDriverCenterInfo(),
              const SizedBox(height: 12),
              _buildNextButton(context),
              _buildErrorMessage(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        const Text(
          'Required Documents',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F2B3F),
          ),
        ),
        const Spacer(),
        BlocBuilder<DocumentVerificationCubit, DocumentVerificationState>(
          builder: (context, state) {
            return RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: "${state.uploadedCount}",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color:
                          state.uploadedCount > 0 ? Colors.green : Colors.red,
                    ),
                  ),
                  TextSpan(
                    text: "/3",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDocumentsList(BuildContext context) {
    final documents = [
      {'id': 0, 'title': 'ID card front view'},
      {'id': 1, 'title': 'ID card back view'},
      {'id': 2, 'title': 'Personal photo'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: documents.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          color: Colors.grey.shade300,
        ),
        itemBuilder: (context, index) {
          final document = documents[index];
          return _buildDocumentItem(
              context, document['id'] as int, document['title'] as String);
        },
      ),
    );
  }

  Widget _buildDocumentItem(BuildContext context, int id, String title) {
    return BlocBuilder<DocumentVerificationCubit, DocumentVerificationState>(
      buildWhen: (previous, current) {
        // Rebuild when uploading state changes or upload count changes
        return previous.uploadedCount != current.uploadedCount ||
            previous.runtimeType != current.runtimeType;
      },
      builder: (context, state) {
        final bool isUploading = state is DocumentVerificationUploading;

        // Check if this document is uploaded based on ID
        final bool isUploaded = state.uploadedCount > id;

        // Get file reference from the cubit
        File? documentFile;
        if (isUploaded) {
          final cubit = context.read<DocumentVerificationCubit>();
          documentFile =
              cubit.additionalDocuments[id] ?? cubit.previousDocuments[id];
        }

        return ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isUploaded ? Colors.green : Colors.grey.shade300,
                width: isUploaded ? 2 : 1,
              ),
            ),
            child: isUploaded && documentFile != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: Image.file(
                      documentFile,
                      fit: BoxFit.cover,
                    ),
                  )
                : Image.asset('assets/images/required_document_icon.png'),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade800,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: isUploaded
              ? const Text(
                  'Uploaded',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                  ),
                )
              : const Text(
                  'Required',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                  ),
                ),
          trailing: isUploaded
              ? const Icon(Icons.check_circle, color: Colors.green)
              : const Icon(Icons.upload_file, color: Colors.grey),
          onTap: isUploading
              ? null
              : () {
                  context.read<DocumentVerificationCubit>().uploadDocument(id);
                },
        );
      },
    );
  }

  Widget _buildDriverCenterInfo() {
    return Center(
      child: TextButton(
        onPressed: () {
          // Handle driver center info tap
        },
        child: const Text(
          'Driver Center Information',
          style: TextStyle(
            fontSize: 14,
            color: Colors.redAccent,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // Update the _buildNextButton method in RequiredDocumentsView class
  Widget _buildNextButton(BuildContext context) {
    return BlocBuilder<DocumentVerificationCubit, DocumentVerificationState>(
      buildWhen: (previous, current) =>
          current is DocumentVerificationUploading ||
          previous is DocumentVerificationUploading ||
          previous.uploadedCount != current.uploadedCount ||
          current is DocumentVerificationError,
      builder: (context, state) {
        final isUploading = state is DocumentVerificationUploading;
        final bool isComplete = state.uploadedCount >= 3;

        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: (isUploading || !isComplete)
                ? null
                : () async {
                    final result = await context
                        .read<DocumentVerificationCubit>()
                        .proceedToNextStep();

                    if (result['success']) {
                      // Only navigate on success
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text("Registration successful!")),
                      );

                      // Navigate to the pending screen instead of map screen
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const RegistrationPendingScreen()),
                        (route) => false, // This removes all previous routes
                      );
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3EB8A5),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              disabledBackgroundColor: Colors.grey.shade300,
            ),
            child: isUploading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Submit Registration',
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

  Widget _buildErrorMessage(BuildContext context) {
    return BlocBuilder<DocumentVerificationCubit, DocumentVerificationState>(
      buildWhen: (previous, current) =>
          current is DocumentVerificationError ||
          previous is DocumentVerificationError,
      builder: (context, state) {
        if (state is DocumentVerificationError) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: Text(
                state.message,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 14,
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
