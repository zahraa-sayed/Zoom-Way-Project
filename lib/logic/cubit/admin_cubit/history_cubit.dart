import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zoom_way/data/api/admin_api_service.dart';

class HistoryState {
  final List<Map<String, dynamic>> rides;
  final bool isLoading;
  final String? error;
  final DateTime? selectedDate;

  HistoryState({
    this.rides = const [],
    this.isLoading = false,
    this.error,
    this.selectedDate,
  });
}

class HistoryCubit extends Cubit<HistoryState> {
  final AdminApiService _apiService = AdminApiService();
  List<Map<String, dynamic>> _allRides = [];

  HistoryCubit() : super(HistoryState()) {
    loadHistory();
  }

  Future<void> loadHistory() async {
    emit(HistoryState(isLoading: true, selectedDate: state.selectedDate));
    try {
      final response = await _apiService.getDrivers();
      if (response['success']) {
        _allRides = [];
        
        for (var driver in response['data']) {
          if (driver['rides'] != null) {
            for (var ride in driver['rides']) {
              _allRides.add({
                ...ride,
                'driver_name': driver['name'],
                'driver_phone': driver['phone_number'],
              });
            }
          }
        }
        
        filterRidesByDate(state.selectedDate);
      } else {
        emit(HistoryState(error: response['message'], selectedDate: state.selectedDate));
      }
    } catch (e) {
      emit(HistoryState(error: e.toString(), selectedDate: state.selectedDate));
    }
  }

  void filterRidesByDate(DateTime? date) {
    if (date == null) {
      emit(HistoryState(rides: _allRides, selectedDate: null));
      return;
    }

    final filteredRides = _allRides.where((ride) {
      final rideDate = DateTime.parse(ride['created_at']);
      return rideDate.year == date.year &&
             rideDate.month == date.month &&
             rideDate.day == date.day;
    }).toList();

    emit(HistoryState(rides: filteredRides, selectedDate: date));
  }
}
