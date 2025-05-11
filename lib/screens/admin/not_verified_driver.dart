import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:zoom_way/data/api/admin_api_service.dart';
import 'package:zoom_way/logic/cubit/admin_cubit/driver_details_cubit.dart';

class NotVerifiedDriverProfileScreen extends StatelessWidget {
  const NotVerifiedDriverProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DriverDetailsCubit, DriverDetailsState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.error != null) {
          return Center(child: Text(state.error!));
        }

        final driver = state.driverData;

        // Update your existing widgets with actual data
        return Scaffold(
          backgroundColor: Colors.grey[50],
          body: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Header
                    _buildProfileHeader(),

                    const SizedBox(height: 20),

                    // Not Verified Status
                    _buildNotVerifiedStatus(),

                    const SizedBox(height: 20),

                    // Car Info Section
                    _buildSectionTitle('Car Info'),
                    _buildCarInfo(),

                    const SizedBox(height: 24),

                    // Documents Section
                    _buildSectionTitle('Documents'),
                    _buildDocumentsSection(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Update other methods to use actual data from state
}

Widget _buildProfileHeader() {
  return BlocBuilder<DriverDetailsCubit, DriverDetailsState>(
    builder: (context, state) {
      final driver = state.driverData;
      return Column(
        children: [
          Row(
            children: [
              Container(
                width: 85,
                height: 85,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[200],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(42.5),
                  child: Image.network(
                    'https://i.pravatar.cc/200',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    driver['name'] ?? 'Unknown',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.phone, size: 18, color: Colors.black54),
              const SizedBox(width: 8),
              Text(
                driver['phone_number'] ?? 'No phone',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.email, size: 18, color: Colors.black54),
              const SizedBox(width: 8),
              Text(
                driver['email'] ?? 'No email',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ],
      );
    },
  );
}

Widget _buildNotVerifiedStatus() {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
    child: const Text(
      'Not Verified',
      style: TextStyle(
        color: Colors.red,
        fontWeight: FontWeight.w500,
        fontSize: 16,
      ),
    ),
  );
}

Widget _buildSectionTitle(String title) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

Widget _buildCarInfo() {
  return BlocBuilder<DriverDetailsCubit, DriverDetailsState>(
    builder: (context, state) {
      final driver = state.driverData;
      return Column(
        children: [
          Row(
            children: [
              // Model
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Model',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      driver['car_model'] ?? 'Unknown',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Icon(
                  Icons.directions_car,
                  size: 30,
                  color: Colors.blue[600],
                ),
              ),

              // Color
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Color',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      driver['car_color'] ?? 'Unknown',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      );
    },
  );
}

Widget _buildDocumentsSection() {
  return BlocBuilder<DriverDetailsCubit, DriverDetailsState>(
    builder: (context, state) {
      final driver = state.driverData;
      final idCardImages = jsonDecode(driver['id_card_image'] ?? '{}');
      final licenseImages = jsonDecode(driver['license_image'] ?? '{}');
      final drivingLicenseImages =
          jsonDecode(driver['driving_license_image'] ?? '{}');

      return Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildDocumentItem(
                context, 'ID Card', 'Front', idCardImages['front']),
            _buildDocumentItem(
                context, 'License', 'Front', licenseImages['front']),
            _buildDocumentItem(
                context, 'License', 'Back', licenseImages['back']),
            _buildDocumentItem(
                context, 'Driving License', '', drivingLicenseImages['front']),
          ],
        ),
      );
    },
  );
}

Widget _buildDocumentItem(
    BuildContext context, String title, String subtitle, String? imagePath) {
  return Column(
    children: [
      GestureDetector(
        onTap: imagePath != null
            ? () {
                // Show dialog with big image
                showDialog(
                  context: context,
                  builder: (context) {
                    String fullPath = imagePath;
                    if (!imagePath.startsWith('driver_licenses/')) {
                      fullPath = 'driver_licenses/$imagePath';
                    }
                    final fullImageUrl =
                        '${AdminApiService.baseUrl.replaceAll('/api', '')}/storage/$fullPath';
                    return Dialog(
                      child: InteractiveViewer(
                        child: Image.network(fullImageUrl),
                      ),
                    );
                  },
                );
              }
            : null,
        child: Container(
          width: 70,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: imagePath != null
              ? FutureBuilder<Map<String, String>>(
                  future: AdminApiService().getImageHeaders(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(
                          child: CircularProgressIndicator(strokeWidth: 2));
                    }

                    final headers = snapshot.data!;

                    String fullPath = imagePath;
                    if (!imagePath.startsWith('driver_licenses/')) {
                      fullPath = 'driver_licenses/$imagePath';
                    }

                    final fullImageUrl =
                        '${AdminApiService.baseUrl.replaceAll('/api', '')}/storage/$fullPath';

                    debugPrint('Loading image from: $fullImageUrl');

                    return Image.network(
                      fullImageUrl,
                      fit: BoxFit.cover,
                      headers: headers,
                      errorBuilder: (context, error, stackTrace) {
                        debugPrint(
                            'Image error: $error for URL: $fullImageUrl');
                        return const Icon(Icons.broken_image,
                            color: Colors.grey);
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                            strokeWidth: 2,
                          ),
                        );
                      },
                    );
                  },
                )
              : const Icon(Icons.description, color: Colors.grey),
        ),
      ),
      const SizedBox(height: 4),
      Text(
        title,
        style: const TextStyle(fontSize: 12),
      ),
      Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      ),
    ],
  );
}
