import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:zoom_way/logic/cubit/driver_cubit/driver_history_cubit.dart';

class DriverHistoryScreen extends StatelessWidget {
  const DriverHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DriverHistoryCubit()..loadRides(),
      child: Scaffold(
        body: Container(
          color: const Color(0xFF26AB91),
          child: SafeArea(
            child: BlocBuilder<DriverHistoryCubit, DriverHistoryState>(
              builder: (context, state) {
                return Column(
                  children: [
                    _buildHeader(context, state),
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
                                        itemCount: state.rides.length,
                                        itemBuilder: (context, index) {
                                          final ride = state.rides[index];
                                          final pickup = json
                                              .decode(ride['pickup_location']);
                                          final dropoff = json
                                              .decode(ride['dropoff_location']);

                                          return _buildHistoryItem(
                                            pickup: _formatLocation(pickup),
                                            dropoff: _formatLocation(dropoff),
                                            amount: double.tryParse(
                                                    ride['distance']
                                                        .toString()) ??
                                                0.0,
                                            status: ride['status'],
                                            statusColor:
                                                _getStatusColor(ride['status']),
                                            passengerName:
                                                ride['passenger_name'],
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

  Widget _buildHeader(BuildContext context, DriverHistoryState state) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child:
                const Icon(Icons.arrow_back_ios, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 12),
          const Text(
            'Driver History',
            style: TextStyle(
                color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: state.selectedDate ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                context.read<DriverHistoryCubit>().filterRidesByDate(picked);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Text(
                    state.selectedDate != null
                        ? DateFormat('MMM dd, yyyy').format(state.selectedDate!)
                        : 'Select Date',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem({
    required String pickup,
    required String dropoff,
    required double amount,
    required String status,
    required Color statusColor,
    required String passengerName,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Passenger: $passengerName',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Pickup: $pickup'),
          Text('Dropoff: $dropoff'),
          const Divider(),
          Row(
            children: [
              Text('\$${amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              Text(status,
                  style: TextStyle(
                      color: statusColor, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
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

  String _formatLocation(Map<String, dynamic> location) {
    double? lat = double.tryParse(location['latitude'].toString());
    double? lon = double.tryParse(location['longitude'].toString());
    if (lat == null || lon == null) return 'Unknown';
    return '${lat.toStringAsFixed(5)}, ${lon.toStringAsFixed(5)}';
  }
}
