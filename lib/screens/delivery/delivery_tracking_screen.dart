import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:zoom_way/services/tracking_service.dart' hide DeliveryStatus;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:zoom_way/models/delivery_status.dart';

class DeliveryTrackingScreen extends StatefulWidget {
  final String rideId;
  final LatLng pickup;
  final LatLng destination;
  final String driverName;
  final String vehicleInfo;

  const DeliveryTrackingScreen({
    Key? key,
    required this.rideId,
    required this.pickup,
    required this.destination,
    required this.driverName,
    required this.vehicleInfo,
  }) : super(key: key);

  @override
  State<DeliveryTrackingScreen> createState() => _DeliveryTrackingScreenState();
}

class _DeliveryTrackingScreenState extends State<DeliveryTrackingScreen> {
  final TrackingService _trackingService = TrackingService();
  GoogleMapController? _mapController;
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};
  DeliveryStatus? _currentStatus;
  bool _isExpanded = false;
  BitmapDescriptor? _carIcon;
  CarMarkerData? _carData;
  bool _showDeviationAlert = false;

  @override
  void initState() {
    super.initState();
    _loadCarIcon();
    _initializeTracking();
  }

  Future<void> _loadCarIcon() async {
    _carIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(48, 48)),
      'assets/images/car_marker.png',
    );
  }

  Future<void> _initializeTracking() async {
    await _trackingService.initialize(
      apiKey: 'AIzaSyDjz4gkb5J7ytJJL8OYCRoYbFNjYGcX2Jg',
      rideId: widget.rideId,
      pickup: widget.pickup,
      destination: widget.destination,
    );
    _setupMap();
    _setupListeners();
  }

  void _setupMap() {
    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('pickup'),
          position: widget.pickup,
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
        Marker(
          markerId: const MarkerId('destination'),
          position: widget.destination,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      };
    });
  }

  void _setupListeners() {
    _trackingService.carMarkerStream.listen((carData) {
      setState(() {
        _carData = carData;
        _updateCarMarker();
      });
    });

    _trackingService.deliveryStatusStream.listen((status) {
      setState(() {
        _currentStatus = status;
        _updatePolyline();
        _checkArrival();
      });
    });

    _trackingService.routeDeviationStream.listen((hasDeviated) {
      setState(() {
        _showDeviationAlert = hasDeviated;
      });
    });
  }

  void _updatePolyline() {
    if (_currentStatus?.polylinePoints == null) return;

    setState(() {
      _polylines = {
        Polyline(
          polylineId: const PolylineId('route'),
          points: _currentStatus!.polylinePoints!,
          color: _getPolylineColor(),
          width: 4,
        ),
      };
    });
  }

  Color _getPolylineColor() {
    switch (_trackingService.currentStatus) {
      case RideStatus.going_to_passenger:
        return Colors.blue;
      case RideStatus.in_progress:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  void _checkArrival() async {
    if (_carData == null) return;

    if (_trackingService.currentStatus == RideStatus.arrived_at_pickup) {
      _showArrivalDialog(
        'Arrived at pickup location',
        'Start the ride when the passenger is ready.',
        () {
          _trackingService.startRide();
          Navigator.pop(context);
        },
      );
    } else if (_trackingService.currentStatus == RideStatus.completed) {
      _showArrivalDialog(
        'Ride Completed',
        'You have reached the destination.',
        () {
          Navigator.pop(context);
          Navigator.pop(context); // Return to previous screen
        },
      );
    }
  }

  void _showArrivalDialog(
      String title, String message, VoidCallback onConfirm) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: onConfirm,
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _updateCarMarker() {
    if (_carData == null || _carIcon == null) return;

    setState(() {
      _markers.removeWhere((marker) => marker.markerId.value == 'car');
      _markers.add(
        Marker(
          markerId: const MarkerId('car'),
          position: _carData!.position,
          rotation: _carData!.rotation,
          icon: _carIcon!,
          anchor: const Offset(0.5, 0.5),
        ),
      );
    });

    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _carData!.position,
            zoom: 15,
            bearing: _carData!.rotation,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: widget.pickup,
              zoom: 15,
            ),
            onMapCreated: (controller) => _mapController = controller,
            polylines: _polylines,
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: false,
            rotateGesturesEnabled: false,
            tiltGesturesEnabled: false,
          ),
          if (_showDeviationAlert)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              right: 16,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: const Text(
                  'Route deviation detected. Recalculating...',
                  style: TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          // Speed Indicator
          if (_carData != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 80,
              right: 16,
              child: Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      '${(_carData!.speed * 3.6).toStringAsFixed(1)}',
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'km/h',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Top Bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: const CircleBorder(),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: () {
                    // Share tracking link
                  },
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: const CircleBorder(),
                  ),
                ),
              ],
            ),
          ),
          // Bottom Sheet
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: GestureDetector(
              onVerticalDragUpdate: (details) {
                setState(() {
                  _isExpanded = details.delta.dy < 0;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: _isExpanded ? 300.h : 200.h,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(20.r),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Handle
                    Container(
                      margin: EdgeInsets.symmetric(vertical: 8.h),
                      width: 40.w,
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                    // Driver Info
                    ListTile(
                      leading: CircleAvatar(
                        radius: 25.r,
                        backgroundColor: Colors.grey[200],
                        child: const Icon(Icons.person),
                      ),
                      title: Text(
                        widget.driverName,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        widget.vehicleInfo,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.phone),
                        onPressed: () {
                          // Call driver
                        },
                      ),
                    ),
                    const Divider(),
                    // Delivery Status
                    if (_currentStatus != null)
                      Padding(
                        padding: EdgeInsets.all(16.r),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _currentStatus!.status,
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_currentStatus!.message != null)
                              Text(
                                _currentStatus!.message!,
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: Colors.grey[600],
                                ),
                              ),
                            SizedBox(height: 16.h),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildInfoCard(
                                  icon: Icons.timer,
                                  title: 'ETA',
                                  value:
                                      '${_currentStatus!.estimatedArrivalTime?.toStringAsFixed(0) ?? "N/A"} min',
                                ),
                                _buildInfoCard(
                                  icon: Icons.route,
                                  title: 'Distance',
                                  value:
                                      '${_currentStatus!.distanceRemaining?.toStringAsFixed(1) ?? "N/A"} km',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.blue),
          SizedBox(height: 8.h),
          Text(
            title,
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _trackingService.dispose();
    super.dispose();
  }
}
