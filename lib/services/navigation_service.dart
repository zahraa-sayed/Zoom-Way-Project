import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();

  final _locationStreamController = StreamController<Position>.broadcast();
  Timer? _locationUpdateTimer;
  Position? _currentPosition;
  List<LatLng>? _currentRoute;
  bool _isNavigating = false;
  String? _apiKey;

  // Getters
  Stream<Position> get locationStream => _locationStreamController.stream;
  Position? get currentPosition => _currentPosition;
  List<LatLng>? get currentRoute => _currentRoute;
  bool get isNavigating => _isNavigating;

  // Initialize the service
  Future<void> initialize({required String apiKey}) async {
    _apiKey = apiKey;
    await _checkLocationPermission();
    _startLocationUpdates();
  }

  // Check and request location permissions
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

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }
  }

  // Start location updates
  void _startLocationUpdates() {
    _locationUpdateTimer =
        Timer.periodic(const Duration(seconds: 3), (timer) async {
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        _currentPosition = position;
        _locationStreamController.add(position);
      } catch (e) {
        print('Error getting location: $e');
      }
    });
  }

  // Get route between two points
  Future<List<LatLng>> getRoute(LatLng origin, LatLng destination) async {
    try {
      final url = Uri.parse(
          'https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&key=$_apiKey');

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          _currentRoute =
              _decodePolyline(data['routes'][0]['overview_polyline']['points']);
          return _currentRoute!;
        }
      }
      throw Exception('Failed to get route');
    } catch (e) {
      print('Error getting route: $e');
      rethrow;
    }
  }

  // Decode Google Maps polyline
  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> poly = [];
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

      poly.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return poly;
  }

  // Start navigation
  void startNavigation() {
    _isNavigating = true;
  }

  // Stop navigation
  void stopNavigation() {
    _isNavigating = false;
    _currentRoute = null;
  }

  // Dispose
  void dispose() {
    _locationUpdateTimer?.cancel();
    _locationStreamController.close();
  }
}
