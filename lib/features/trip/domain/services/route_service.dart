import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ETAInfo {
  final String duration;
  final double distance;

  ETAInfo({required this.duration, required this.distance});
}

class RouteService {
  final String _apiKey;
  final String _baseUrl = 'https://maps.googleapis.com/maps/api';

  RouteService({required String apiKey}) : _apiKey = apiKey;

  Future<List<LatLng>> getRoutePoints({
    required LatLng origin,
    required LatLng destination,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/directions/json?origin=${origin.latitude},${origin.longitude}'
          '&destination=${destination.latitude},${destination.longitude}'
          '&mode=driving&key=$_apiKey',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final points = data['routes'][0]['overview_polyline']['points'];
          return _decodePolyline(points);
        }
      }
      return [];
    } catch (e) {
      print('Error getting route: $e');
      return [];
    }
  }

  Future<ETAInfo> getETAAndDistance({
    required LatLng origin,
    required LatLng destination,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/directions/json?origin=${origin.latitude},${origin.longitude}'
          '&destination=${destination.latitude},${destination.longitude}'
          '&mode=driving&key=$_apiKey',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final leg = data['routes'][0]['legs'][0];
          return ETAInfo(
            duration: leg['duration']['text'],
            distance: leg['distance']['value'] / 1000, // Convert to kilometers
          );
        }
      }
      return ETAInfo(duration: 'Unknown', distance: 0.0);
    } catch (e) {
      print('Error getting ETA: $e');
      return ETAInfo(duration: 'Error', distance: 0.0);
    }
  }

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

      final p = LatLng(lat / 1E5, lng / 1E5);
      poly.add(p);
    }
    return poly;
  }

  Future<LatLng?> getLocationFromAddress(String address) async {
    try {
      final encodedAddress = Uri.encodeComponent(address);
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/geocode/json?address=$encodedAddress&key=$_apiKey',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          final location = data['results'][0]['geometry']['location'];
          return LatLng(location['lat'], location['lng']);
        }
      }
      return null;
    } catch (e) {
      print('Error geocoding address: $e');
      return null;
    }
  }
}
