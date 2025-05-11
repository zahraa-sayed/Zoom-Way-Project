import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:convert';

import 'package:zoom_way/data/api/driver_api_services.dart';

import 'package:zoom_way/screens/driver/active_ride_screen.dart';
import 'package:zoom_way/services/maps_service.dart';
import 'package:geolocator/geolocator.dart';

class RideDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> rideDetails;

  const RideDetailsScreen({
    Key? key,
    required this.rideDetails,
  }) : super(key: key);

  @override
  State<RideDetailsScreen> createState() => _RideDetailsScreenState();
}

class _RideDetailsScreenState extends State<RideDetailsScreen> {
  GoogleMapController? _mapController;
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};
  bool _isLoading = false;
  Position? _currentPosition;
  final TextEditingController _priceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _initializeMap() async {
    final pickupLocation = widget.rideDetails['pickup_location'];
    final dropoffLocation = widget.rideDetails['dropoff_location'];
    debugPrint(
        "pickupLocation" + jsonEncode(widget.rideDetails['pickup_location']));
    debugPrint(
        "dropoffLocation" + jsonEncode(widget.rideDetails['dropoff_location']));
    final routePoints = await MapsService.getRoutePoints(
        LatLng(
          double.parse(pickupLocation['latitude'].toString()),
          double.parse(pickupLocation['longitude'].toString()),
        ),
        LatLng(
          double.parse(dropoffLocation['latitude'].toString()),
          double.parse(dropoffLocation['longitude'].toString()),
        ));

    setState(() {
      _polylines = {
        Polyline(
          polylineId: const PolylineId('route'),
          points: routePoints,
          color: Colors.blue,
          width: 5,
        ),
      };
      _markers = {
        Marker(
          markerId: const MarkerId('pickup'),
          position: LatLng(
            double.parse(pickupLocation['latitude'].toString()),
            double.parse(pickupLocation['longitude'].toString()),
          ),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
        Marker(
          markerId: const MarkerId('dropoff'),
          position: LatLng(
            double.parse(dropoffLocation['latitude'].toString()),
            double.parse(dropoffLocation['longitude'].toString()),
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      };
    });

    if (_currentPosition != null) {
      await _drawRoute(_getDriverLatLng(), _getPickupLocation(),
          color: Colors.blue);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map at the top
          Column(
            children: [
              Expanded(
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(
                      double.parse(widget.rideDetails['pickup_location']
                              ['latitude']
                          .toString()),
                      double.parse(widget.rideDetails['pickup_location']
                              ['longitude']
                          .toString()),
                    ),
                    zoom: 14,
                  ),
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                  polylines: _polylines,
                  markers: _markers,
                  mapType: MapType.normal,
                ),
              ),
              // Bottom sheet with ride details
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(20.r)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.directions_car, size: 24.sp),
                        SizedBox(width: 8.w),
                        Text(
                          'Just go',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '\$${widget.rideDetails['fare'] ?? '25.00'}',
                          style: TextStyle(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF33B9A0),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildPaymentOption(
                          icon: Icons.payment,
                          label: 'Payment',
                        ),
                        _buildPaymentOption(
                          icon: Icons.more_horiz,
                          label: 'Options',
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: TextField(
                        controller: _priceController,
                        keyboardType:
                            TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Enter your price',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.attach_money),
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    SizedBox(
                      width: double.infinity,
                      height: 50.h,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleRequest,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF33B9A0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : Text(
                                'Request',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Back button at top
          Positioned(
            top: MediaQuery.of(context).padding.top,
            left: 8.w,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption({
    required IconData icon,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, size: 24.sp),
        SizedBox(height: 4.h),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Future<void> _handleRequest() async {
    setState(() => _isLoading = true);

    try {
      final driverApiService = DriverApiService();
      final driverId = widget.rideDetails['driver_id']?.toString();

      debugPrint(
          "-----------------------------------driverId in detail-----------------------");
      debugPrint(driverId);
      debugPrint("id rideDetails" + widget.rideDetails['id'].toString());
      debugPrint("fare" + widget.rideDetails['fare'].toString());
      debugPrint('------------------------bride id--------------------');
      debugPrint(widget.rideDetails['id'].toString());
      final enteredPrice = double.tryParse(_priceController.text) ?? 25.00;
      final result = await driverApiService.createBid(
        int.parse(widget.rideDetails['id'].toString()),
        enteredPrice,
      );

      if (result['success']) {
        // Show loading dialog with countdown
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  SizedBox(height: 20.h),
                  const Text('Starting ride in...'),
                  StreamBuilder<int>(
                    stream: Stream.periodic(
                      const Duration(seconds: 1),
                      (i) => 60 - i,
                    ).take(61),
                    builder: (context, snapshot) {
                      return Text(
                        '${snapshot.data ?? 60} seconds',
                        style: const TextStyle(fontSize: 20),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );

        // Wait for 1 minute
        await Future.delayed(const Duration(seconds: 5));

        // Navigate to ActiveRideScreen
        if (!mounted) return;
        Navigator.of(context).pop();
        // Close dialog

        final rideDetails = Map<String, dynamic>.from(widget.rideDetails);
        if (rideDetails['pickup_location'] is String) {
          rideDetails['pickup_location'] =
              jsonDecode(rideDetails['pickup_location']);
          debugPrint("pickup_location" +
              jsonEncode(widget.rideDetails['pickup_location']));
        }
        if (rideDetails['dropoff_location'] is String) {
          rideDetails['dropoff_location'] =
              jsonDecode(rideDetails['dropoff_location']);
          debugPrint("dropoff_location" +
              jsonEncode(widget.rideDetails['dropoff_location']));
        }
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ActiveRideScreen(
              rideDetails: rideDetails,
              enteredPrice: enteredPrice,
            ),
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to create bid'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  LatLng _getPickupLocation() {
    final pickup = widget.rideDetails['pickup_location'];
    return LatLng(
      double.parse(pickup['latitude'].toString()),
      double.parse(pickup['longitude'].toString()),
    );
  }

  LatLng _getDriverLatLng() {
    return LatLng(
      _currentPosition?.latitude ?? 0,
      _currentPosition?.longitude ?? 0,
    );
  }

  Future<void> _getCurrentLocation() async {
    try {
      _currentPosition = await Geolocator.getCurrentPosition();
      setState(() {});
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  Future<void> _drawRoute(LatLng from, LatLng to,
      {required Color color}) async {
    // You need to implement route fetching logic here, for example:
    // final routePoints = await MapsService.getRoutePoints(from, to);
    // setState(() {
    //   _polylines.add(Polyline(
    //     polylineId: PolylineId('route'),
    //     points: routePoints,
    //     color: color,
    //     width: 5,
    //   ));
    // });
  }
}
