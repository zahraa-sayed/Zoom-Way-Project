class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() {
    return 'ApiException: $message ${statusCode != null ? "(Status Code: $statusCode)" : ""}';
  }
}
