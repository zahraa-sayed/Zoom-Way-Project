import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TrafficService {
  static final TrafficService _instance = TrafficService._internal();
  factory TrafficService() => _instance;
  TrafficService._internal();

  final _trafficStreamController =
      StreamController<Map<String, dynamic>>.broadcast();
  Timer? _trafficUpdateTimer;
  String? _apiKey;

  // Getters
  Stream<Map<String, dynamic>> get trafficStream =>
      _trafficStreamController.stream;

  // Initialize the service with API key
  void initialize(String apiKey) {
    _apiKey = apiKey;
    _startTrafficUpdates();
  }

  // Start periodic traffic updates
  void _startTrafficUpdates() {
    _trafficUpdateTimer =
        Timer.periodic(const Duration(minutes: 5), (timer) async {
      await _fetchTrafficData();
    });
  }

  // Fetch traffic data from API
  Future<void> _fetchTrafficData() async {
    if (_apiKey == null) return;

    try {
      // This is a placeholder URL. Replace with actual traffic API endpoint
      final response = await http.get(
        Uri.parse('https://api.example.com/traffic?key=$_apiKey'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _trafficStreamController.add(data);
      }
    } catch (e) {
      print('Error fetching traffic data: $e');
    }
  }

  // Get traffic information for a specific route
  Future<Map<String, dynamic>> getTrafficInfo(List<LatLng> route) async {
    if (_apiKey == null) return {};

    try {
      // This is a placeholder implementation
      // Replace with actual traffic API call
      return {
        'status': 'moderate',
        'delay': 5,
        'description': 'Moderate traffic on route',
      };
    } catch (e) {
      print('Error getting traffic info: $e');
      return {};
    }
  }

  // Dispose
  void dispose() {
    _trafficUpdateTimer?.cancel();
    _trafficStreamController.close();
  }
}
