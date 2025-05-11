import 'package:flutter/material.dart';

class ValidationErrorSnackbar {
  // Show a snackbar with validation errors
  static void show(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    // Dismiss any existing snackbars first
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    // Create and show the new snackbar
    final snackBar = SnackBar(
      content: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.redAccent,
      duration: duration,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      action: action,
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  // Show a snackbar with multiple validation errors
  static void showMultipleErrors(
    BuildContext context, {
    required Map<String, String?> errors,
    Duration duration = const Duration(seconds: 4),
  }) {
    // Filter out null errors and get valid error messages
    final validErrors = errors.entries
        .where((entry) => entry.value != null && entry.value!.isNotEmpty)
        .map((entry) => entry.value!)
        .toList();

    if (validErrors.isEmpty) return;

    // Show first error or combine errors
    final message = validErrors.length == 1
        ? validErrors.first
        : '${validErrors.first} (${validErrors.length - 1} more ${validErrors.length == 2 ? 'error' : 'errors'})';

    // Show snackbar with option to view all errors if multiple
    show(
      context,
      message: message,
      duration: duration,
      action: validErrors.length > 1
          ? SnackBarAction(
              label: 'View All',
              textColor: Colors.white,
              onPressed: () => _showAllErrors(context, validErrors),
            )
          : null,
    );
  }

  // Show a dialog with all validation errors
  static void _showAllErrors(BuildContext context, List<String> errors) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.redAccent),
            SizedBox(width: 12),
            Text('Validation Errors'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < errors.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("${i + 1}. ",
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      Expanded(child: Text(errors[i])),
                    ],
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
