enum TripState {
  pending,
  going_to_passenger,
  arrived,
  in_progress,
  completed;

  String get displayName {
    switch (this) {
      case TripState.pending:
        return 'Waiting for driver';
      case TripState.going_to_passenger:
        return 'Driver is heading to pickup location';
      case TripState.arrived:
        return 'Driver has arrived at pickup location';
      case TripState.in_progress:
        return 'Ride is ongoing';
      case TripState.completed:
        return 'Ride is completed';
    }
  }
}
