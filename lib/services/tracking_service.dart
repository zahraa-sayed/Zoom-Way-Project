import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:zoom_way/models/delivery_status.dart';

enum RideStatus {
  going_to_passenger,
  arrived_at_pickup,
  in_progress,
  completed
}

class TrackingService {
  static final TrackingService _instance = TrackingService._internal();
  factory TrackingService() => _instance;
  TrackingService._internal();

  final _locationStreamController = StreamController<Position>.broadcast();
  final _deliveryStatusController =
      StreamController<DeliveryStatus>.broadcast();
  final _carMarkerController = StreamController<CarMarkerData>.broadcast();
  final _routeDeviationController = StreamController<bool>.broadcast();
  Timer? _locationUpdateTimer;
  Position? _currentPosition;
  String? _rideId;
  String? _apiKey;
  double _lastHeading = 0;
  List<LatLng>? _currentRoute;
  RideStatus _currentStatus = RideStatus.going_to_passenger;
  LatLng? _pickupLocation;
  LatLng? _destinationLocation;
  bool _hasArrivedAtPickup = false;

  // Getters
  Stream<Position> get locationStream => _locationStreamController.stream;
  Stream<DeliveryStatus> get deliveryStatusStream =>
      _deliveryStatusController.stream;
  Stream<CarMarkerData> get carMarkerStream => _carMarkerController.stream;
  Stream<bool> get routeDeviationStream => _routeDeviationController.stream;
  RideStatus get currentStatus => _currentStatus;

  // Initialize tracking
  Future<void> initialize({
    required String apiKey,
    required String rideId,
    required LatLng pickup,
    required LatLng destination,
  }) async {
    _apiKey = apiKey;
    _rideId = rideId;
    _pickupLocation = pickup;
    _destinationLocation = destination;
    _currentStatus = RideStatus.going_to_passenger;
    await _checkLocationPermission();
    _startLocationUpdates();
    _startStatusUpdates();
  }

