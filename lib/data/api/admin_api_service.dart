import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'
    show FlutterSecureStorage;
import 'package:http/http.dart' as http;

import 'package:zoom_way/data/api/const.dart';

class AdminApiService {
  static String? token;

  static const String baseUrl = ApiConst.baseUrl;
  static const String imageBaseUrl = ApiConst.imageBaseUrl;
  final storage = const FlutterSecureStorage();

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('Attempting to login with email: $email');
      debugPrint('Using API endpoint: $baseUrl/login');

      var headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json, text/plain, */*',
        'ngrok-skip-browser-warning': 'true' // Add this for ngrok
      };

      var request = http.Request('POST', Uri.parse('$baseUrl/login'));
      request.body = json
          .encode({"email": email, "password": password, "user_type": "admin"});
      request.headers.addAll(headers);

      debugPrint('Sending login request...');
      http.StreamedResponse response = await request.send();
      debugPrint('Received response with status code: ${response.statusCode}');

      var responseBody = await response.stream.bytesToString();
      debugPrint(
          'Response body preview: ${responseBody.length > 100 ? responseBody.substring(0, 100) + "..." : responseBody}');

      // Check if response is HTML instead of JSON
      if (responseBody.trim().startsWith('<!DOCTYPE html>')) {
        debugPrint('Received HTML response instead of JSON');
        return {
          'success': false,
          'message':
              'Server returned HTML instead of JSON. Your ngrok tunnel might have expired or the server is returning an error page.',
        };
      }

      try {
        var parsedResponse = json.decode(responseBody);

        if (response.statusCode == 200) {
          // Store token if available
          if (parsedResponse['token'] != null) {
            await storage.write(
                key: 'admin_token', value: parsedResponse['token']);
            await storage.write(key: 'user_type', value: 'admin');
            debugPrint('Login successful, token stored');
          }
          return {
            'success': true,
            'data': parsedResponse,
          };
        } else {
          debugPrint('Login failed with status code: ${response.statusCode}');
          return {
            'success': false,
            'message': parsedResponse['message'] ?? 'Login failed',
          };
        }
      } catch (parseError) {
        debugPrint('Failed to parse JSON response: $parseError');
        return {
          'success': false,
          'message': 'Invalid response format: $parseError',
        };
      }
    } catch (e) {
      debugPrint('Login error: $e');
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> getPassengers() async {
    try {
      var headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json, text/plain, */*'
      };

      // Get token for authentication
      final token = await storage.read(key: 'admin_token');
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      var request = http.Request('GET', Uri.parse('$baseUrl/passengers'));
      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();
      var responseBody = await response.stream.bytesToString();
      var parsedResponse = json.decode(responseBody);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': parsedResponse,
        };
      } else {
        return {
          'success': false,
          'message': parsedResponse['message'] ?? 'Failed to fetch passengers',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> deletePassengers(List<int> passengerIds) async {
    try {
      var headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json, text/plain, */*'
      };

      final token = await storage.read(key: 'admin_token');
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      var request = http.Request('DELETE', Uri.parse('$baseUrl/passengers'));
      request.body = json.encode({"passenger_ids": passengerIds});
      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();
      var responseBody = await response.stream.bytesToString();
      var parsedResponse = json.decode(responseBody);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': parsedResponse,
        };
      } else {
        return {
          'success': false,
          'message': parsedResponse['message'] ?? 'Failed to delete passengers',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> updatePassenger(
      int passengerId, Map<String, dynamic> updateData) async {
    try {
      var headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json, text/plain, */*'
      };

      final token = await storage.read(key: 'admin_token');
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      var request =
          http.Request('PUT', Uri.parse('$baseUrl/passengers/$passengerId'));
      request.body = json.encode(updateData);
      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();
      var responseBody = await response.stream.bytesToString();
      var parsedResponse = json.decode(responseBody);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': parsedResponse,
        };
      } else {
        return {
          'success': false,
          'message': parsedResponse['message'] ?? 'Failed to update passenger',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> getPassengerDetails(int passengerId) async {
    try {
      var headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json, text/plain, */*'
      };

      final token = await storage.read(key: 'admin_token');
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      var request =
          http.Request('GET', Uri.parse('$baseUrl/passengers/$passengerId'));
      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();
      var responseBody = await response.stream.bytesToString();
      var parsedResponse = json.decode(responseBody);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': parsedResponse,
        };
      } else {
        return {
          'success': false,
          'message':
              parsedResponse['message'] ?? 'Failed to fetch passenger details',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> getDrivers() async {
    try {
      var headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json, text/plain, */*'
      };

      final token = await storage.read(key: 'admin_token');
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      var request = http.Request('GET', Uri.parse('$baseUrl/drivers'));
      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();
      var responseBody = await response.stream.bytesToString();
      var parsedResponse = json.decode(responseBody);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': parsedResponse,
        };
      } else {
        return {
          'success': false,
          'message': parsedResponse['message'] ?? 'Failed to fetch drivers',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> deleteDrivers(List<int> driverIds) async {
    try {
      var headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json, text/plain, */*'
      };

      final token = await storage.read(key: 'admin_token');
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      var request = http.Request('DELETE', Uri.parse('$baseUrl/drivers'));
      request.body = json.encode({"driver_ids": driverIds});
      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();
      var responseBody = await response.stream.bytesToString();
      var parsedResponse = json.decode(responseBody);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': parsedResponse,
        };
      } else {
        return {
          'success': false,
          'message': parsedResponse['message'] ?? 'Failed to delete drivers',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> updateDriver(int driverId,
      Map<String, dynamic> updateData, Map<String, String>? files) async {
    try {
      var headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json, text/plain, */*,multipart/form-data',
      };

      final token = await storage.read(key: 'admin_token');
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      var request =
          http.MultipartRequest('PUT', Uri.parse('$baseUrl/drivers/$driverId'));
      request.headers.addAll(headers);

      // Add regular fields
      updateData.forEach((key, value) {
        request.fields[key] = value.toString();
      });

      // Add files if provided
      if (files != null) {
        for (var entry in files.entries) {
          request.files
              .add(await http.MultipartFile.fromPath(entry.key, entry.value));
        }
      }

      http.StreamedResponse response = await request.send();
      var responseBody = await response.stream.bytesToString();
      var parsedResponse = json.decode(responseBody);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': parsedResponse,
        };
      } else {
        return {
          'success': false,
          'message': parsedResponse['message'] ?? 'Failed to update driver',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> getDriverDetails(int driverId) async {
    try {
      var headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json, text/plain, */*'
      };

      final token = await storage.read(key: 'admin_token');
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      var request =
          http.Request('GET', Uri.parse('$baseUrl/drivers/$driverId'));
      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();
      var responseBody = await response.stream.bytesToString();
      var parsedResponse = json.decode(responseBody);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': parsedResponse,
        };
      } else {
        return {
          'success': false,
          'message':
              parsedResponse['message'] ?? 'Failed to fetch driver details',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> getFeedbacks() async {
    try {
      var headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json, text/plain, */*'
      };

      final token = await storage.read(key: 'admin_token');
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      var request = http.Request('GET', Uri.parse('$baseUrl/feedback'));
      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();
      var responseBody = await response.stream.bytesToString();
      var parsedResponse = json.decode(responseBody);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': parsedResponse,
        };
      } else {
        return {
          'success': false,
          'message': parsedResponse['message'] ?? 'Failed to fetch feedbacks',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> getPayments() async {
    try {
      var headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json, text/plain, */*'
      };

      final token = await storage.read(key: 'admin_token');
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      var request = http.Request('GET', Uri.parse('$baseUrl/payments'));
      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();
      var responseBody = await response.stream.bytesToString();
      var parsedResponse = json.decode(responseBody);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': parsedResponse,
        };
      } else {
        return {
          'success': false,
          'message': parsedResponse['message'] ?? 'Failed to fetch payments',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> getNotifications() async {
    try {
      var headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json, text/plain, */*'
      };

      final token = await storage.read(key: 'admin_token');
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      var request = http.Request('GET', Uri.parse('$baseUrl/notifications'));
      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();
      var responseBody = await response.stream.bytesToString();
      var parsedResponse = json.decode(responseBody);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': parsedResponse,
        };
      } else {
        return {
          'success': false,
          'message':
              parsedResponse['message'] ?? 'Failed to fetch notifications',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  // Add this method to get the stored token
  Future<String?> getStoredToken() async {
    return await storage.read(key: 'admin_token');
  }

  // Add this method to get image headers
  // In admin_api_service.dart - Update the getImageHeaders method

  // Update these methods in your AdminApiService class

// Add this utility method
  static String getImageUrl(String imagePath) {
    // Make sure we're using the base URL without /api
    final baseUrlWithoutApi = baseUrl.replaceAll('/api', '');
    return '$baseUrlWithoutApi/storage/$imagePath';
  }

// Update the getImageHeaders method
  Future<Map<String, String>> getImageHeaders() async {
    final token = await getStoredToken();
    if (token == null) {
      throw Exception('Authentication token not found');
    }

    return {
      'Accept': '*/*',
      'Authorization': 'Bearer $token',
      'ngrok-skip-browser-warning': 'true',
      // Add these headers which might be needed for ngrok
      'Cache-Control': 'no-cache',
      'Pragma': 'no-cache',
    };
  }

// Add this useful method to get the correct image URL
  static String getFullImageUrl(String imagePath) {
    // Remove "driver_licenses/" prefix if present
    final cleanPath = imagePath.startsWith('driver_licenses/')
        ? imagePath
        : 'driver_licenses/$imagePath';

    return '$baseUrl/$cleanPath';
  }

  // Update the static token property
  static Future<Map<String, String>> get imageHeaders async {
    final storage = const FlutterSecureStorage();
    final token = await storage.read(key: 'admin_token');
    return {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
      'ngrok-skip-browser-warning': 'true',
    };
  }

  Future<Map<String, dynamic>> updateDriverVerification(
      int driverId, int isVerified) async {
    try {
      final token = await storage.read(key: 'admin_token');
      var headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token'
      };

      var request =
          http.Request('PUT', Uri.parse('$baseUrl/drivers/$driverId/verify'));
      request.body =
          json.encode({"is_verified": isVerified}); // Send as integer
      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();
      var responseBody = await response.stream.bytesToString();
      return json.decode(responseBody);
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to update driver verification'
      };
    }
  }

  Future<Map<String, dynamic>> declineDriver(int driverId) async {
    try {
      final token = await storage.read(key: 'admin_token');
      var headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token'
      };

      var request =
          http.Request('PUT', Uri.parse('$baseUrl/drivers/$driverId/decline'));
      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();
      var responseBody = await response.stream.bytesToString();
      return json.decode(responseBody);
    } catch (e) {
      return {'success': false, 'message': 'Failed to decline driver'};
    }
  }

  Future<bool> logout() async {
    final token = await storage.read(key: 'admin_token');
    var headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json, text/plain, */*',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    var request = http.Request('POST', Uri.parse('$baseUrl/logout'));
    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      // Optionally clear local storage/session here
      print(await response.stream.bytesToString());
      return true;
    } else {
      print(response.reasonPhrase);
      return false;
    }
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      debugPrint('Attempting to register admin with email: $email');

      var headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json, text/plain, */*',
        'ngrok-skip-browser-warning': 'true'
      };

      var request = http.Request('POST', Uri.parse('$baseUrl/register'));
      request.body = json.encode({
        "name": name,
        "email": email,
        "password": password,
        "password_confirmation": passwordConfirmation,
        "user_type": "admin"
      });
      request.headers.addAll(headers);

      debugPrint('Sending registration request...');
      http.StreamedResponse response = await request.send();
      debugPrint('Received response with status code: ${response.statusCode}');

      var responseBody = await response.stream.bytesToString();
      var parsedResponse = json.decode(responseBody);

      if (response.statusCode == 200) {
        // Store token if available
        if (parsedResponse['token'] != null) {
          await storage.write(
              key: 'admin_token', value: parsedResponse['token']);
          await storage.write(key: 'user_type', value: 'admin');
          debugPrint('Registration successful, token stored');
        }
        return {
          'success': true,
          'data': parsedResponse,
        };
      } else {
        debugPrint(
            'Registration failed with status code: ${response.statusCode}');
        return {
          'success': false,
          'message': parsedResponse['message'] ?? 'Registration failed',
          'errors': parsedResponse['errors'],
        };
      }
    } catch (e) {
      debugPrint('Registration error: $e');
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> deletePassengerDetail(int passengerId) async {
    try {
      debugPrint(
          'Starting deletePassengerDetail for passenger ID: $passengerId');
      var headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json, text/plain, */*',
        'ngrok-skip-browser-warning': 'true'
      };

      final token = await storage.read(key: 'admin_token');
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
      debugPrint('Using headers: $headers');

      final url = '$baseUrl/passengers';
      debugPrint('Making DELETE request to: $url');

      var request = http.Request('DELETE', Uri.parse(url));
      request.headers.addAll(headers);

      // Add the required passenger_ids field in the request body
      request.body = json.encode({
        "passenger_ids": [passengerId]
      });
      debugPrint('Request body: ${request.body}');

      debugPrint('Sending request...');
      http.StreamedResponse response = await request.send();
      debugPrint('Received response with status code: ${response.statusCode}');

      var responseBody = await response.stream.bytesToString();
      debugPrint('Response body: $responseBody');

      var parsedResponse = json.decode(responseBody);

      if (response.statusCode == 200) {
        debugPrint('Delete successful');
        return {
          'success': true,
          'data': parsedResponse,
        };
      } else {
        debugPrint('Delete failed with status: ${response.statusCode}');
        return {
          'success': false,
          'message': parsedResponse['message'] ?? 'Failed to delete passenger',
        };
      }
    } catch (e) {
      debugPrint('Error in deletePassengerDetail: $e');
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }
}
