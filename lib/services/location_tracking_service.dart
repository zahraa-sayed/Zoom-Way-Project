import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:zoom_way/services/maps_service.dart';


enum RidePhase {
  idle,
  enRouteToPickup,
  waitingForPickup,
  enRouteToDestination,
  completed
}

class LocationTrackingService {
  static final LocationTrackingService _instance =
      LocationTrackingService._internal();
  factory LocationTrackingService() => _instance;
  LocationTrackingService._internal();

  static const double GEOFENCE_RADIUS = 50.0; // meters
  static const int LOCATION_UPDATE_INTERVAL = 5; // seconds

  final _locationController = StreamController<Position>.broadcast();
  final _phaseController = StreamController<RidePhase>.broadcast();
  final _etaController = StreamController<int>.broadcast();

  RidePhase _currentPhase = RidePhase.idle;
  Timer? _locationTimer;
  Position? _lastKnownLocation;
  LatLng? _pickupLocation;
  LatLng? _destinationLocation;
  Set<Polyline> _activeRoutes = {};

  // Getters
  Stream<Position> get locationStream => _locationController.stream;
  Stream<RidePhase> get phaseStream => _phaseController.stream;
  Stream<int> get etaStream => _etaController.stream;
  RidePhase get currentPhase => _currentPhase;
  Set<Polyline> get activeRoutes => _activeRoutes;

  Future<bool> _checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('Location services are disabled.');
      return false;
    }

    // Check location permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('Location permissions are denied');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('Location permissions are permanently denied');
      return false;
    }

    return true;
  }

  Future<void> startTracking() async {
    // Request location permissions and check if enabled
    if (!await _checkLocationPermission()) {
      throw Exception('Location permissions not granted');
    }

    // Get initial location immediately
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _lastKnownLocation = position;
      _locationController.add(position);
    } catch (e) {
      debugPrint('Error getting initial location: $e');
    }

    // Start periodic location updates
    _locationTimer?.cancel(); // Cancel any existing timer
    _locationTimer = Timer.periodic(
      const Duration(seconds: LOCATION_UPDATE_INTERVAL),
      (_) => _updateLocation(),
    );
  }

  Future<void> _updateLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _lastKnownLocation = position;
      _locationController.add(position);

      // Check geofence and update phase if necessary
      await _checkGeofenceAndUpdatePhase(position);

      // Update ETA
      await _updateETA(position);

      // Always recalculate route on location update
      await _recalculateRoute();
    } catch (e) {
      debugPrint('Error updating location: $e');
    }
  }

  Future<void> _checkGeofenceAndUpdatePhase(Position position) async {
    if (_currentPhase == RidePhase.enRouteToPickup && _pickupLocation != null) {
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        _pickupLocation!.latitude,
        _pickupLocation!.longitude,
      );

      if (distance <= GEOFENCE_RADIUS) {
        _updatePhase(RidePhase.waitingForPickup);
      }
    } else if (_currentPhase == RidePhase.enRouteToDestination &&
        _destinationLocation != null) {
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        _destinationLocation!.latitude,
        _destinationLocation!.longitude,
      );

      if (distance <= GEOFENCE_RADIUS) {
        _updatePhase(RidePhase.completed);
      }
    }
  }

  Future<void> _updateETA(Position position) async {
    if (_currentPhase == RidePhase.enRouteToPickup && _pickupLocation != null) {
      final eta = await _calculateETA(
        LatLng(position.latitude, position.longitude),
        _pickupLocation!,
      );
      _etaController.add(eta);
    } else if (_currentPhase == RidePhase.enRouteToDestination &&
        _destinationLocation != null) {
      final eta = await _calculateETA(
        LatLng(position.latitude, position.longitude),
        _destinationLocation!,
      );
      _etaController.add(eta);
    }
  }

  Future<int> _calculateETA(LatLng origin, LatLng destination) async {
    try {
      final route = await MapsService.getRoutePoints(origin, destination);
      // Assuming average speed of 30 km/h for simplicity
      // In real app, use actual traffic data and historical patterns
      final distance = await Geolocator.distanceBetween(
        origin.latitude,
        origin.longitude,
        destination.latitude,
        destination.longitude,
      );
      return (distance / (30 * 1000 / 3600)).round(); // ETA in seconds
    } catch (e) {
      print('Error calculating ETA: $e');
      return 0;
    }
  }

  bool _shouldRecalculateRoute(Position position) {
    // Recalculate if deviation is more than 200m from current route
    // This is a simplified check - in production, compare with actual route points
    return true; // For demo purposes, always recalculate
  }

  Future<void> startRide(LatLng pickup, LatLng destination) async {
    _pickupLocation = pickup;
    _destinationLocation = destination;
    _currentPhase = RidePhase.enRouteToPickup;
    _phaseController.add(_currentPhase);

    // Get current location if not available
    if (_lastKnownLocation == null) {
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        _lastKnownLocation = position;
        _locationController.add(position);
      } catch (e) {
        debugPrint('Error getting initial location: $e');
      }
    }

    // Calculate initial route
    await _recalculateRoute();
  }

  Future<void> _recalculateRoute() async {
    if (_lastKnownLocation == null) return;

    final currentLocation = LatLng(
      _lastKnownLocation!.latitude,
      _lastKnownLocation!.longitude,
    );

    try {
      List<LatLng> routePoints;
      Color routeColor;
      LatLng targetLocation;

      if (_currentPhase == RidePhase.enRouteToPickup &&
          _pickupLocation != null) {
        targetLocation = _pickupLocation!;
        routeColor = Colors.blue;
      } else if (_currentPhase == RidePhase.enRouteToDestination &&
          _destinationLocation != null) {
        targetLocation = _destinationLocation!;
        routeColor = Colors.green;
      } else {
        return;
      }

      routePoints = await MapsService.getRoutePoints(
        currentLocation,
        targetLocation,
      );

      _activeRoutes = {
        Polyline(
          polylineId: const PolylineId('current_route'),
          points: routePoints,
          color: routeColor,
          width: 5,
          patterns: [
            PatternItem.dash(20),
            PatternItem.gap(10),
          ],
        ),
      };
    } catch (e) {
      debugPrint('Error calculating route: $e');
    }
  }

  void markAsPickedUp() {
    _updatePhase(RidePhase.enRouteToDestination);
    _recalculateRoute();
  }

  void _updatePhase(RidePhase newPhase) {
    _currentPhase = newPhase;
    _phaseController.add(newPhase);
  }

  void dispose() {
    _locationTimer?.cancel();
    _locationController.close();
    _phaseController.close();
    _etaController.close();
  }
}
