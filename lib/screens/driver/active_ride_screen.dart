import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zoom_way/data/api/driver_api_services.dart';
  import 'package:zoom_way/screens/driver/driver_chat_screen.dart';

import 'package:zoom_way/services/maps_service.dart';
import 'package:zoom_way/screens/driver/driver_home_screen.dart';

class ActiveRideScreen extends StatefulWidget {
  final Map<String, dynamic> rideDetails;
  final double enteredPrice;

  const ActiveRideScreen({
    Key? key,
    required this.rideDetails,
    required this.enteredPrice,
  }) : super(key: key);

  @override
  State<ActiveRideScreen> createState() => _ActiveRideScreenState();
}

class _ActiveRideScreenState extends State<ActiveRideScreen> {
  GoogleMapController? _mapController;
  final DriverApiService _apiService = DriverApiService();
  StreamSubscription<Position>? _positionStream;
  Timer? _autoCompleteTimer;
  bool _isTimerActive = true;

  final Set<Polyline> _polylines = {};
  final Map<MarkerId, Marker> _markers = {};
  Position? _currentPosition;
  String _currentStatus = 'pending';
  bool _isLocationPermissionGranted = false;
  bool _isLoading = true;
  String? _errorMessage;

  static const double arrivalThreshold =
      50; // Reduced threshold for better accuracy
  static const Duration statusCheckInterval = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    _initializeRide();
    _startAutoCompleteTimer();
  }

  Future<void> _initializeRide() async {
    try {
      setState(() => _isLoading = true);
      await _checkLocationPermission();

      if (_isLocationPermissionGranted) {
        _currentPosition = await Geolocator.getCurrentPosition();
        _setupInitialMarkers();
        await _updateRideStatus('driver_en_route');
        await _drawDriverToPickupRoute();
        _startLocationUpdates();
      }
    } catch (e) {
      setState(
          () => _errorMessage = 'Failed to initialize ride: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _checkLocationPermission() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final requestedPermission = await Geolocator.requestPermission();
        setState(() {
          _isLocationPermissionGranted =
              requestedPermission == LocationPermission.whileInUse ||
                  requestedPermission == LocationPermission.always;
        });
      } else {
        setState(() {
          _isLocationPermissionGranted =
              permission == LocationPermission.whileInUse ||
                  permission == LocationPermission.always;
        });
      }
    } catch (e) {
      setState(
          () => _errorMessage = 'Location permission error: ${e.toString()}');
    }
  }

  void _startLocationUpdates() {
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 10,
      ),
    ).listen((Position position) async {
      if (!mounted) return;

      setState(() => _currentPosition = position);
      _updateDriverMarker(position);
      _animateCameraToPosition(position);

      await _checkProximityAndUpdateStatus();
    });
  }

  Future<void> _checkProximityAndUpdateStatus() async {
    switch (_currentStatus) {
      case 'driver_en_route':
        if (await _isNearPickupLocation()) {
          await _handleArrivalAtPickup();
        }
        break;
      case 'driver_arrived':
      case 'trip_in_progress':
        if (await _isNearDropoffLocation()) {
          await _handleArrivalAtDestination();
        }
        break;
    }
  }

  Future<void> _handleArrivalAtPickup() async {
    await _updateRideStatus('driver_arrived');
    _showArrivalDialog();
  }

  Future<void> _startTrip() async {
    _clearRoutes();
    await _updateRideStatus('trip_in_progress');
    await _drawPickupToDropoffRoute();
  }

  Future<void> _handleArrivalAtDestination() async {
    await _updateRideStatus('trip_completed');
    _clearRoutes();
    _showCompletionDialog();
  }

  Future<bool> _isNearPickupLocation() async {
    return _isNearLocation(_getPickupLocation());
  }

  Future<bool> _isNearDropoffLocation() async {
    return _isNearLocation(_getDropoffLocation());
  }

  Future<bool> _isNearLocation(LatLng target) async {
    try {
      final distance = await Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        target.latitude,
        target.longitude,
      );
      return distance <= arrivalThreshold;
    } catch (e) {
      debugPrint('Error calculating distance: $e');
      return false;
    }
  }

  Future<void> _drawDriverToPickupRoute() async {
    await _drawRoute(
      _getDriverLatLng(),
      _getPickupLocation(),
      color: Colors.blue,
      polylineId: 'driver_to_pickup',
    );
  }

  Future<void> _drawPickupToDropoffRoute() async {
    await _drawRoute(
      _getPickupLocation(),
      _getDropoffLocation(),
      color: Colors.green,
      polylineId: 'pickup_to_dropoff',
    );
  }

  Future<void> _drawRoute(
    LatLng from,
    LatLng to, {
    required Color color,
    required String polylineId,
  }) async {
    try {
      final routePoints = await MapsService.getRoutePoints(from, to);
      if (!mounted) return;

      setState(() {
        _polylines
            .removeWhere((polyline) => polyline.polylineId.value == polylineId);
        _polylines.add(
          Polyline(
            polylineId: PolylineId(polylineId),
            points: routePoints,
            color: color,
            width: 5,
            patterns: [PatternItem.dash(20), PatternItem.gap(10)],
          ),
        );
      });

      _zoomToFitRoute(from, to);
    } catch (e) {
      debugPrint('Error drawing route: $e');
    }
  }

  void _clearRoutes() {
    setState(() => _polylines.clear());
  }

  void _setupInitialMarkers() {
    _markers.clear();

    // Driver marker
    _updateDriverMarker(_currentPosition!);

    // Pickup marker
    _markers[const MarkerId('pickup')] = Marker(
      markerId: const MarkerId('pickup'),
      position: _getPickupLocation(),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      infoWindow: const InfoWindow(title: 'Pickup Location'),
    );

    // Dropoff marker
    _markers[const MarkerId('dropoff')] = Marker(
      markerId: const MarkerId('dropoff'),
      position: _getDropoffLocation(),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      infoWindow: const InfoWindow(title: 'Dropoff Location'),
    );
  }

  void _updateDriverMarker(Position position) {
    setState(() {
      _markers[const MarkerId('driver')] = Marker(
        markerId: const MarkerId('driver'),
        position: LatLng(position.latitude, position.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: const InfoWindow(title: 'Your Location'),
      );
    });
  }

  void _animateCameraToPosition(Position position) {
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: 17,
          bearing: position.heading,
          tilt: 45,
        ),
      ),
    );
  }

  void _zoomToFitRoute(LatLng from, LatLng to) {
    final bounds = LatLngBounds(
      southwest: LatLng(
        from.latitude < to.latitude ? from.latitude : to.latitude,
        from.longitude < to.longitude ? from.longitude : to.longitude,
      ),
      northeast: LatLng(
        from.latitude > to.latitude ? from.latitude : to.latitude,
        from.longitude > to.longitude ? from.longitude : to.longitude,
      ),
    );
    _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
  }

  LatLng _getDriverLatLng() {
    return LatLng(
      _currentPosition?.latitude ?? 0,
      _currentPosition?.longitude ?? 0,
    );
  }

  LatLng _getPickupLocation() {
    try {
      final pickup = widget.rideDetails['pickup_location'];
      if (pickup is String) {
        final decoded = jsonDecode(pickup) as Map<String, dynamic>;
        return LatLng(decoded['latitude'], decoded['longitude']);
      } else if (pickup is Map) {
        return LatLng(pickup['latitude'], pickup['longitude']);
      }
    } catch (e) {
      debugPrint('Error parsing pickup location: $e');
    }
    return const LatLng(0, 0);
  }

  LatLng _getDropoffLocation() {
    try {
      final dropoff = widget.rideDetails['dropoff_location'];
      if (dropoff is String) {
        final decoded = jsonDecode(dropoff) as Map<String, dynamic>;
        return LatLng(decoded['latitude'], decoded['longitude']);
      } else if (dropoff is Map) {
        return LatLng(dropoff['latitude'], dropoff['longitude']);
      }
    } catch (e) {
      debugPrint('Error parsing dropoff location: $e');
    }
    return const LatLng(0, 0);
  }

  Future<void> _updateRideStatus(String status) async {
    try {
      final rideId =
          int.tryParse(widget.rideDetails['id']?.toString() ?? '0') ?? 0;
      final result = await _apiService.updateRideStatus(rideId, status);

      if (result['success'] == true && mounted) {
        setState(() => _currentStatus = status);

        if (status == 'completed') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => RatingScreen(
                passengerName:
                    widget.rideDetails['passenger']?['name'] ?? 'Passenger',
                passengerId:
                    widget.rideDetails['passenger']?['id']?.toString() ?? '',
                avatarUrl: widget.rideDetails['passenger']?['avatar'],
                rideId: widget.rideDetails['id'].toString(),
                driverId: widget.rideDetails['passenger_id'].toString(),
              ),
            ),
          );
        } else if (status == 'canceled') {
          _pauseTimer();
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const DriverHomeScreen()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      debugPrint('Error updating ride status: $e');
    }
  }

  void _showArrivalDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Arrived at Pickup'),
        content: const Text(
            'You have arrived at the pickup location. Please wait for the passenger.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _startTrip();
            },
            child: const Text('Start Trip'),
          ),
        ],
      ),
    );
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Trip Completed'),
        content: const Text('You have successfully completed the trip!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => RatingScreen(
                    passengerName:
                        widget.rideDetails['passenger']?['name'] ?? 'Passenger',
                    passengerId:
                        widget.rideDetails['passenger']?['id']?.toString() ??
                            '',
                    avatarUrl: widget.rideDetails['passenger']?['avatar'],
                    rideId: widget.rideDetails['id'].toString(),
                    driverId: widget.rideDetails['passenger_id'].toString(),
                  ),
                ),
              );
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _startAutoCompleteTimer() {
    _autoCompleteTimer = Timer(const Duration(minutes: 15), () {
      if (mounted && _currentStatus != 'canceled' && _isTimerActive) {
        _updateRideStatus('completed');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => RatingScreen(
              passengerName:
                  widget.rideDetails['passenger']?['name'] ?? 'Passenger',
              passengerId:
                  widget.rideDetails['passenger']?['id']?.toString() ?? '',
              avatarUrl: widget.rideDetails['passenger']?['avatar'],
              rideId: widget.rideDetails['id'].toString(),
              driverId: widget.rideDetails['passenger_id'].toString(),
            ),
          ),
        );
      }
    });
  }

  void _pauseTimer() {
    _isTimerActive = false;
    _autoCompleteTimer?.cancel();
  }

  void _resumeTimer() {
    _isTimerActive = true;
    _startAutoCompleteTimer();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _mapController?.dispose();
    _autoCompleteTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _initializeRide,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_isLocationPermissionGranted) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Location permission is required'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _checkLocationPermission,
                child: const Text('Grant Permission'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_currentPosition != null) {
            _animateCameraToPosition(_currentPosition!);
          }
        },
        child: const Icon(Icons.my_location),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _getPickupLocation(),
              zoom: 15,
            ),
            onMapCreated: (controller) => _mapController = controller,
            markers: Set<Marker>.of(_markers.values),
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
          ),

          // Status bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  _getStatusText(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),

          // Bottom info card
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildRideInfoCard(),
          ),
        ],
      ),
    );
  }

  String _getStatusText() {
    switch (_currentStatus) {
      case 'driver_en_route':
        return 'Driver En Route';
      case 'driver_arrived':
        return 'Driver Arrived';
      case 'trip_in_progress':
        return 'Trip In Progress';
      case 'trip_completed':
        return 'Trip Completed';
      default:
        return 'Active Ride';
    }
  }

  Widget _buildRideInfoCard() {
    final passenger =
        widget.rideDetails['passenger'] as Map<String, dynamic>? ?? {};
    final distance =
        (widget.rideDetails['distance'] as num?)?.toStringAsFixed(1) ?? '--';
    final fare = widget.enteredPrice.toStringAsFixed(2);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Passenger info
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: passenger['avatar'] != null
                    ? NetworkImage(passenger['avatar'] as String)
                    : null,
                child: passenger['avatar'] == null
                    ? const Icon(Icons.person, size: 32)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      passenger['name']?.toString() ?? 'Passenger',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          (passenger['rating']?['rate']?.toString() ?? '--'),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _buildActionButton(Icons.chat, const Color(0xFF33B9A0)),
              const SizedBox(width: 8),
              _buildActionButton(Icons.call, const Color(0xFF33B9A0)),
            ],
          ),
          const SizedBox(height: 18),

          // Location info
          _buildLocationInfo(),
          const SizedBox(height: 18),

          // Ride metrics
          _buildRideMetrics(distance, fare),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE6F7F4),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: color),
        onPressed: () async {
          final rideId = widget.rideDetails['id']?.toString();
          final passengerId = widget.rideDetails['passenger_id']?.toString();
          final prefs = await SharedPreferences.getInstance();
          final driverId = prefs.getString('driver_id');

          // Pause timer before navigating to chat
          _pauseTimer();
  debugPrint(
              "-----------------------------------driverId-----------------------");
          debugPrint(driverId);
          debugPrint(
              "-----------------------------------rideId-----------------------");
          debugPrint(rideId);
          debugPrint(
              "-----------------------------------passengerId-----------------------");
          debugPrint(passengerId);
          debugPrint(
              "-----------------------------------senderType-----------------------");
          debugPrint('driver');
          debugPrint(
              "-----------------------------------receiverType-----------------------");
          debugPrint(widget.rideDetails['passenger']?['name'] ?? 'Passenger');
          debugPrint(
              "------------------------------------------------------------------");
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DriverChatScreen(
                receiverType:
                    widget.rideDetails['passenger']?['name'] ?? 'Passenger',
                rideId: int.parse(rideId!),
                senderId: int.parse(driverId!),
                receiverId: int.parse(passengerId!),
                receiverName:
                    widget.rideDetails['passenger']?['name'] ?? 'Passenger',
                senderType: 'driver',
              ),
            ),
          ).then((_) {
            // Resume timer when returning from chat
            if (mounted) {
              _resumeTimer();
            }
          });
        },
      ),
    );
  }

  Widget _buildLocationInfo() {
    return Column(
      children: [
        Row(
          children: [
            const Icon(Icons.circle_outlined, color: Colors.green, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _currentPosition!.latitude.toString() +
                        " , " +
                        _currentPosition!.longitude.toString() ??
                    'Pickup location',
                style: const TextStyle(fontSize: 15),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.location_on, color: Colors.red, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                (widget.rideDetails['dropoff_location']?['longitude']
                                    ?.toString() ??
                                '') +
                            " , " +
                            (widget.rideDetails['dropoff_location']?['latitude']
                                    ?.toString() ??
                                '') !=
                        " , "
                    ? (widget.rideDetails['dropoff_location']?['longitude']
                                ?.toString() ??
                            '') +
                        " , " +
                        (widget.rideDetails['dropoff_location']?['latitude']
                                ?.toString() ??
                            '')
                    : 'Dropoff location',
                style: const TextStyle(fontSize: 15),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRideMetrics(String distance, String fare) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildMetricItem(Icons.directions_car, '$distance km'),
        _buildMetricItem(Icons.access_time, '-- min'),
        _buildMetricItem(Icons.attach_money, '\$$fare'),
      ],
    );
  }

  Widget _buildMetricItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class RatingScreen extends StatefulWidget {
  final String passengerName;
  final String passengerId;
  final String? avatarUrl;
  final String rideId;
  final String driverId;

  const RatingScreen({
    Key? key,
    required this.passengerName,
    required this.passengerId,
    required this.rideId,
    required this.driverId,
    this.avatarUrl,
  }) : super(key: key);

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  int _rating = 4;
  final TextEditingController _commentController = TextEditingController();
  final DriverApiService _apiService = DriverApiService();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final driverId = widget.driverId;
      final rideId = widget.rideId;

      if (driverId == null || rideId == null) {
        throw Exception('Missing required IDs');
      }

      final result = await _apiService.submitFeedback(
        rideId: int.parse(rideId),
        driverId: int.parse(driverId),
        passengerId: int.parse(widget.passengerId),
        driverRating: _rating.toDouble(),
        driverComments: _commentController.text,
      );

      if (result['success'] == true) {
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const DriverHomeScreen()),
            (route) => false,
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text(result['message'] ?? 'Failed to submit feedback')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF21B573),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: Colors.white),
        title: const Text('Rating', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundImage: widget.avatarUrl != null
                    ? NetworkImage(widget.avatarUrl!)
                    : null,
                child: widget.avatarUrl == null
                    ? const Icon(Icons.person, size: 40)
                    : null,
              ),
              const SizedBox(height: 12),
              Text(widget.passengerName,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18)),
              Text(widget.passengerId,
                  style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 18),
              const Text('How is your trip?',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
              const SizedBox(height: 8),
              const Text('Your feedback will help improve driving experience',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < _rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 36,
                    ),
                    onPressed: () {
                      setState(() {
                        _rating = index + 1;
                      });
                    },
                  );
                }),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _commentController,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Additional comments...',
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B5AFB),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _isSubmitting ? null : _submitFeedback,
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Submit Review',
                          style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
