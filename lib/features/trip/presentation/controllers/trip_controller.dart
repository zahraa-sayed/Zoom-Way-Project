import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../domain/models/trip_state.dart';
import '../../domain/services/route_service.dart';
import 'package:zoom_way/data/api/driver_api_services.dart';

class TripController {
  final RouteService _routeService;
  final DriverApiService _driverApiService;
  final Function(TripState) onStateChanged;
  final Function(Set<Polyline>) onRoutesChanged;
  final Function(String, double) onETAUpdated; // ETA and distance updates

  StreamSubscription<Position>? _locationSubscription;
  Timer? _etaUpdateTimer;
  LatLng? _lastKnownLocation;
  static const double ARRIVAL_THRESHOLD = 100; // meters

  TripController({
    required String googleMapsApiKey,
    required this.onStateChanged,
    required this.onRoutesChanged,
    required this.onETAUpdated,
  })  : _routeService = RouteService(apiKey: googleMapsApiKey),
        _driverApiService = DriverApiService();

  Future<void> startTrip({
    required int rideId,
    required LatLng driverLocation,
    required LatLng pickupLocation,
    required LatLng destinationLocation,
  }) async {
    _lastKnownLocation = driverLocation;

    // Start location tracking
    await _startLocationTracking(rideId, pickupLocation, destinationLocation);

    // Update status and draw initial route
    await _updateTripStatus(rideId, TripState.going_to_passenger);
    await _drawRouteToPickup(driverLocation, pickupLocation);

    // Start ETA updates
    _startETAUpdates(pickupLocation);
  }

  Future<void> _startLocationTracking(
    int rideId,
    LatLng pickupLocation,
    LatLng destinationLocation,
  ) async {
    // Request location permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw Exception('Location permissions are denied');
    }

    // Start location updates
    _locationSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    ).listen((Position position) async {
      final currentLocation = LatLng(position.latitude, position.longitude);
      _lastKnownLocation = currentLocation;

      // Check if arrived at pickup location during going_to_passenger state
      if (await _isNearLocation(currentLocation, pickupLocation)) {
        await arrivedAtPickup(rideId);
        return;
      }

      // Update route based on current state
      final state = await _driverApiService.getRideStatus(rideId);
      if (state['status'] == 'going_to_passenger') {
        await _drawRouteToPickup(currentLocation, pickupLocation);
      } else if (state['status'] == 'in_progress') {
        await _drawRouteToDestination(currentLocation, destinationLocation);
      }
    });
  }

  Future<bool> _isNearLocation(LatLng current, LatLng target) async {
    double distance = await Geolocator.distanceBetween(
      current.latitude,
      current.longitude,
      target.latitude,
      target.longitude,
    );
    return distance <= ARRIVAL_THRESHOLD;
  }

  void _startETAUpdates(LatLng destination) {
    _etaUpdateTimer?.cancel();
    _etaUpdateTimer =
        Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (_lastKnownLocation != null) {
        final eta = await _routeService.getETAAndDistance(
          origin: _lastKnownLocation!,
          destination: destination,
        );
        onETAUpdated(eta.duration, eta.distance);
      }
    });
  }

  Future<void> arrivedAtPickup(int rideId) async {
    _etaUpdateTimer?.cancel();
    await _updateTripStatus(rideId, TripState.arrived);
    onRoutesChanged({});
  }

  Future<void> startRide({
    required int rideId,
    required LatLng currentLocation,
    required LatLng destinationLocation,
  }) async {
    await _updateTripStatus(rideId, TripState.in_progress);
    await _drawRouteToDestination(currentLocation, destinationLocation);
    _startETAUpdates(destinationLocation);
  }

  Future<void> completeTrip(int rideId) async {
    _locationSubscription?.cancel();
    _etaUpdateTimer?.cancel();
    await _updateTripStatus(rideId, TripState.completed);
    onRoutesChanged({});
  }

  Future<void> _updateTripStatus(int rideId, TripState status) async {
    final result =
        await _driverApiService.updateRideStatus(rideId, status.name);
    if (result['success']) {
      onStateChanged(status);
    }
  }

  Future<void> _drawRouteToPickup(
      LatLng driverLocation, LatLng pickupLocation) async {
    final points = await _routeService.getRoutePoints(
      origin: driverLocation,
      destination: pickupLocation,
    );

    onRoutesChanged({
      Polyline(
        polylineId: const PolylineId('route_to_pickup'),
        points: points,
        color: Colors.blue,
        width: 5,
      ),
    });
  }

  Future<void> _drawRouteToDestination(
      LatLng currentLocation, LatLng destinationLocation) async {
    final points = await _routeService.getRoutePoints(
      origin: currentLocation,
      destination: destinationLocation,
    );

    onRoutesChanged({
      Polyline(
        polylineId: const PolylineId('route_to_destination'),
        points: points,
        color: Colors.green,
        width: 5,
      ),
    });
  }

  void dispose() {
    _locationSubscription?.cancel();
    _etaUpdateTimer?.cancel();
  }
}
