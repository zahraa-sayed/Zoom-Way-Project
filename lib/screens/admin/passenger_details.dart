import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:intl/intl.dart';
import '../../data/api/admin_api_service.dart';
import '../../logic/cubit/admin_cubit/passenger_details_cubit.dart';


class PassengerProfileScreen extends StatelessWidget {
  final int passengerId;
  final AdminApiService _adminService = AdminApiService();

  PassengerProfileScreen({
    super.key,
    required this.passengerId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PassengerDetailsCubit(passengerId),
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        body: BlocBuilder<PassengerDetailsCubit, PassengerDetailsState>(
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.error != null) {
              return Center(child: Text(state.error!));
            }

            return SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionWithHeader(
                      'Passenger Information',
                      _buildPassengerInfoContent(state.passengerData),
                      onEdit: () {
                        // Handle edit action
                        print('Edit passenger info');
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildSectionWithoutButton(
                      'Ride History',
                      _buildRideHistoryContent(state.rides),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: ElevatedButton(
                          onPressed: () async {
                            // Show confirmation dialog
                            final shouldDelete = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete Passenger'),
                                content: const Text(
                                    'Are you sure you want to delete this passenger?'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );

                            if (shouldDelete == true && context.mounted) {
                              try {
                                print(
                                    'Attempting to delete passenger with ID: $passengerId');
                                final response = await _adminService
                                    .deletePassengerDetail(passengerId);
                                print('Delete response: $response');

                                if (context.mounted) {
                                  if (response['success']) {
                                    // First show success message
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Passenger deleted successfully'),
                                        backgroundColor: Color(0xFF2DC8A8),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );

                                    // Wait for snackbar to be visible
                                    await Future.delayed(
                                        const Duration(milliseconds: 500));

                                    if (context.mounted) {
                                      // Pop back to previous screen
                                      Navigator.of(context).pop(true);
                                    }
                                  } else {
                                    // Show detailed error message
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'Error: ${response['message'] ?? 'Failed to delete passenger'}'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              } catch (e) {
                                print('Error during deletion: $e');
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error: $e'),
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
                            padding: const EdgeInsets.symmetric(
                                horizontal: 32, vertical: 20),
                            minimumSize: const Size(200, 60), // حجم الزر الأدنى
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Delete',
                            style: TextStyle(fontSize: 18), // حجم الخط
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionWithHeader(String title, Widget content,
      {VoidCallback? onEdit}) {
    return Container(
      margin: const EdgeInsets.all(0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (onEdit != null)
                  OutlinedButton(
                    onPressed: onEdit,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.black),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Edit',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
              ],
            ),
          ),
          content,
        ],
      ),
    );
  }

  Widget _buildSectionWithoutButton(String title, Widget content) {
    return Container(
      margin: const EdgeInsets.all(0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          content,
        ],
      ),
    );
  }

  Widget _buildPassengerInfoContent(Map<String, dynamic> passengerData) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.grey[300],
                child: Text(
                  passengerData['name']?.substring(0, 1).toUpperCase() ?? 'U',
                  style: const TextStyle(fontSize: 30),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    passengerData['name'] ?? 'Unknown',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.black, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        '${_parseRating(passengerData['rating'])}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildInfoRow('Phone', passengerData['phone_number'] ?? 'N/A'),
        _buildInfoRow('Email', passengerData['email'] ?? 'N/A'),
        _buildInfoRow('Address', passengerData['address'] ?? 'N/A'),
        const SizedBox(height: 16),
      ],
    );
  }

  String _parseRating(dynamic rating) {
    try {
      if (rating == null) return '0.00';
      if (rating is String) {
        final parsed = jsonDecode(rating);
        return (parsed['rate'] as num).toStringAsFixed(2);
      }
      if (rating is num) {
        return rating.toStringAsFixed(2);
      }
      return '0.00';
    } catch (e) {
      return '0.00';
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRideHistoryContent(List<Map<String, dynamic>> rides) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Expanded(flex: 2, child: Text('Date')),
              Expanded(flex: 2, child: Text('Location')),
              Expanded(flex: 2, child: Text('Distance')),
              Expanded(flex: 2, child: Text('Status')),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ...rides.map((ride) => _buildRideRow(
              date: DateFormat('d MMM yyyy')
                  .format(DateTime.parse(ride['created_at'])),
              location: ride['region'] ?? 'Unknown',
              distance: '${ride['distance']} km',
              status: ride['status'] ?? 'Unknown',
            )),
      ],
    );
  }

  Widget _buildRideRow({
    required String date,
    required String location,
    required String distance,
    required String status,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              date,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              location,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              distance,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color:
                    status == 'Completed' ? Colors.grey[200] : Colors.grey[300],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                status,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: status == 'Completed' ? Colors.black : Colors.black87,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
