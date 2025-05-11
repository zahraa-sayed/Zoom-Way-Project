import 'package:google_maps_flutter/google_maps_flutter.dart';

class DeliveryStatus {
  final String status;
  final String? message;
  final List<LatLng>? polylinePoints;
  final double? estimatedArrivalTime;
  final double? distanceRemaining;

  DeliveryStatus({
    required this.status,
    this.message,
    this.polylinePoints,
    this.estimatedArrivalTime,
    this.distanceRemaining,
  });

  factory DeliveryStatus.initial() {
    return DeliveryStatus(
      status: 'Initializing',
      message: 'Preparing delivery tracking...',
    );
  }

  DeliveryStatus copyWith({
    String? status,
    String? message,
    List<LatLng>? polylinePoints,
    double? estimatedArrivalTime,
    double? distanceRemaining,
  }) {
    return DeliveryStatus(
      status: status ?? this.status,
      message: message ?? this.message,
      polylinePoints: polylinePoints ?? this.polylinePoints,
      estimatedArrivalTime: estimatedArrivalTime ?? this.estimatedArrivalTime,
      distanceRemaining: distanceRemaining ?? this.distanceRemaining,
    );
  }
}
