import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'dart:async';
import 'package:zoom_way/data/api/passengers_api_service.dart';
import 'package:zoom_way/screens/users/map_screen.dart';
import 'package:zoom_way/screens/users/rating_screen.dart';
import 'package:zoom_way/screens/users/chat_screen.dart';

class RideRequestCard extends StatefulWidget {
  const RideRequestCard({
    super.key,
    required this.dropoffLat,
    required this.dropoffLng,
    required this.rideId,
    required this.driverName,
    required this.driverRating,
    required this.distance,
    required this.time,
    required this.price,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.carModel,
    required this.licensePlate,
    required this.phoneNumber,
    required this.senderId,
    required this.receiverId,
  });
  final double dropoffLat;
  final double dropoffLng;
  final int rideId;
  final String driverName;
  final double driverRating;
  final double distance;
  final int time;
  final double price;
  final String pickupAddress;
  final String dropoffAddress;
  final String carModel;
  final String licensePlate;
  final String phoneNumber;
  final int senderId;
  final int receiverId;

  @override
  State<RideRequestCard> createState() => _RideRequestCardState();
}

class _RideRequestCardState extends State<RideRequestCard> {
  late GoogleMapController mapController;
  Position? currentPosition;
  Set<Marker> markers = {};
  Set<Polyline> polylines = {};
  List<LatLng> polylineCoordinates = [];
  PolylinePoints polylinePoints = PolylinePoints();
  StreamSubscription<Position>? positionStream;
  Timer? _locationCheckTimer;
  Timer? _autoCompleteTimer;
  bool _isTimerPaused = false;
  Duration _remainingTime = const Duration(minutes: 15);

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _startLocationUpdates();
    _startLocationCheckTimer();
    _startAutoCompleteTimer();
  }

  @override
  void dispose() {
    positionStream?.cancel();
    _locationCheckTimer?.cancel();
    _autoCompleteTimer?.cancel();
    super.dispose();
  }

  void _startLocationUpdates() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update every 10 meters
    );

    positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((Position position) {
      setState(() {
        currentPosition = position;
        _updateMap();
      });
    });
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }

    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      currentPosition = position;
      _updateMap();
    });
  }

  void _updateMap() {
    if (currentPosition != null) {
      // Update markers
      markers.clear();
      markers.add(
        Marker(
          markerId: const MarkerId('currentLocation'),
          position:
              LatLng(currentPosition!.latitude, currentPosition!.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );

      markers.add(
        Marker(
          markerId: const MarkerId('dropoffLocation'),
          position: LatLng(widget.dropoffLat, widget.dropoffLng),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );

      // Update camera position
      mapController.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(currentPosition!.latitude, currentPosition!.longitude),
        ),
      );

      // Update polyline
      _getPolyline();
    }
  }

  void _getPolyline() async {
    if (currentPosition != null) {
      PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        'AIzaSyDjz4gkb5J7ytJJL8OYCRoYbFNjYGcX2Jg', // Replace with your API key
        PointLatLng(currentPosition!.latitude, currentPosition!.longitude),
        PointLatLng(widget.dropoffLat, widget.dropoffLng),
        travelMode: TravelMode.driving,
      );

      if (result.points.isNotEmpty) {
        polylineCoordinates.clear();
        result.points.forEach((PointLatLng point) {
          polylineCoordinates.add(LatLng(point.latitude, point.longitude));
        });

        setState(() {
          polylines.clear();
          polylines.add(
            Polyline(
              polylineId: const PolylineId('route'),
              points: polylineCoordinates,
              color: Colors.blue,
              width: 5,
            ),
          );
        });
      }
    }
  }

  void _startLocationCheckTimer() {
    _locationCheckTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _checkIfReachedDestination();
    });
  }

  void _checkIfReachedDestination() async {
    if (currentPosition == null) return;

    final distance = Geolocator.distanceBetween(
      currentPosition!.latitude,
      currentPosition!.longitude,
      widget.dropoffLat,
      widget.dropoffLng,
    );

    if (distance < 100) {
      _updateRideStatus('completed');
      _locationCheckTimer?.cancel();
    }
  }

  void _startAutoCompleteTimer() {
    _autoCompleteTimer = Timer(_remainingTime, () {
      if (mounted && !_isTimerPaused) {
        _updateRideStatus('completed');
      }
    });
  }

  void _pauseTimer() {
    if (_autoCompleteTimer != null && !_isTimerPaused) {
      _isTimerPaused = true;
      _remainingTime = Duration(milliseconds: _autoCompleteTimer!.tick);
      _autoCompleteTimer!.cancel();
    }
  }

  void _resumeTimer() {
    if (_isTimerPaused) {
      _isTimerPaused = false;
      _startAutoCompleteTimer();
    }
  }

  Future<void> _updateRideStatus(String status) async {
    try {
      final success = await ApiService.updateRideStatus(
        rideId: widget.rideId,
        status: status,
      );

      if (success) {
        if (status == 'completed') {
          // Navigate to rating screen
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => RatingScreen(
                  driverName: widget.driverName,
                  driverAvatarUrl:
                      'https://ui-avatars.com/api/?name=${widget.driverName}&background=random',
                  driverCarInfo: '${widget.carModel} - ${widget.licensePlate}',
                  rideId: widget.rideId,
                  driverId: widget.receiverId,
                ),
              ),
            );
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Ride completed successfully!')),
            );
          }
        } else if (status == 'canceled') {
          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const MapScreen()),
              (route) => false,
            );
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Ride canceled successfully!')),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update ride status')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An error occurred. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          Expanded(
            child: currentPosition == null
                ? const Center(child: CircularProgressIndicator())
                : GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(currentPosition!.latitude,
                          currentPosition!.longitude),
                      zoom: 14,
                    ),
                    markers: markers,
                    polylines: polylines,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    onMapCreated: (GoogleMapController controller) {
                      mapController = controller;
                    },
                  ),
          ),
          Container(
            width: MediaQuery.of(context).size.width * 0.9,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Route information
                _buildRouteSection(),

                // Divider
                const Divider(height: 1, thickness: 1),

                // Driver information
                _buildDriverSection(),

                // Divider
                const Divider(height: 1, thickness: 1),

                // Ride details
                _buildRideDetailsSection(),

                // Cancel button
                _buildCancelButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "target location ",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.dropoffAddress,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Driver avatar and info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.driverName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      widget.driverRating.toStringAsFixed(1),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.carModel} • ${widget.licensePlate}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.phone, color: Colors.grey[600], size: 16),
                    const SizedBox(width: 4),
                    Text(
                      widget.phoneNumber,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    const SizedBox(width: 16),
                    // Chat icon
                    GestureDetector(
                      onTap: () {
                        _pauseTimer();
                        
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(
                              rideId: widget.rideId,
                              senderId: widget.senderId,
                              receiverId: widget.receiverId,
                              senderType: "passenger",
                              receiverType: "driver",
                              receiverName: widget.driverName,
                            ),
                          ),
                        ).then((_) => _resumeTimer());
                      },
                      child:
                          Icon(Icons.chat, color: Colors.blue[600], size: 20),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Driver image
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[200],
              image: DecorationImage(
                image: NetworkImage(
                    'https://ui-avatars.com/api/?name=${widget.driverName}&background=random'),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRideDetailsSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              const Text(
                'DISTANCE',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              Text(
                '${widget.distance.toStringAsFixed(1)} km',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Column(
            children: [
              const Text(
                'TIME',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              Text(
                '${widget.time} min',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Column(
            children: [
              const Text(
                'PRICE',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              Text(
                '\$${widget.price.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCancelButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.red,
            side: const BorderSide(color: Colors.red),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Cancel Ride'),
                content:
                    const Text('Are you sure you want to cancel this ride?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('No'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _updateRideStatus('canceled');
                    },
                    child: const Text('Yes'),
                  ),
                ],
              ),
            );
          },
          child: const Text(
            'Cancel Request',
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}