  // Check location permissions
  Future<void> _checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }
  }

  // Start location updates
  void _startLocationUpdates() {
    _locationUpdateTimer =
        Timer.periodic(const Duration(seconds: 1), (timer) async {
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          forceAndroidLocationManager: true,
        );
        _currentPosition = position;
        _locationStreamController.add(position);
        _updateDeliveryLocation(position);
        _updateCarMarker(position);
        _checkRouteDeviation(position);
        _checkArrival(position);
      } catch (e) {
        print('Error getting location: $e');
      }
    });
  }

  // Update car marker position and rotation
  void _updateCarMarker(Position position) {
    // Calculate heading change
    double heading = position.heading;
    if (heading < 0) heading += 360;

    // Smooth rotation
    double targetRotation = heading;
    if ((targetRotation - _lastHeading).abs() > 180) {
      if (targetRotation > _lastHeading) {
        targetRotation -= 360;
      } else {
        targetRotation += 360;
      }
    }

    _lastHeading = targetRotation;

    _carMarkerController.add(CarMarkerData(
      position: LatLng(position.latitude, position.longitude),
      rotation: targetRotation,
      speed: position.speed,
    ));
  }

  // Update delivery location on server
  Future<void> _updateDeliveryLocation(Position position) async {
    if (_rideId == null) return;

    try {
      final response = await http.post(
        Uri.parse('YOUR_API_ENDPOINT/delivery/location'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'delivery_id': _rideId,
          'latitude': position.latitude,
          'longitude': position.longitude,
          'timestamp': DateTime.now().toIso8601String(),
          'speed': position.speed,
          'heading': position.heading,
        }),
      );

      if (response.statusCode != 200) {
        print('Failed to update delivery location');
      }
    } catch (e) {
      print('Error updating delivery location: $e');
    }
  }

  // Start delivery status updates
  void _startStatusUpdates() {
    Timer.periodic(const Duration(seconds: 10), (timer) async {
      if (_rideId == null) return;

      try {
        final response = await http.get(
          Uri.parse('YOUR_API_ENDPOINT/delivery/status/$_rideId'),
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          _deliveryStatusController.add(DeliveryStatus(
            status: _currentStatus.toString(),
            polylinePoints: _currentRoute,
            estimatedArrivalTime: _calculateETA(
                data['routes'][0]['legs'][0]['duration']['value']),
            distanceRemaining:
                data['routes'][0]['legs'][0]['distance']['value'] / 1000,
          ));
        }
      } catch (e) {
        print('Error getting delivery status: $e');
      }
    });
  }

  void _checkArrival(Position position) {
    if (_currentStatus == RideStatus.going_to_passenger &&
        !_hasArrivedAtPickup) {
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        _pickupLocation!.latitude,
        _pickupLocation!.longitude,
      );

      if (distance <= 50) {
        // Within 50 meters
        _hasArrivedAtPickup = true;
        _updateRideStatus(RideStatus.arrived_at_pickup);
      }
    } else if (_currentStatus == RideStatus.in_progress) {
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        _destinationLocation!.latitude,
        _destinationLocation!.longitude,
      );

      if (distance <= 50) {
        // Within 50 meters
        _updateRideStatus(RideStatus.completed);
      }
    }
  }

  Future<void> _updateRideStatus(RideStatus newStatus) async {
    try {
      final response = await http.put(
        Uri.parse(
            'https://dd26-41-33-95-84.ngrok-free.app/api/ride/${_rideId}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'status': newStatus.toString().split('.').last,
        }),
      );

      if (response.statusCode == 200) {
        _currentStatus = newStatus;
        if (newStatus == RideStatus.in_progress) {
          // Update route to destination
          await _calculateRoute(
              LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
              _destinationLocation!);
        }
      } else {
        throw Exception('Failed to update ride status');
      }
    } catch (e) {
      print('Error updating ride status: $e');
    }
  }

  Future<void> _calculateRoute(LatLng origin, LatLng destination) async {
    try {
      final url = Uri.parse(
          'https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}'
          '&destination=${destination.latitude},${destination.longitude}'
          '&key=$_apiKey');

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          _currentRoute =
              _decodePolyline(data['routes'][0]['overview_polyline']['points']);
          // Notify listeners about new route
          _deliveryStatusController.add(DeliveryStatus(
            status: _currentStatus.toString(),
            polylinePoints: _currentRoute,
            estimatedArrivalTime: _calculateETA(
                data['routes'][0]['legs'][0]['duration']['value']),
            distanceRemaining:
                data['routes'][0]['legs'][0]['distance']['value'] / 1000,
          ));
        }
      }
    } catch (e) {
      print('Error calculating route: $e');
    }
  }

  void _checkRouteDeviation(Position position) {
    if (_currentRoute == null) return;

    // Find closest point on route
    double minDistance = double.infinity;
    for (var point in _currentRoute!) {
      double distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        point.latitude,
        point.longitude,
      );
      if (distance < minDistance) {
        minDistance = distance;
      }
    }

    // If deviation is more than 200m, notify and recalculate route
    if (minDistance > 200) {
      _routeDeviationController.add(true);
      _recalculateRoute(position);
    }
  }

  Future<void> _recalculateRoute(Position position) async {
    LatLng destination;
    if (_currentStatus == RideStatus.going_to_passenger) {
      destination = _pickupLocation!;
    } else if (_currentStatus == RideStatus.in_progress) {
      destination = _destinationLocation!;
    } else {
      return;
    }

    await _calculateRoute(
      LatLng(position.latitude, position.longitude),
      destination,
    );
  }

  // Convert duration from seconds to minutes
  double _calculateETA(int durationInSeconds) {
    return durationInSeconds / 60;
  }

  // Decode Google Maps encoded polyline string to list of LatLng
  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }

  void startRide() {
    if (_currentStatus == RideStatus.arrived_at_pickup) {
      _updateRideStatus(RideStatus.in_progress);
    }
  }

  // Dispose
  void dispose() {
    _locationUpdateTimer?.cancel();
    _locationStreamController.close();
    _deliveryStatusController.close();
    _carMarkerController.close();
    _routeDeviationController.close();
  }
}

class CarMarkerData {
  final LatLng position;
  final double rotation;
  final double speed;

  CarMarkerData({
    required this.position,
    required this.rotation,
    required this.speed,
  });
}
