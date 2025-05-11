import 'dart:io';
import 'package:flutter/material.dart';

class ErrorUtils {
  // Network error handler
  static String handleNetworkError(dynamic error) {
    if (error is SocketException) {
      return 'Network error: Please check your internet connection';
    } else if (error.toString().contains('timeout')) {
      return 'Request timed out: Server is taking too long to respond';
    } else if (error.toString().contains('HttpException')) {
      return 'HTTP error occurred: Unable to complete request';
    } else {
      return 'An unexpected error occurred: ${error.toString()}';
    }
  }

  // Form validation error handler
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }

  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    final phoneRegex = RegExp(r'^\d{10,15}$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  static String? validateYear(String? value) {
    if (value == null || value.isEmpty) {
      return 'Year is required';
    }
    final yearRegex = RegExp(r'^\d{4}$');
    if (!yearRegex.hasMatch(value)) {
      return 'Enter a valid 4-digit year';
    }
    final year = int.tryParse(value);
    if (year == null || year < 1900 || year > DateTime.now().year) {
      return 'Enter a year between 1900 and ${DateTime.now().year}';
    }
    return null;
  }

  // File upload error handler
  static String? validateFileSize(File file, int maxSizeInMB) {
    final fileSize = file.lengthSync();
    if (fileSize > maxSizeInMB * 1024 * 1024) {
      return 'File is too large. Maximum size is $maxSizeInMB MB.';
    }
    return null;
  }

  // Show error dialog
  static void showErrorDialog(
      BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Show error snackbar
  static void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Show success snackbar
  static void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
