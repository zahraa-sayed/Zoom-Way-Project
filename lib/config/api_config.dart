class ApiConfig {
  // Replace this with your actual API key after enabling billing
  static const String googleMapsApiKey = 'AIzaSyDjz4gkb5J7ytJJL8OYCRoYbFNjYGcX2Jg';

  // Base URLs
  static const String baseUrl =
      'https://api.example.com'; // Replace with your actual base URL

  // API Endpoints
  static const String directionsEndpoint =
      'https://maps.googleapis.com/maps/api/directions/json';
  static const String geocodingEndpoint =
      'https://maps.googleapis.com/maps/api/geocode/json';

  // Other configuration
  static const int locationUpdateInterval = 3; // seconds
  static const double arrivalThreshold = 100.0; // meters
  static const double routeDeviationThreshold = 200.0; // meters
}
