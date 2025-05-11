import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zoom_way/data/api/admin_api_service.dart';

class DriverDetailsState {
  final Map<String, dynamic> driverData;
  final List<Map<String, dynamic>> rides;
  final bool isLoading;
  final String? error;

  DriverDetailsState({
    this.driverData = const {},
    this.rides = const [],
    this.isLoading = false,
    this.error,
  });
}

class DriverDetailsCubit extends Cubit<DriverDetailsState> {
  final AdminApiService _apiService = AdminApiService();
  final int driverId;

  DriverDetailsCubit(this.driverId) : super(DriverDetailsState()) {
    loadDriverDetails();
  }

  Future<void> loadDriverDetails() async {
    emit(DriverDetailsState(isLoading: true));
    try {
      final response = await _apiService.getDriverDetails(driverId);

      if (response['success'] == true &&
          response['data'] != null &&
          response['data']['success'] == true &&
          response['data']['driver'] != null) {
        final driver = response['data']['driver'];
        final rides = List<Map<String, dynamic>>.from(driver['rides'] ?? []);

        emit(DriverDetailsState(
          driverData: Map<String, dynamic>.from(driver),
          rides: rides,
        ));
        debugPrint('Driver details loaded successfully$response');
      } else {
        emit(DriverDetailsState(
          error: 'Failed to load driver details',
          driverData: const {},
          rides: const [],
        ));
        debugPrint('Failed to load driver details: $response');
      }
    } catch (e) {
      print('Error loading driver details: $e');
      emit(DriverDetailsState(
        error: 'Failed to load driver details',
        driverData: const {},
        rides: const [],
      ));
    }
  }
}
