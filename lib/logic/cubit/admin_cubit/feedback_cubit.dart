import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geocoding/geocoding.dart';
import 'package:zoom_way/data/api/admin_api_service.dart';

class FeedbackState {
  final List<Map<String, dynamic>> feedbacks;
  final bool isLoading;
  final String? error;

  FeedbackState({
    this.feedbacks = const [],
    this.isLoading = false,
    this.error,
  });
}

class FeedbackCubit extends Cubit<FeedbackState> {
  final AdminApiService _apiService = AdminApiService();

  FeedbackCubit() : super(FeedbackState()) {
    loadFeedbacks();
  }

  Future<String> _parseLocation(String locationString) async {
    try {
      final cleanString = locationString.replaceAll("'", '"');
      final Map<String, dynamic> coords = json.decode(cleanString);
      
      // Convert string coordinates to double
      final double latitude = double.parse(coords['latitude'].toString());
      final double longitude = double.parse(coords['longitude'].toString());

      // Get place name from coordinates
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        // Format the address
        return '${place.street ?? ''}, ${place.locality ?? ''}, ${place.country ?? ''}'
            .replaceAll(RegExp(r', ,'), ',')  // Remove empty parts
            .replaceAll(RegExp(r'^,\s*'), '') // Remove leading comma
            .trim();
      }
      
      // Fallback to coordinates if geocoding fails
      return 'Lat: $latitude, Long: $longitude';
    } catch (e) {
      debugPrint('Location parsing error: $e');
      return 'Unknown location';
    }
  }

  Future<void> loadFeedbacks() async {
    emit(FeedbackState(isLoading: true));
    try {
      final response = await _apiService.getFeedbacks();

      if (response['success']) {
        final List<Map<String, dynamic>> processedFeedbacks = [];

        for (var feedback in response['data']) {
          // Process pickup and dropoff locations
          final pickupLocation =
              await _parseLocation(feedback['pickup_location'] ?? '');
          final dropoffLocation =
              await _parseLocation(feedback['dropoff_location'] ?? '');

          processedFeedbacks.add({
            ...feedback,
            'pickup_location': pickupLocation,
            'dropoff_location': dropoffLocation,
            'driver': {
              'name': feedback['driver_name'] ?? 'Unknown Driver',
            },
            'passenger': {
              'name': feedback['passenger_name'] ?? 'Unknown Passenger',
            },
            'driver_comment': feedback['driver_comment'] ?? 'No comment',
            'passenger_comment': feedback['passenger_comment'] ?? 'No comment',
            'driver_rating': feedback['driver_rating'] ?? 0,
            'passenger_rating': feedback['passenger_rating'] ?? 0,
            'status': feedback['status'] ?? 'completed',
          });
        }

        emit(FeedbackState(feedbacks: processedFeedbacks));
      } else {
        emit(FeedbackState(error: response['message']));
      }
    } catch (e) {
      print('Feedback API Error: ${e.toString()}');
      emit(FeedbackState(error: e.toString()));
    }
  }
}
