import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../domain/models/trip_state.dart';

// Events
abstract class TripStateEvent extends Equatable {
  const TripStateEvent();

  @override
  List<Object?> get props => [];
}

class UpdateTripState extends TripStateEvent {
  final TripState newState;
  final LatLng? currentLocation;
  final LatLng? destination;

  const UpdateTripState({
    required this.newState,
    this.currentLocation,
    this.destination,
  });

  @override
  List<Object?> get props => [newState, currentLocation, destination];
}

// State
class TripStateState extends Equatable {
  final TripState currentState;
  final LatLng? currentLocation;
  final LatLng? destination;
  final List<LatLng>? routePoints;

  const TripStateState({
    this.currentState = TripState.pending,
    this.currentLocation,
    this.destination,
    this.routePoints,
  });

  TripStateState copyWith({
    TripState? currentState,
    LatLng? currentLocation,
    LatLng? destination,
    List<LatLng>? routePoints,
  }) {
    return TripStateState(
      currentState: currentState ?? this.currentState,
      currentLocation: currentLocation ?? this.currentLocation,
      destination: destination ?? this.destination,
      routePoints: routePoints ?? this.routePoints,
    );
  }

  @override
  List<Object?> get props => [currentState, currentLocation, destination, routePoints];
}

// Bloc
class TripStateBloc extends Bloc<TripStateEvent, TripStateState> {
  TripStateBloc() : super(const TripStateState()) {
    on<UpdateTripState>(_onUpdateTripState);
  }

  void _onUpdateTripState(UpdateTripState event, Emitter<TripStateState> emit) {
    emit(state.copyWith(
      currentState: event.newState,
      currentLocation: event.currentLocation,
      destination: event.destination,
    ));
  }
} 