import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zoom_way/data/api/admin_api_service.dart';

class PassengerDetailsState {
  final Map<String, dynamic> passengerData;
  final List<Map<String, dynamic>> rides;
  final bool isLoading;
  final String? error;

  PassengerDetailsState({
    this.passengerData = const {}, // Initialize with empty map
    this.rides = const [], // Initialize with empty list
    this.isLoading = false,
    this.error,
  });
}

class PassengerDetailsCubit extends Cubit<PassengerDetailsState> {
  final AdminApiService _apiService = AdminApiService();
  final int passengerId;

  PassengerDetailsCubit(this.passengerId) : super(PassengerDetailsState()) {
    loadPassengerDetails();
  }

  Future<void> loadPassengerDetails() async {
    emit(PassengerDetailsState(isLoading: true));
    try {
      final response = await _apiService.getPassengerDetails(passengerId);

      if (response != null &&
          response['success'] == true &&
          response['data'] != null &&
          response['data']['success'] == true) {
        final passenger = response['data']['passenger'];

        emit(PassengerDetailsState(
          passengerData: Map<String, dynamic>.from(passenger),
          rides: List<Map<String, dynamic>>.from(passenger['rides'] ?? []),
        ));
      } else {
        emit(PassengerDetailsState(
          error: response?['data']?['message'] ??
              'Failed to load passenger details',
          passengerData: const {},
          rides: const [],
        ));
        debugPrint(
            'Error loading passenger details: ${response?['data']?['message']}');
      }
    } catch (e) {
      print('Error loading passenger details: $e');
      emit(PassengerDetailsState(
        error: 'Failed to load passenger details',
        passengerData: const {},
        rides: const [],
      ));
    }
  }
}
