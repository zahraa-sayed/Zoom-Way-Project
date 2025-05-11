import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../data/api/admin_api_service.dart';
import '../../logic/cubit/admin_cubit/driver_details_cubit.dart';
import 'drivers_screen.dart';


class DriverProfileScreen extends StatelessWidget {
  const DriverProfileScreen({super.key});

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
        final rating =
            jsonDecode(driver['rating'] ?? '{"rate":0,"rate_count":0}');

        // Update your existing widgets with actual data
        return Scaffold(
          backgroundColor: Colors.grey[100],
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Profile Header
                        _buildProfileHeader(),

                        // Car Info Section
                        _buildSectionTitle('Car Info',
                            trailing: Row(
                              children: [
                                _buildStatusChip('Active', Colors.green),
                                const SizedBox(width: 8),
                                _buildStatusChip('Verified', Colors.green),
                              ],
                            )),
                        _buildCarInfoSection(),

                        // Rating Section
                        _buildSectionTitle('Rating & Experience'),
                        _buildRatingSection(),

                        // Documents Section
                        _buildSectionTitle('Documents'),
                        _buildDocumentsSection(),

                        // Ride History Section
                        _buildSectionTitle('Ride History'),
                        _buildRideHistorySection(),

                        // Created Info Section
                        _buildCreatedInfoSection(),

                        Padding(
                          padding: EdgeInsets.only(
                              bottom: 24.h, top: 10.h), // padding علوي وسفلي
                          child: Center(
                            child: SizedBox(
                              width: 200.w,
                              height: 50.h,
                              child: ElevatedButton(
                                onPressed: () async {
                                  // Show confirmation dialog
                                  final shouldDelete = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Delete Driver'),
                                      content: const Text(
                                          'Are you sure you want to delete this driver? This action cannot be undone.'),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (shouldDelete == true) {
                                    final adminService = AdminApiService();
                                    final response = await adminService
                                        .deleteDrivers(
                                            [state.driverData['id']]);

                                    if (response['success'] == true) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Driver deleted successfully'),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                        // Get the parent context before popping
                                        final parentContext = context;
                                        Navigator.pop(context);
                                        // Refresh the drivers list using parent context
                                        parentContext
                                            .read<DriverCubit>()
                                            .loadDrivers();
                                      }
                                    } else {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(response['message'] ??
                                                'Failed to delete driver'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey[300],
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  'Delete',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Space for the delete button
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader() {
    return BlocBuilder<DriverDetailsCubit, DriverDetailsState>(
      builder: (context, state) {
        final driver = state.driverData;
        return Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              const CircleAvatar(
                radius: 40,
                backgroundImage: NetworkImage('https://i.pravatar.cc/300'),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driver['name'] ?? 'Unknown',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.phone, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          driver['phone_number'] ?? 'No phone',
                          style:
                              const TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.email, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          driver['email'] ?? 'No email',
                          style:
                              const TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title, {Widget? trailing}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildCarInfoSection() {
    return BlocBuilder<DriverDetailsCubit, DriverDetailsState>(
      builder: (context, state) {
        final driver = state.driverData;
        final tableData = [
          ['Model', 'Color', 'License Plate'],
          [
            driver['car_model'] ?? 'Unknown',
            driver['car_color'] ?? 'Unknown',
            driver['license_plate'] ?? 'Unknown',
          ],
        ];

        return Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Table(
            columnWidths: const {
              0: FlexColumnWidth(1),
              1: FlexColumnWidth(1),
              2: FlexColumnWidth(1),
            },
            children: tableData.map((row) {
              return TableRow(
                children: row.map((cell) {
                  final isHeader = tableData.indexOf(row) == 0;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      cell,
                      style: TextStyle(
                        fontSize: isHeader ? 14 : 16,
                        fontWeight:
                            isHeader ? FontWeight.normal : FontWeight.w500,
                        color: isHeader ? Colors.grey[700] : Colors.black,
                      ),
                    ),
                  );
                }).toList(),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildRatingSection() {
    return BlocBuilder<DriverDetailsCubit, DriverDetailsState>(
      builder: (context, state) {
        final driver = state.driverData;
        final rating =
            jsonDecode(driver['rating'] ?? '{"rate":0,"rate_count":0}');

        return Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.star, color: Colors.amber[700], size: 20),
                      const SizedBox(width: 4),
                      Text(
                        rating['rate'].toString(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.access_time,
                          color: Colors.black, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        '${driver['driving_experience'] ?? 0} Years',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
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
              _buildDocumentItem(context, 'Driving License', '',
                  drivingLicenseImages['front']),
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

  Widget _buildRideHistorySection() {
    return BlocBuilder<DriverDetailsCubit, DriverDetailsState>(
      builder: (context, state) {
        final rides = state.rides;

        return Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: Text(
                        'Date',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        'Distance',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        'Fare',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        'Status',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              ...rides
                  .map((ride) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: Text(ride['created_at'] ?? ''),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text('${ride['distance'] ?? 0} km'),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text('${ride['fare'] ?? 0} EGP'),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                ride['status'] ?? 'Unknown',
                                style: TextStyle(
                                  color: (ride['status'] == 'completed')
                                      ? Colors.green[700]
                                      : Colors.red[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCreatedInfoSection() {
    return BlocBuilder<DriverDetailsCubit, DriverDetailsState>(
      builder: (context, state) {
        final driver = state.driverData;
        final createdAt = driver['created_at'] != null
            ? DateTime.parse(driver['created_at']).toString().substring(0, 10)
            : 'Unknown';
        final updatedAt = driver['updated_at'] != null
            ? DateTime.parse(driver['updated_at']).toString().substring(0, 10)
            : 'Unknown';

        return Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Created At',
                      style: TextStyle(color: Colors.grey),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Last Updated',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(createdAt),
                    const SizedBox(height: 4),
                    Text(updatedAt),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
