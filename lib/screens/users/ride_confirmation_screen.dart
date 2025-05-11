import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shimmer/shimmer.dart';
import 'package:zoom_way/data/api/passengers_api_service.dart';
import 'package:zoom_way/screens/users/ride_share_screen.dart';

class RideConfirmationScreen extends StatefulWidget {
  final double pickupLat;
  final double pickupLng;
  final double dropoffLat;
  final double dropoffLng;
  final String dropoffName;
  final int rideId;
  final String passengerId;

  const RideConfirmationScreen({
    super.key,
    required this.pickupLat,
    required this.pickupLng,
    required this.dropoffLat,
    required this.dropoffLng,
    required this.dropoffName,
    required this.rideId,
    required this.passengerId,
  });

  @override
  State<RideConfirmationScreen> createState() => _RideConfirmationScreenState();
}

class _RideConfirmationScreenState extends State<RideConfirmationScreen> {
  late GoogleMapController _mapController;
  final Set<Polyline> _polylines = {};
  final Set<Marker> _markers = {};
  late LatLng _pickupLocation;
  late LatLng _dropoffLocation;
  LatLng? _currentDriverLocation;
  Timer? _locationUpdateTimer;

  List<Map<String, dynamic>> _bids = [];
  bool _isLoadingBids = true;
  Timer? _bidFetchTimer;
  int _selectedBidIndex = -1;

  @override
  void initState() {
    super.initState();
    _pickupLocation = LatLng(widget.pickupLat, widget.pickupLng);
    _dropoffLocation = LatLng(widget.dropoffLat, widget.dropoffLng);
    _initializeMap();
    _startBidFetching();
  }

