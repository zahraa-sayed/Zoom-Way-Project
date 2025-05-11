import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zoom_way/data/api/const.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}

class NetworkException implements Exception {
  final String message;

  NetworkException(this.message);

  @override
  String toString() => 'NetworkException: $message';
}

class DriverApiService {
  // Fix the base URL formatting - remove trailing slash if present
  static const String baseUrl = ApiConst.baseUrl;
  // Create storage for tokens
  final storage = const FlutterSecureStorage();

  // Register a new driver
  Future<Map<String, dynamic>> registerDriver({
    required String name,
    required String email,
    required String phoneNumber,
    required String carModel,
    required String password,
    required String passwordConfirmation,
    required String address,
    required String licenseNumber,
    required String drivingExperience,
    required String licensePlate,
    required String carColor,
    required String manufacturingYear,
    required File idCardFront,
    required File idCardBack,
    required File licenseFront,
    required File licenseBack,
    required File drivingLicenseFront,
    required File drivingLicenseBack,
  }) async {
    try {
      // Validate inputs
      if (name.isEmpty || email.isEmpty || password.isEmpty) {
        return {
          'success': false,
          'message': 'Required fields cannot be empty',
        };
      }

      // Validate email format
      final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegExp.hasMatch(email)) {
        return {
          'success': false,
          'message': 'Invalid email format',
        };
      }

      // Validate password match
      if (password != passwordConfirmation) {
        return {
          'success': false,
          'message': 'Passwords do not match',
        };
      }

      // Validate files exist
      if (!idCardFront.existsSync() ||
          !idCardBack.existsSync() ||
          !licenseFront.existsSync() ||
          !licenseBack.existsSync() ||
          !drivingLicenseFront.existsSync() ||
          !drivingLicenseBack.existsSync()) {
        return {
          'success': false,
          'message': 'One or more document files are missing',
        };
      }

      var request =
          http.MultipartRequest('POST', Uri.parse('$baseUrl/register'));

      // Add text fields
      request.fields.addAll({
        'name': name,
        'email': email,
        'phone_number': phoneNumber,
        'car_model': carModel,
        'password': password,
        'password_confirmation': passwordConfirmation,
        'address': address,
        'license_number': licenseNumber,
        'driving_experience': drivingExperience,
        'license_plate': licensePlate,
        'car_color': carColor,
        'manufacturing_year': manufacturingYear,
        'user_type': 'driver',
      });

      // Add files
      try {
        request.files.addAll([
          await http.MultipartFile.fromPath(
              'id_card_image[front]', idCardFront.path),
          await http.MultipartFile.fromPath(
              'id_card_image[back]', idCardBack.path),
          await http.MultipartFile.fromPath(
              'license_image[front]', licenseFront.path),
          await http.MultipartFile.fromPath(
              'license_image[back]', licenseBack.path),
          await http.MultipartFile.fromPath(
              'driving_license_image[front]', drivingLicenseFront.path),
          await http.MultipartFile.fromPath(
              'driving_license_image[back]', drivingLicenseBack.path),
        ]);
      } catch (e) {
        return {
          'success': false,
          'message': 'Error attaching files: ${e.toString()}',
        };
      }

      // Add headers
      request.headers.addAll({
        'Content-Type': 'application/json',
        'Accept': 'application/json, text/plain, */*',
        'ngrok-skip-browser-warning': 'true',
      });

      // Send request with timeout
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException(
              'Request timed out. Please check your internet connection and try again.');
        },
      );

      final response = await http.Response.fromStream(streamedResponse);

      // Handle response
      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
          final responseData = jsonDecode(response.body);
          return {'success': true, 'data': responseData};
        } catch (e) {
          return {
            'success': false,
            'message': 'Failed to parse response: ${e.toString()}',
          };
        }
      } else {
        // Handle various error status codes
        Map<String, dynamic> errorResponse;
        try {
          errorResponse = jsonDecode(response.body);
        } catch (e) {
          errorResponse = {'message': 'Unknown server error'};
        }

        String errorMessage = errorResponse['message'] ?? 'Registration failed';

        // Handle specific error codes
        if (response.statusCode == 401) {
          errorMessage = 'Unauthorized. Please check your credentials.';
        } else if (response.statusCode == 403) {
          errorMessage = 'Permission denied.';
        } else if (response.statusCode == 404) {
          errorMessage = 'Service not found. Please try again later.';
        } else if (response.statusCode == 422) {
          // Validation errors
          if (errorResponse.containsKey('errors')) {
            var errors = errorResponse['errors'];
            if (errors is Map) {
              errorMessage = errors.values.first is List
                  ? errors.values.first.first
                  : errors.values.first.toString();
            }
          }
        } else if (response.statusCode >= 500) {
          errorMessage = 'Server error. Please try again later.';
        }

        return {
          'success': false,
          'message': errorMessage,
          'statusCode': response.statusCode,
        };
      }
    } on SocketException catch (_) {
      return {
        'success': false,
        'message':
            'No internet connection. Please check your network and try again.',
      };
    } on HttpException catch (e) {
      return {
        'success': false,
        'message': 'HTTP error: ${e.toString()}',
      };
    } on FormatException catch (_) {
      return {
        'success': false,
        'message': 'Invalid response format from server.',
      };
    } on TimeoutException catch (_) {
      return {
        'success': false,
        'message': 'Request timed out. Please try again.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Unexpected error: ${e.toString()}',
      };
    }
  }

  // Login user (driver or passenger)
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('Starting login process...');
      debugPrint('Using API endpoint: $baseUrl/login');

      var headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json, text/plain, */*',
        'ngrok-skip-browser-warning': 'true'
      };

      var request = http.Request('POST', Uri.parse('$baseUrl/login'));
      request.body = json.encode(
          {"email": email, "password": password, "user_type": "driver"});
      request.headers.addAll(headers);

      debugPrint('Sending login request...');
      http.StreamedResponse response = await request.send();
      var responseBody = await response.stream.bytesToString();
      debugPrint('Response status code: ${response.statusCode}');
      debugPrint('Response body: $responseBody');

      if (response.statusCode == 200) {
        try {
          final parsedResponse = json.decode(responseBody);
          // Convert ID to string before storing
          await storage.write(
              key: "driver_id", value: parsedResponse['user']['id'].toString());
          // Store token if available
          if (parsedResponse['token'] != null) {
            await storage.write(
                key: 'auth_token', value: parsedResponse['token']);
            await storage.write(key: 'user_type', value: 'driver');

            // Store user data
            final userData = jsonEncode({'user': parsedResponse['user']});
            await storage.write(key: 'user_data', value: userData);
          }
          return {
            'success': true,
            'data': parsedResponse,
          };
        } catch (e) {
          debugPrint('Failed to parse response: $e');
          return {
            'success': false,
            'message': 'Invalid response format',
          };
        }
      } else {
        Map<String, dynamic> errorResponse;
        try {
          errorResponse = json.decode(responseBody);
          return {
            'success': false,
            'message': errorResponse['message'] ?? 'Login failed',
            'statusCode': response.statusCode,
          };
        } catch (e) {
          return {
            'success': false,
            'message': 'Login failed: ${response.reasonPhrase}',
            'statusCode': response.statusCode,
          };
        }
      }
    } catch (e) {
      debugPrint('Login error: $e');
      return {
        'success': false,
        'message': 'Connection error: ${e.toString()}',
      };
    }
  }

  // Get the stored token with error handling
  Future<String?> getToken() async {
    try {
      return await storage.read(key: 'auth_token');
    } catch (e) {
      // ignore: avoid_print
      print('Error retrieving token: ${e.toString()}');
      return null;
    }
  }

  // Logout - clear stored credentials with error handling
  Future<bool> logout() async {
    try {
      await storage.delete(key: 'auth_token');
      await storage.delete(key: 'user_type');
      await storage.delete(key: 'user_data');
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('Error during logout: ${e.toString()}');
      return false;
    }
  }

  Future<Map<String, dynamic>> checkApprovalStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication token not found',
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/driver/approval-status'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'is_approved': data['is_approved'] ?? false,
          'message': data['message'] ?? 'Status checked successfully',
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to check approval status',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }

  Map<String, dynamic> parseRideRequest(Map<String, dynamic> json) {
    // Parse pickup and dropoff locations
    final pickupLocation = json['pickup_location'] != null
        ? jsonDecode(json['pickup_location'])
        : {'latitude': 0.0, 'longitude': 0.0};

    final dropoffLocation = json['dropoff_location'] != null
        ? jsonDecode(json['dropoff_location'])
        : {'latitude': 0.0, 'longitude': 0.0};

    // Parse passenger rating
    final passengerRating =
        json['passenger'] != null && json['passenger']['rating'] != null
            ? jsonDecode(json['passenger']['rating'])
            : {'rate': 0, 'rate_count': 0};

    return {
      'id': json['id'],
      'passenger_id': json['passenger_id'],
      'driver_id': json['driver_id'],
      'pickup_location': pickupLocation,
      'dropoff_location': dropoffLocation,
      'region': json['region'] ?? '',
      'start_time': json['start_time'],
      'end_time': json['end_time'],
      'distance': double.tryParse(json['distance']?.toString() ?? '0') ?? 0.0,
      'fare': json['fare'] != null
          ? double.tryParse(json['fare'].toString())
          : null,
      'status': json['status'] ?? 'pending',
      'created_at': json['created_at'],
      'updated_at': json['updated_at'],
      'passenger': {
        'id': json['passenger']?['id'],
        'name': json['passenger']?['name'] ?? 'Unknown',
        'phone_number': json['passenger']?['phone_number'],
        'email': json['passenger']?['email'],
        'address': json['passenger']?['address'] ?? '',
        'rating': passengerRating,
      },
    };
  }

  Future<List<Map<String, dynamic>>> getMyRides() async {
    try {
      final token = await getToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      var headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json, text/plain, */*',
        'Authorization': 'Bearer $token',
        'ngrok-skip-browser-warning': 'true'
      };

      var request = http.Request('GET', Uri.parse('$baseUrl/rides/my-rides'));
      request.headers.addAll(headers);

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(responseBody);
        return jsonList.map((json) => parseRideRequest(json)).toList();
      } else {
        throw Exception('Failed to load rides: ${response.reasonPhrase}');
      }
    } catch (e) {
      debugPrint('Error fetching rides: $e');
      throw Exception('Failed to fetch rides: $e');
    }
  }

  // Add this method to the DriverApiService class
  Future<Map<String, dynamic>> updateDriverStatus(bool isOnline) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication token not found',
        };
      }

      final response = await http.post(
        Uri.parse('$baseUrl/driver/status'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'status': isOnline ? 'online' : 'offline',
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Status updated successfully',
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to update status',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> createBid(int rideId, double price) async {
    try {
      final token = await getToken();
      final prefs = await SharedPreferences.getInstance();
      final driverId =
          prefs.getString('driver_id'); // Get driver ID from SharedPreferences

      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication token not found',
        };
      }

      if (driverId == null) {
        return {
          'success': false,
          'message': 'Driver ID not found',
        };
      }

      debugPrint('Making API call to: $baseUrl/rides/$rideId/bids');
      debugPrint('Request body: {"price": $price, "driver_id": $driverId}');
      debugPrint('Token: $token');

      final response = await http.post(
        Uri.parse('$baseUrl/rides/$rideId/bids'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          "price": price,
          "driver_id": int.parse(driverId), // Include driver_id in request
        }),
      );

      debugPrint('Response status code: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'data': data,
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ??
              'Failed to create bid: ${response.reasonPhrase}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error creating bid: ${e.toString()}',
      };
    }
  }

  // Get all notifications
  Future<Map<String, dynamic>> getNotifications() async {
    try {
      final token = await getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication token not found',
        };
      }

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json, text/plain, */*',
        'Authorization': 'Bearer $token',
      };

      final response = await http.get(
        Uri.parse('$baseUrl/notifications'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': json.decode(response.body),
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch notifications: ${response.reasonPhrase}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error fetching notifications: $e',
      };
    }
  }

  // Get single notification
  Future<Map<String, dynamic>> getNotification(String notificationId) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication token not found',
        };
      }

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json, text/plain, */*',
        'Authorization': 'Bearer $token',
      };

      final response = await http.get(
        Uri.parse('$baseUrl/notifications/$notificationId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': json.decode(response.body),
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch notification: ${response.reasonPhrase}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error fetching notification: $e',
      };
    }
  }

  // Delete notification
  Future<Map<String, dynamic>> deleteNotification(String notificationId) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication token not found',
        };
      }

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json, text/plain, */*',
        'Authorization': 'Bearer $token',
      };

      final response = await http.delete(
        Uri.parse('$baseUrl/notifications/$notificationId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Notification deleted successfully',
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to delete notification: ${response.reasonPhrase}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error deleting notification: $e',
      };
    }
  }

  Future<Map<String, dynamic>> updateRideStatus(
      int rideId, String status) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication token not found',
        };
      }

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json, text/plain, */*',
        'Authorization': 'Bearer $token',
        'ngrok-skip-browser-warning': 'true'
      };

      final response = await http.put(
        Uri.parse('$baseUrl/ride/$rideId'),
        headers: headers,
        body: json.encode({
          "status": status,
        }),
      );

      debugPrint('Response status code: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'data': data,
          'message': 'Ride status updated successfully',
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to update ride status',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error updating ride status: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> getRideStatus(int rideId) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication token not found',
          'status': 'unknown'
        };
      }

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json, text/plain, */*',
        'Authorization': 'Bearer $token',
        'ngrok-skip-browser-warning': 'true'
      };

      final response = await http.get(
        Uri.parse('$baseUrl/ride/$rideId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'status': data['status'],
          'data': data,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to get ride status',
          'status': 'unknown'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error getting ride status: ${e.toString()}',
        'status': 'unknown'
      };
    }
  }

  Future<Map<String, dynamic>> submitFeedback({
    required int rideId,
    required int driverId,
    required int passengerId,
    double? passengerRating,
    double? driverRating,
    String? passengerComments,
    String? driverComments,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication token not found',
        };
      }

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json, text/plain, */*',
        'Authorization': 'Bearer $token',
        'ngrok-skip-browser-warning': 'true'
      };

      final response = await http.post(
        // ignore: unnecessary_brace_in_string_interps
        Uri.parse('${baseUrl}/feedback'),
        headers: headers,
        body: json.encode({
          "ride_id": rideId,
          "passenger_rating": passengerRating ?? 4.5,
          "driver_rating": driverRating ?? 4.5,
          "passenger_comments": passengerComments ?? "lorem100",
          "driver_comments": driverComments ?? "lorem100",
          "driver_id": driverId,
          "passenger_id": passengerId,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'data': data,
          'message': 'Feedback submitted successfully',
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to submit feedback',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error submitting feedback: ${e.toString()}',
      };
    }
  }
    Future<Map<String, dynamic>> sendMessage({
    required int rideId,
    required String message,
    required String senderType,
    required String receiverType,
    required int senderId,
    required int receiverId,
  }) async {
    try {
       final token = await getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication token not found',
        };
      }

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json, text/plain, */*',
        'Authorization': 'Bearer $token',
        'ngrok-skip-browser-warning': 'true'
      };

      var request = http.Request('POST', Uri.parse('$baseUrl/messages'));
      request.headers.addAll(headers);
      request.body = json.encode({
        "ride_id": rideId,
        "message": message,
        "sender_type": senderType,
        "receiver_type": receiverType,
        "sender_id": senderId,
        "receiver_id": receiverId
      });

      http.StreamedResponse response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        debugPrint('Message sent successfully: $responseBody');
        return {
          'success': true,
          'data': json.decode(responseBody),
        };
      } else {
        debugPrint('Failed to send message: $responseBody');
        return {
          'success': false,
          'message': 'Failed to send message',
        };
      }
    } catch (e) {
      debugPrint('Error sending message: $e');
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  // Add method to get chat messages for a ride
    Future<Map<String, dynamic>> getChatMessages(int rideId) async {
    try {
     

     final token = await getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication token not found',
        };
      }

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json, text/plain, */*',
        'Authorization': 'Bearer $token',
        'ngrok-skip-browser-warning': 'true'
      };

      var request = http.Request('GET', Uri.parse('$baseUrl/messages/$rideId'));
      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': json.decode(responseBody),
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch messages',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

}

class TimeoutException implements Exception {
  final String message;

  TimeoutException(this.message);

  @override
  String toString() => 'TimeoutException: $message';
}
