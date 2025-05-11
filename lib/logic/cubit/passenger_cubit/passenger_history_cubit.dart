import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zoom_way/data/api/passengers_api_service.dart';

class PassengerHistoryState {
  final List<Map<String, dynamic>> rides;
  final bool isLoading;
  final String? error;
  final DateTime? selectedDate;

  PassengerHistoryState({
    this.rides = const [],
    this.isLoading = false,
    this.error,
    this.selectedDate,
  });
}

class PassengerHistoryCubit extends Cubit<PassengerHistoryState> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _allRides = [];

  PassengerHistoryCubit() : super(PassengerHistoryState()) {
    loadHistory();
  }

  Future<void> loadHistory() async {
    emit(PassengerHistoryState(isLoading: true, selectedDate: state.selectedDate));
    try {
      final response = await _apiService.getRides();
      if (response['success']) {
        _allRides = [];
        
        for (var ride in response['data']) {
          _allRides.add({
            ...ride,
            'status': ride['status'],
            'distance': ride['distance'],
            'region': ride['region'],
            'created_at': ride['created_at'],
            'driver_name': ride['driver']?['name'] ?? 'Not Assigned',
            'driver_phone': ride['driver']?['phone_number'] ?? 'N/A',
          });
        }
        
        filterRidesByDate(state.selectedDate);
      } else {
        emit(PassengerHistoryState(
          error: response['message'], 
          selectedDate: state.selectedDate
        ));
      }
    } catch (e) {
      emit(PassengerHistoryState(
        error: e.toString(), 
        selectedDate: state.selectedDate
      ));
    }
  }

  void filterRidesByDate(DateTime? date) {
    if (date == null) {
      emit(PassengerHistoryState(rides: _allRides, selectedDate: null));
      return;
    }

    final filteredRides = _allRides.where((ride) {
      final rideDate = DateTime.parse(ride['created_at']);
      return rideDate.year == date.year &&
             rideDate.month == date.month &&
             rideDate.day == date.day;
    }).toList();

    emit(PassengerHistoryState(rides: filteredRides, selectedDate: date));
  }
}
