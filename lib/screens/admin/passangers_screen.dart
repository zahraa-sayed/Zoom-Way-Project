import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zoom_way/data/api/admin_api_service.dart';
import 'package:zoom_way/logic/cubit/admin_cubit/passenger_details_cubit.dart';
import 'package:zoom_way/screens/admin/passenger_details.dart';

// Passenger Model
class Passenger {
  final String id;
  final String name;
  final String flightName;
  final String imageUrl;
  final String email;
  final String phoneNumber;
  final String address;
  final double? rating; // Make rating nullable
  bool isSelected;

  Passenger({
    required this.id,
    required this.name,
    required this.flightName,
    required this.imageUrl,
    required this.email,
    required this.phoneNumber,
    required this.address,
    this.rating, // Make rating optional
    this.isSelected = false,
  });

  factory Passenger.fromJson(Map<String, dynamic> json) {
    double? parseRating(dynamic ratingData) {
      try {
        if (ratingData == null) return 0.0;
        final parsed = jsonDecode(ratingData.toString());
        return (parsed['rate'] as num?)?.toDouble() ?? 0.0;
      } catch (e) {
        return 0.0;
      }
    }

    return Passenger(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? 'Unknown Passenger',
      flightName: json['flightName'] ?? 'Unknown Flight',
      imageUrl: json['imageUrl'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      address: json['address'] ?? '',
      rating: parseRating(json['rating']),
      isSelected: json['isSelected'] ?? false,
    );
  }
}

// Cubit for Managing Passenger State
class PassengerCubit extends Cubit<List<Passenger>> {
  final AdminApiService _apiService = AdminApiService();

  PassengerCubit() : super([]);

  Future<void> loadPassengers() async {
    try {
      final response = await _apiService.getPassengers();

      if (response['success']) {
        final List<dynamic> passengersData = response['data'] ?? [];
        final List<Passenger> passengers = passengersData.map((data) {
          return Passenger.fromJson(data);
        }).toList();

        emit(passengers);
      } else {
        // Handle unsuccessful API response
        print('Failed to load passengers: ${response['message']}');
        emit([]); // Emit empty list to indicate no passengers
      }
    } catch (e) {
      // Handle error
      print('Error loading passengers: $e');
      emit([]); // Emit empty list on error
    }
  }

  void togglePassengerSelection(int index) {
    final updatedPassengers = List<Passenger>.from(state);
    updatedPassengers[index].isSelected = !updatedPassengers[index].isSelected;
    emit(updatedPassengers);
  }

  Future<bool> removePassenger(int index) async {
    final updatedPassengers = List<Passenger>.from(state);
    final passenger = updatedPassengers[index];

    try {
      final passengerId = int.tryParse(passenger.id) ?? 0;
      final response = await _apiService.deletePassengers([passengerId]);

      if (response['success']) {
        updatedPassengers.removeAt(index);
        emit(updatedPassengers);
        return true;
      } else {
        print('Error removing passenger: ${response['message']}');
        return false;
      }
    } catch (e) {
      print('Error removing passenger: $e');
      return false;
    }
  }
}

// Passengers Screen
class PassengersScreen extends StatefulWidget {
  const PassengersScreen({super.key});

  @override
  State<PassengersScreen> createState() => _PassengersScreenState();
}

class _PassengersScreenState extends State<PassengersScreen> {
  late PassengerCubit _passengerCubit;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _passengerCubit = context.read<PassengerCubit>();
    _loadPassengers();
  }

  Future<void> _loadPassengers() async {
    setState(() {
      _isLoading = true;
    });

    await _passengerCubit.loadPassengers();

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Passengers',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: const Icon(Icons.search, color: Colors.black),
              onPressed: () {
                // Implement search functionality
              },
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadPassengers,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : BlocBuilder<PassengerCubit, List<Passenger>>(
                builder: (context, passengers) {
                  if (passengers.isEmpty) {
                    return const Center(child: Text('No passengers found'));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    itemCount: passengers.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () async {
                          // Navigate and wait for result
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BlocProvider(
                                create: (context) => PassengerDetailsCubit(
                                    int.parse(passengers[index].id)),
                                child: PassengerProfileScreen(
                                  passengerId: int.parse(passengers[index].id),
                                ),
                              ),
                            ),
                          );

                          // If passenger was deleted (result is true), refresh the list
                          if (result == true && mounted) {
                            _loadPassengers();
                          }
                        },
                        child: _buildPassengerItem(
                            context, passengers[index], index),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }

  Widget _buildPassengerItem(
      BuildContext context, Passenger passenger, int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
      child: Row(
        children: [
          // Passenger Image
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.grey[200],
            backgroundImage:
                passenger.imageUrl != null && passenger.imageUrl.isNotEmpty
                    ? NetworkImage(passenger.imageUrl)
                    : null,
            child: passenger.imageUrl == null || passenger.imageUrl.isEmpty
                ? const Icon(Icons.person, size: 40, color: Colors.grey)
                : null,
            onBackgroundImageError: (_, __) {
              // Fallback for image loading errors
            },
          ),
          const SizedBox(width: 16),
          // Passenger Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  passenger.name,
                  style: TextStyle(
                    color: Colors.teal[400],
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      (passenger.rating ?? 0.0).toStringAsFixed(1),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ), // Action Buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Select Button
              InkWell(
                onTap: () => context
                    .read<PassengerCubit>()
                    .togglePassengerSelection(index),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: passenger.isSelected ? Colors.green : Colors.black,
                      width: 2,
                    ),
                    color: passenger.isSelected ? Colors.green : Colors.white,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.check,
                      color: passenger.isSelected
                          ? Colors.white
                          : Colors.transparent,
                      size: 24,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Remove Button
              InkWell(
                onTap: () async {
                  final success = await context
                      .read<PassengerCubit>()
                      .removePassenger(index);
                  if (success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Passenger removed successfully'),
                        backgroundColor: Color(0xFF2DC8A8),
                      ),
                    );
                    // Refresh the screen
                    if (mounted) {
                      setState(() {
                        _loadPassengers();
                      });
                    }
                  }
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.close,
                      color: Colors.black,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// للاستخدام في main.dart أو عند تسجيل الكوبت
Widget buildPassengersScreenWithBloc() {
  return BlocProvider(
    create: (context) => PassengerCubit()..loadPassengers(),
    child: const PassengersScreen(),
  );
}
