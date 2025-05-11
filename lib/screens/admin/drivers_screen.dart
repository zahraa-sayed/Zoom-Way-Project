

// Driver Model
// Driver Model
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zoom_way/data/api/admin_api_service.dart';
import 'package:zoom_way/logic/cubit/admin_cubit/driver_details_cubit.dart';
import 'package:zoom_way/screens/admin/not_verified_driver.dart';
import 'package:zoom_way/screens/admin/verifed_driver_details.dart';

class Driver {
  final int id;
  final String flightName;
  final String name;
  final String email;
  final String? phoneNumber;
  final bool isVerified;
  bool isSelected;

  Driver({
    required this.id,
    required this.flightName,
    required this.name,
    required this.email,
    this.phoneNumber,
    required this.isVerified,
    this.isSelected = false,
  });

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: json['id'],
      flightName: json['flight_name'] ?? 'Unknown Flight',
      name: json['name'] ?? 'Unknown',
      email: json['email'] ?? 'No email',
      phoneNumber: json['phone_number'],
      isVerified: json['is_verified'] == '1' || json['is_verified'] == 1,
    );
  }
}

// Update the Cubit to use API
class DriverCubit extends Cubit<List<Driver>> {
  final AdminApiService _apiService = AdminApiService();

  DriverCubit() : super([]) {
    loadDrivers();
  }

  Future<void> loadDrivers() async {
    try {
      final response = await _apiService.getDrivers();
      if (response['success']) {
        final List<Driver> drivers = (response['data'] as List)
            .map((json) => Driver.fromJson(json))
            .toList();
        emit(drivers);
      }
    } catch (e) {
      // Handle error if needed
      emit([]);
    }
  }

  void toggleDriverSelection(int index) {
    final updatedDrivers = List<Driver>.from(state);
    updatedDrivers[index].isSelected = !updatedDrivers[index].isSelected;
    emit(updatedDrivers);
  }

  Future<void> removeDriver(int index) async {
    final driver = state[index];
    try {
      final response = await _apiService.deleteDrivers([driver.id]);
      if (response['success']) {
        final updatedDrivers = List<Driver>.from(state);
        updatedDrivers.removeAt(index);
        emit(updatedDrivers);
      }
    } catch (e) {
      // Handle error if needed
    }
  }

  Future<void> toggleDriverVerification(int index) async {
    final driver = state[index];
    try {
      // Only toggle if the current state is different from what we want to set
      final newVerificationStatus = !driver.isVerified;
      final response = await _apiService.updateDriverVerification(
          driver.id, newVerificationStatus ? 1 : 0);

      if (response['success'] == true) {
        final updatedDrivers = List<Driver>.from(state);
        updatedDrivers[index] = Driver(
          id: driver.id,
          flightName: driver.flightName,
          name: driver.name,
          email: driver.email,
          phoneNumber: driver.phoneNumber,
          isVerified: newVerificationStatus,
          isSelected: driver.isSelected,
        );
        emit(updatedDrivers);
      } else {
        // Show error message if the driver is already in the desired state
        if (response['message']?.contains('already been verified') == true ||
            response['message']?.contains('already been unverified') == true) {
          // Update UI to reflect the current state
          final updatedDrivers = List<Driver>.from(state);
          updatedDrivers[index] = Driver(
            id: driver.id,
            flightName: driver.flightName,
            name: driver.name,
            email: driver.email,
            phoneNumber: driver.phoneNumber,
            isVerified: !newVerificationStatus, // Keep the current state
            isSelected: driver.isSelected,
          );
          emit(updatedDrivers);
        }
      }
    } catch (e) {
      print('Error updating driver verification: $e');
    }
  }

  Future<void> declineDriver(int index) async {
    final driver = state[index];
    try {
      final response = await _apiService.declineDriver(driver.id);
      if (response['success'] == true) {
        final updatedDrivers = List<Driver>.from(state);
        updatedDrivers.removeAt(index);
        emit(updatedDrivers);
        print('Driver ${driver.name} declined successfully');
      } else {
        print('Failed to decline driver. Response: $response');
      }
    } catch (e) {
      print('Error declining driver: $e');
    }
  }
}

// Drivers Screen
class DriversScreen extends StatelessWidget {
  const DriversScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Drivers'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: BlocProvider(
        create: (context) => DriverCubit(),
        child: const DriverList(),
      ),
    );
  }
}

// Driver List Widget
class DriverList extends StatelessWidget {
  const DriverList({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DriverCubit, List<Driver>>(
      builder: (context, Drivers) {
        if (Drivers.isEmpty) {
          return const Center(
            child: Text(
              'No drivers found',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () => context.read<DriverCubit>().loadDrivers(),
          child: ListView.builder(
            itemCount: Drivers.length,
            itemBuilder: (context, index) {
              return DriverTile(driver: Drivers[index], index: index);
            },
          ),
        );
      },
    );
  }
}

// Driver Tile Widget
class DriverTile extends StatelessWidget {
  final Driver driver;
  final int index;

  const DriverTile({super.key, required this.driver, required this.index});

  @override
  Widget build(BuildContext context) {
    final driverCubit = context.read<DriverCubit>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BlocProvider.value(
                value: DriverDetailsCubit(driver.id)..loadDriverDetails(),
                child: driver.isVerified
                    ? DriverProfileScreen()
                    : const NotVerifiedDriverProfileScreen(),
              ),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 5,
              ),
            ],
          ),
          child: ListTile(
            leading: Image.asset('assets/images/driver.png'),
            title: Text(driver.name,
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.teal[400])),
            subtitle: Text(driver.flightName),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    driver.isVerified
                        ? Icons.verified_user
                        : Icons.verified_user_outlined,
                    color: driver.isVerified ? Colors.green : Colors.grey,
                  ),
                  onPressed: () => driverCubit.toggleDriverVerification(index),
                ),
                IconButton(
                  icon: const Icon(Icons.block, color: Colors.red),
                  onPressed: () => driverCubit.declineDriver(index),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