  @override
  void dispose() {
    _bidFetchTimer?.cancel();
    _locationUpdateTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  void _initializeMap() {
    _markers.add(Marker(
      markerId: const MarkerId('pickup'),
      position: _pickupLocation,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      infoWindow: InfoWindow(title: 'Pickup Point'),
    ));

    _markers.add(Marker(
      markerId: const MarkerId('dropoff'),
      position: _dropoffLocation,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      infoWindow: InfoWindow(title: widget.dropoffName),
    ));

    _polylines.add(Polyline(
      polylineId: const PolylineId('route'),
      points: [_pickupLocation, _dropoffLocation],
      color: Colors.blue,
      width: 4,
    ));
  }

  void _startBidFetching() {
    _fetchBids();
    _bidFetchTimer = Timer.periodic(const Duration(seconds: 20), (timer) {
      if (_bids.isEmpty) {
        _fetchBids();
      }
    });
  }

  Future<void> _fetchBids() async {
    if (!mounted) return;

    setState(() => _isLoadingBids = true);

    try {
      final bids = await ApiService.getRideBids(widget.rideId);

      if (mounted) {
        setState(() {
          _bids = bids?.map((bid) {
                if (bid['driver'] != null) {
                  try {
                    final driver = bid['driver'];
                    if (driver['rating'] != null) {
                      final ratingData = json.decode(driver['rating']);
                      driver['parsed_rating'] =
                          ratingData['rate']?.toString() ?? '0.0';
                    }
                    if (driver['location'] != null) {
                      final location = json.decode(driver['location']);
                      driver['current_lat'] = location['latitude'];
                      driver['current_lng'] = location['longitude'];
                    }
                  } catch (e) {
                    debugPrint('Error parsing driver data: $e');
                  }
                }
                return bid;
              }).toList() ??
              [];
          _isLoadingBids = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingBids = false);
      }
    }
  }

  void _startDriverTracking(int bidIndex) {
    setState(() {
      _selectedBidIndex = bidIndex;
    });

    // Simulate driver movement (in a real app, this would come from your backend)
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!mounted || _selectedBidIndex == -1) {
        timer.cancel();
        return;
      }

      final driver = _bids[_selectedBidIndex]['driver'];
      if (driver['current_lat'] == null || driver['current_lng'] == null) {
        return;
      }

      // Simulate movement towards destination
      final currentLat = driver['current_lat'] as double;
      final currentLng = driver['current_lng'] as double;
      final latDiff = (_dropoffLocation.latitude - currentLat) / 10;
      final lngDiff = (_dropoffLocation.longitude - currentLng) / 10;

      setState(() {
        _currentDriverLocation = LatLng(
          currentLat + latDiff,
          currentLng + lngDiff,
        );

        // Update the driver marker
        _markers.removeWhere((m) => m.markerId.value == 'driver');
        _markers.add(Marker(
          markerId: const MarkerId('driver'),
          position: _currentDriverLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: InfoWindow(title: 'Driver ${driver['name']}'),
          rotation: _calculateBearing(
            _currentDriverLocation!,
            _dropoffLocation,
          ),
        ));

        // Update the polyline to show driver's route
        _polylines.removeWhere((p) => p.polylineId.value == 'driver_route');
        _polylines.add(Polyline(
          polylineId: const PolylineId('driver_route'),
          points: [_currentDriverLocation!, _dropoffLocation],
          color: Colors.green,
          width: 3,
          patterns: [PatternItem.dash(10), PatternItem.gap(5)],
        ));
      });

      // Center map on driver location
      _mapController.animateCamera(
        CameraUpdate.newLatLng(_currentDriverLocation!),
      );
    });
  }

  double _calculateBearing(LatLng begin, LatLng end) {
    final lat1 = begin.latitude * pi / 180;
    final lon1 = begin.longitude * pi / 180;
    final lat2 = end.latitude * pi / 180;
    final lon2 = end.longitude * pi / 180;

    final dLon = lon2 - lon1;
    final y = sin(dLon) * cos(lat2);
    final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
    final bearing = atan2(y, x);

    return (bearing * 180 / pi + 360) % 360;
  }

  Widget _buildBidsList() {
    if (_isLoadingBids) {
      return Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: 3,
          itemBuilder: (context, index) => Container(
            width: 300,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const SizedBox(), // Placeholder
          ),
        ),
      );
    }

    if (_bids.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('No bids available yet',
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _fetchBids,
              child: const Text('Retry Now'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[200],
                foregroundColor: Colors.black,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemCount: _bids.length,
      itemBuilder: (context, index) => _buildBidCard(_bids[index], index),
    );
  }

  Widget _buildBidCard(Map<String, dynamic> bid, int index) {
    final driver = bid['driver'] ?? {};
    String rating = '0.0';
    if (driver['rating'] != null) {
      final ratingData = json.decode(driver['rating']);
      rating = ratingData['rate']?.toString() ?? '0.0';
    }

    final carModel = driver['car_model'] ?? 'Unknown';
    final licensePlate = driver['license_plate'] ?? 'Unknown';
    final phoneNumber = driver['phone_number'] ?? 'Unknown';

    return buildDriverCard(
      avatarUrl:
          'https://ui-avatars.com/api/?name=${driver['name'] ?? 'Driver'}&background=random',
      name: driver['name'] ?? 'Driver',
      rating: double.parse(rating),
      recommendedAvatars: driver['recommended_avatars'] ?? [],
      recommendedCount: driver['recommended_count'] ?? 0,
      distance: _calculateDistance(
          driver['latitude'] ?? 0.0, driver['longitude'] ?? 0.0),
      time: bid['estimated_time'] ?? 20,
      price: bid['fare'] ?? 200,
      carModel: carModel,
      licensePlate: licensePlate,
      phoneNumber: phoneNumber,
      onConfirm: () async {
        // Show loading dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );
        try {
          final response = await ApiService.chooseBid(widget.rideId, bid['id']);
          Navigator.pop(context); // Dismiss loading dialog

          if (response['success'] == true) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => RideRequestCard(
                  receiverId: int.tryParse(driver['id'].toString()) ?? 0,
                  senderId: int.tryParse(widget.passengerId.toString()) ?? 0,
                  dropoffLat: widget.dropoffLat,
                  dropoffLng: widget.dropoffLng,
                  rideId: widget.rideId,
                  driverName: driver['name'] ?? 'Driver',
                  driverRating: double.parse(rating),
                  distance: _calculateDistance(
                    driver['latitude'] ?? 0.0,
                    driver['longitude'] ?? 0.0,
                  ),
                  time: bid['estimated_time'] ?? 20,
                  price: bid['fare'] ?? 200,
                  pickupAddress:
                      'Current Location', // You might want to get this from somewhere
                  dropoffAddress: widget.dropoffName,
                  carModel: driver['car_model'] ?? 'Unknown',
                  licensePlate: driver['license_plate'] ?? 'Unknown',
                  phoneNumber: driver['phone_number'] ?? 'Unknown',
                ),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(response['message'] ?? 'Failed to choose bid.'),
              ),
            );
          }
        } catch (e) {
          Navigator.pop(context); // Dismiss loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('An error occurred. Please try again.')),
          );
        }
      },
    );
  }

  double _calculateDistance(double lat, double lng) {
    const R = 6371; // Earth's radius in km
    final dLat = (_pickupLocation.latitude - lat) * (pi / 180);
    final dLng = (_pickupLocation.longitude - lng) * (pi / 180);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat * (pi / 180)) *
            cos(_pickupLocation.latitude * (pi / 180)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _calculateTime(double lat, double lng) {
    const R = 6371; // Earth's radius in km
    final dLat = (_pickupLocation.latitude - lat) * (pi / 180);
    final dLng = (_pickupLocation.longitude - lng) * (pi / 180);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat * (pi / 180)) *
            cos(_pickupLocation.latitude * (pi / 180)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    final distance = R * c;
    return distance / 1000 * 60; // Convert distance to minutes
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _pickupLocation,
              zoom: 14,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
              _mapController.animateCamera(
                CameraUpdate.newLatLngBounds(
                  LatLngBounds(
                    southwest: LatLng(
                      min(_pickupLocation.latitude, _dropoffLocation.latitude),
                      min(_pickupLocation.longitude,
                          _dropoffLocation.longitude),
                    ),
                    northeast: LatLng(
                      max(_pickupLocation.latitude, _dropoffLocation.latitude),
                      max(_pickupLocation.longitude,
                          _dropoffLocation.longitude),
                    ),
                  ),
                  50,
                ),
              );
            },
            polylines: _polylines,
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Available Drivers',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 280,
                    child: _buildBidsList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildDriverCard({
    required String avatarUrl,
    required String name,
    required double rating,
    required List<String> recommendedAvatars,
    required int recommendedCount,
    required double distance,
    required int time,
    required double price,
    required String carModel,
    required String licensePlate,
    required String phoneNumber,
    required VoidCallback onConfirm,
  }) {
    return Container(
      width: 300,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top Row: Avatar, Name, Rating, Chat, Call
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: NetworkImage(avatarUrl),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        Text(rating.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 14)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Recommended Row
          Row(
            children: [
              ...List.generate(
                recommendedAvatars.length,
                (i) => Padding(
                  padding: EdgeInsets.only(left: i == 0 ? 0 : -8),
                  child: CircleAvatar(
                    radius: 12,
                    backgroundImage: NetworkImage(recommendedAvatars[i]),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('$recommendedCount Recommended',
                  style: const TextStyle(fontSize: 13)),
            ],
          ),
          SizedBox(height: 20.h),
          // Car, Distance, Time, Price
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              const Icon(Icons.directions_car, size: 24),
              Column(
                children: [
                  const Text('DISTANCE',
                      style: TextStyle(fontSize: 11, color: Colors.grey)),
                  Text('${distance.toStringAsFixed(1)} km',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
              Column(
                children: [
                  const Text('TIME',
                      style: TextStyle(fontSize: 11, color: Colors.grey)),
                  Text('$time min',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
              Column(
                children: [
                  const Text('PRICE',
                      style: TextStyle(fontSize: 11, color: Colors.grey)),
                  Text('\$${price.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
            ],
          ),
          SizedBox(height: 35.h),
          // Confirm Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF21B573),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onPressed: onConfirm,
              child: const Text('Confirm',
                  style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
