import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:zoom_way/logic/cubit/passenger_cubit/passenger_history_cubit.dart';

class PassengerHistoryScreen extends StatelessWidget {
  const PassengerHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PassengerHistoryCubit(),
      child: Scaffold(
        body: Container(
          color: const Color(0xFF26AB91),
          child: SafeArea(
            child: BlocBuilder<PassengerHistoryCubit, PassengerHistoryState>(
              builder: (context, state) {
                return Column(
                  children: [
                    // App bar with back button, title and date picker
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: const Icon(
                              Icons.arrow_back_ios,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'History',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () async {
                              final DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate:
                                    state.selectedDate ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) {
                                context
                                    .read<PassengerHistoryCubit>()
                                    .filterRidesByDate(picked);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    state.selectedDate != null
                                        ? DateFormat('MMM dd, yyyy')
                                            .format(state.selectedDate!)
                                        : 'Select Date',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.keyboard_arrow_down,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // List of history items
                    Expanded(
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                        ),
                        child: state.isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : state.error != null
                                ? Center(child: Text(state.error!))
                                : state.rides.isEmpty
                                    ? const Center(
                                        child: Text('No rides found'))
                                    : ListView.builder(
                                        padding: EdgeInsets.zero,
                                        itemCount: state.rides.length,
                                        itemBuilder: (context, index) {
                                          final ride = state.rides[index];
                                          // Parse location JSON strings
                                          Map<String, dynamic> pickupLocation =
                                              json.decode(
                                                  ride['pickup_location']);
                                          Map<String, dynamic> dropoffLocation =
                                              json.decode(
                                                  ride['dropoff_location']);

                                          return _buildHistoryItem(
                                            pickup:
                                                _formatLocation(pickupLocation),
                                            dropoff: _formatLocation(
                                                dropoffLocation),
                                            amount: double.parse(
                                                ride['distance'].toString()),
                                            status: ride['status'] ?? 'Unknown',
                                            statusColor:
                                                _getStatusColor(ride['status']),
                                            driverName: ride['driver_name'] ??
                                                'Not Assigned',
                                          );
                                        },
                                      ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      case 'confirm':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Widget _buildHistoryItem({
    required String pickup,
    required String dropoff,
    required double amount,
    required String status,
    required Color statusColor,
    required String driverName,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Location section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    // Origin marker
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: const Color(0xFF26AB91),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                    // Dotted line
                    Container(
                      width: 2,
                      height: 40,
                      color: Colors.grey.withOpacity(0.3),
                    ),
                    // Destination marker
                    Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.location_on,
                          color: Colors.white, size: 14),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pickup,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        dropoff,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Divider
          const Divider(height: 1),

          // Price and status section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.attach_money, color: Colors.grey),
                ),
                const SizedBox(width: 12),
                Text(
                  '\$${amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right,
                  color: statusColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
    // Add driver name display if needed
  }
}

String _formatLocation(Map<String, dynamic> location) {
  double? latitude = double.tryParse(location['latitude'].toString());
  double? longitude = double.tryParse(location['longitude'].toString());

  if (latitude == null || longitude == null) {
    return 'Unknown location';
  }

  return '${latitude.toStringAsFixed(6)}°N, ${longitude.toStringAsFixed(6)}°E';
}
