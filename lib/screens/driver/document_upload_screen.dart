import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../logic/cubit/driver_cubit/document_upload_cubit.dart';
import '../../models/document_item.dart';
import 'required_document_screen.dart';


class DocumentUploadScreen extends StatelessWidget {
  final Map<String, String> formData;

  const DocumentUploadScreen({
    super.key,
    required this.formData,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = DocumentUploadCubit();
        cubit.setRegistrationData(formData);
        return cubit;
      },
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        body: const SafeArea(
          child: DocumentUploadView(),
        ),
      ),
    );
  }
}

// MAIN VIEW
class DocumentUploadView extends StatelessWidget {
  const DocumentUploadView({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DocumentHeader(),
          const SizedBox(height: 16),
          BlocBuilder<DocumentUploadCubit, DocumentUploadState>(
            builder: (context, state) {
              return Expanded(
                child: Column(
                  children: [
                    // Document items list
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: state.documents.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) {
                          return DocumentListItem(
                            document: state.documents[index],
                            onTap: () {
                              context
                                  .read<DocumentUploadCubit>()
                                  .pickAndUploadDocument(index);
                            },
                          );
                        },
                      ),
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
                    // Sign Up button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final result = await context
                              .read<DocumentUploadCubit>()
                              .proceedToNextScreen();
                          if (result['success']) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RequiredDocumentsScreen(
                                  registrationData: result['registrationData'],
                                  documentFiles: result['documentFiles'],
                                ),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(result['message'])),
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
                        ),
                        child: const Text(
                          'Sign Up',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// COMPONENTS
class DocumentHeader extends StatelessWidget {
  const DocumentHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Required Documents',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        BlocBuilder<DocumentUploadCubit, DocumentUploadState>(
          builder: (context, state) {
            return Text(
              '${state.completedDocuments}/${state.totalDocuments}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            );
          },
        ),
      ],
    );
  }
}

class DocumentListItem extends StatelessWidget {
  final DocumentItem document;
  final VoidCallback onTap;

  const DocumentListItem({
    super.key,
    required this.document,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      title: Text(
        document.title,
        style: const TextStyle(
          fontSize: 16,
        ),
      ),
      leading: Container(
        width: 50,
        height: 50,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(4),
        ),
        child: document.isUploaded && document.filePath != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.file(
                  File(document.filePath!),
                  fit: BoxFit.cover,
                ),
              )
            : Image.asset('assets/images/required_document_icon.png'),
      ),
      trailing: document.isUploaded
          ? const Icon(Icons.check_circle, color: Colors.green)
          : const Icon(Icons.chevron_right, color: Colors.grey),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }
}
