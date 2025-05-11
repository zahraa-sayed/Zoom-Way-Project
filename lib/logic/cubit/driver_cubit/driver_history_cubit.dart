// logic/cubit/driver_cubit/driver_history_cubit.dart

import 'package:flutter_bloc/flutter_bloc.dart';

class DriverHistoryState {
  final List<dynamic> rides;
  final bool isLoading;
  final String? error;
  final DateTime? selectedDate;

  DriverHistoryState({
    required this.rides,
    required this.isLoading,
    this.error,
    this.selectedDate,
  });

  DriverHistoryState copyWith({
    List<dynamic>? rides,
    bool? isLoading,
    String? error,
    DateTime? selectedDate,
  }) {
    return DriverHistoryState(
      rides: rides ?? this.rides,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedDate: selectedDate ?? this.selectedDate,
    );
  }
}

class DriverHistoryCubit extends Cubit<DriverHistoryState> {
  DriverHistoryCubit() : super(DriverHistoryState(rides: [], isLoading: true));

  void loadRides() async {
    emit(state.copyWith(isLoading: true));
    try {
      // استبدل هذا بالـ API الحقيقي
      await Future.delayed(const Duration(seconds: 2));
      List<Map<String, dynamic>> fakeData = [
        {
          'pickup_location': '{"latitude": "30.033", "longitude": "31.233"}',
          'dropoff_location': '{"latitude": "30.056", "longitude": "31.232"}',
          'distance': 25.0,
          'status': 'completed',
          'passenger_name': 'Radwa'
        },
        // أضف المزيد حسب الحاجة
      ];

      emit(state.copyWith(rides: fakeData, isLoading: false));
    } catch (e) {
      emit(state.copyWith(error: e.toString(), isLoading: false));
    }
  }

  void filterRidesByDate(DateTime date) {
    emit(state.copyWith(selectedDate: date));
    // يمكنك هنا تصفية البيانات أو استدعاء API جديد
  }
}
