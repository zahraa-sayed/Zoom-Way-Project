

import 'dart:async';

import 'package:card_swiper/card_swiper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:zoom_way/data/api/driver_api_services.dart';
import 'package:zoom_way/screens/driver/ride_details_screen.dart';
import 'package:zoom_way/services/location_tracking_service.dart';
import 'package:zoom_way/widgets/notification_icon.dart';

class RideRequestScreen extends StatefulWidget {
  const RideRequestScreen({super.key});

  @override
  State<RideRequestScreen> createState() => _RideRequestScreenState();
}

class _RideRequestScreenState extends State<RideRequestScreen> {
  GoogleMapController? _mapController;
  Set<Polyline> _polylines = {};
  final DriverApiService _apiService = DriverApiService();
  List<Map<String, dynamic>> _rideRequests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRideRequests();
  }

  Future<void> _loadRideRequests() async {
    try {
      setState(() => _isLoading = true);
      final rides = await _apiService.getMyRides();
      setState(() {
        _rideRequests = rides;
        _isLoading = false;
      });

      if (rides.isNotEmpty) {
        _updateMapMarkers(rides.first);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading rides: $e')),
      );
    }
  }

  void _updateMapMarkers(Map<String, dynamic> ride) {
    if (_mapController != null) {
      final pickup = LatLng(
        double.parse(ride['pickup_location']['latitude'].toString()),
        double.parse(ride['pickup_location']['longitude'].toString()),
      );
      final dropoff = LatLng(
        double.parse(ride['dropoff_location']['latitude'].toString()),
        double.parse(ride['dropoff_location']['longitude'].toString()),
      );

      setState(() {
        _polylines = {
          Polyline(
            polylineId: const PolylineId('route'),
            points: [pickup, dropoff],
            color: Colors.blue,
            width: 5,
          ),
        };
      });

      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(
              pickup.latitude < dropoff.latitude
                  ? pickup.latitude
                  : dropoff.latitude,
              pickup.longitude < dropoff.longitude
                  ? pickup.longitude
                  : dropoff.longitude,
            ),
            northeast: LatLng(
              pickup.latitude > dropoff.latitude
                  ? pickup.latitude
                  : dropoff.latitude,
              pickup.longitude > dropoff.longitude
                  ? pickup.longitude
                  : dropoff.longitude,
            ),
          ),
          50,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_rideRequests.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('No ride requests available')),
      );
    }

    final currentRide = _rideRequests[0];

    final pickup = LatLng(
      double.parse(currentRide['pickup_location']['latitude'].toString()),
      double.parse(currentRide['pickup_location']['longitude'].toString()),
    );
    final dropoff = LatLng(
      double.parse(currentRide['dropoff_location']['latitude'].toString()),
      double.parse(currentRide['dropoff_location']['longitude'].toString()),
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Ride Requests'),
        actions: const [
          NotificationIconWidget(),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: pickup,
              zoom: 14,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
              _updateMapMarkers(currentRide);
            },
            polylines: _polylines,
            markers: {
              Marker(
                markerId: const MarkerId('pickup'),
                position: pickup,
                icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueGreen),
              ),
              Marker(
                markerId: const MarkerId('dropoff'),
                position: dropoff,
                icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueRed),
              ),
            },
          ),
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Container(
              height: 0.45.sh, // Adjusted the height for better visibility
              child: Swiper(
                itemBuilder: (context, index) {
                  final currentRide = _rideRequests[index];
                  final passenger = currentRide['passenger'] ?? {};
                  final rating =
                      passenger['rating'] ?? {'rate': 0, 'rate_count': 0};

                  return Container(
                    margin: const EdgeInsets.all(10),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 25.r,
                              backgroundImage:
                                  NetworkImage(passenger['image'] ?? ''),
                              child: passenger['image'] == null
                                  ? Icon(Icons.person,
                                      size: 24.sp, color: Colors.white)
                                  : null,
                            ),
                            SizedBox(width: 15.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    passenger['name'] ?? 'Unknown',
                                    style: TextStyle(
                                      fontSize: 18.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Row(
                                    children: [
                                      Icon(Icons.star,
                                          size: 16.sp, color: Colors.amber),
                                      Text(
                                        ' ${rating['rate'] ?? '4.9'}',
                                        style: TextStyle(fontSize: 14.sp),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.message,
                                      size: 24.sp, color: Colors.blue),
                                  onPressed: () {},
                                ),
                                IconButton(
                                  icon: Icon(Icons.phone,
                                      size: 24.sp, color: Colors.green),
                                  onPressed: () {},
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 15.h),
                        Row(
                          children: [
                            for (var i = 0; i < 3; i++)
                              Padding(
                                padding: EdgeInsets.only(right: 8.w),
                                child: CircleAvatar(
                                  radius: 15.r,
                                  backgroundColor: Colors.grey[300],
                                ),
                              ),
                            Text(
                              '${passenger['recommended_count'] ?? '25'} Recommended',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14.sp,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildTripDetail(
                              Icons.directions_car,
                              'DISTANCE',
                              '${currentRide['distance'] ?? '0.2'} km',
                            ),
                            _buildTripDetail(
                              Icons.access_time,
                              'TIME',
                              '${currentRide['duration'] ?? '2'} min',
                            ),
                            _buildTripDetail(
                              Icons.attach_money,
                              'PRICE',
                              '\$${currentRide['fare'] ?? '25.00'}',
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 45.h,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RideDetailsScreen(
                                      rideDetails: currentRide),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF33B9A0),
                              padding: EdgeInsets.symmetric(vertical: 15.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                            ),
                            child: Text(
                              'Confirm',
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                itemCount: _rideRequests.length,
                onIndexChanged: (index) {
                  _updateMapMarkers(_rideRequests[index]);
                },
                loop: false,
                viewportFraction: 0.85,
              ),
            ),
          )
        ],
      ),
    );
  }
}

Widget _buildTripDetail(IconData icon, String title, String value) {
  return Column(
    children: [
      Icon(icon, size: 24.sp, color: Colors.grey),
      SizedBox(height: 5.h),
      Text(
        title,
        style: TextStyle(
          fontSize: 12.sp,
          color: Colors.grey[600],
          fontWeight: FontWeight.w500,
        ),
      ),
      SizedBox(height: 5.h),
      Text(
        value,
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
    ],
  );
}
