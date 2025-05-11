import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:card_swiper/card_swiper.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:zoom_way/data/api/driver_api_services.dart';

import 'package:zoom_way/screens/driver/active_ride_screen.dart';
import 'package:zoom_way/screens/driver/ride_details_screen.dart';
import 'package:zoom_way/services/maps_service.dart';
import 'package:zoom_way/widgets/notification_icon.dart';

class RideRequestScreen extends StatefulWidget {
  const RideRequestScreen({super.key});

  @override
  State<RideRequestScreen> createState() => _RideRequestScreenState();
}

class _RideRequestScreenState extends State<RideRequestScreen> {
  GoogleMapController? _mapController;
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};
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
        await _updateMapMarkersAndRoute(rides.first);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading rides: $e')),
      );
    }
  }

  Future<void> _updateMapMarkersAndRoute(Map<String, dynamic> ride) async {
    if (_mapController != null) {
      final pickup = LatLng(
        double.parse(ride['pickup_location']['latitude'].toString()),
        double.parse(ride['pickup_location']['longitude'].toString()),
      );
      final dropoff = LatLng(
        double.parse(ride['dropoff_location']['latitude'].toString()),
        double.parse(ride['dropoff_location']['longitude'].toString()),
      );

      // Get route points using MapsService
      final routePoints = await MapsService.getRoutePoints(pickup, dropoff);

      setState(() {
        _markers = {
          Marker(
            markerId: const MarkerId('pickup'),
            position: pickup,
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueGreen),
            infoWindow: const InfoWindow(title: 'Pickup Location'),
          ),
          Marker(
            markerId: const MarkerId('dropoff'),
            position: dropoff,
            icon:
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            infoWindow: const InfoWindow(title: 'Dropoff Location'),
          ),
        };

        _polylines = {
          Polyline(
            polylineId: const PolylineId('route'),
            points: routePoints,
            color: Colors.blue,
            width: 5,
            patterns: [
              PatternItem.dash(20.0),
              PatternItem.gap(10.0),
            ],
          ),
        };
      });

      // Animate camera to show the entire route
      if (routePoints.isNotEmpty) {
        final bounds = MapsService.getBoundsForPoints(routePoints);
        _mapController!.animateCamera(
          CameraUpdate.newLatLngBounds(bounds, 100),
        );
      }
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
              target: LatLng(
                double.parse(
                    currentRide['pickup_location']['latitude'].toString()),
                double.parse(
                    currentRide['pickup_location']['longitude'].toString()),
              ),
              zoom: 14,
            ),
            onMapCreated: (controller) async {
              _mapController = controller;
              await _updateMapMarkersAndRoute(currentRide);
            },
            polylines: _polylines,
            markers: _markers,
            mapType: MapType.normal,
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
                              radius: 30,
                              backgroundColor: Colors.grey[200],
                              backgroundImage: passenger['image'] != null &&
                                      passenger['image'].isNotEmpty
                                  ? NetworkImage(passenger['image'])
                                  : null,
                              child: passenger['image'] == null ||
                                      passenger['image'].isEmpty
                                  ? const Icon(Icons.person,
                                      size: 40, color: Colors.grey)
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
                            // Row(
                            //   mainAxisSize: MainAxisSize.min,
                            //   children: [
                            //     IconButton(
                            //       icon: Icon(Icons.message,
                            //           size: 24.sp, color: Colors.blue),
                            //       onPressed: () {},
                            //     ),
                            //     IconButton(
                            //       icon: Icon(Icons.phone,
                            //           size: 24.sp, color: Colors.green),
                            //       onPressed: () {},
                            //     ),
                            //   ],
                            // ),
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
                  _updateMapMarkersAndRoute(_rideRequests[index]);
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

Widget buildDriverCard({
  required String avatarUrl,
  required String name,
  required double rating,
  required List<String> recommendedAvatars,
  required int recommendedCount,
  required double distance,
  required int time,
  required double price,
  required VoidCallback onConfirm,
}) {
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
              radius: 30,
              backgroundColor: Colors.grey[200],
              backgroundImage: NetworkImage(avatarUrl),
              child: avatarUrl.isEmpty
                  ? const Icon(Icons.person, size: 40, color: Colors.grey)
                  : null,
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 16, color: Colors.amber),
                      Text(
                        ' ${rating.toStringAsFixed(1)}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            for (var i = 0; i < recommendedAvatars.length; i++)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: CircleAvatar(
                  radius: 15,
                  backgroundImage: NetworkImage(recommendedAvatars[i]),
                  backgroundColor: Colors.grey[300],
                ),
              ),
            Text(
              '$recommendedCount Recommended',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildTripDetail(Icons.directions_car, 'DISTANCE',
                '${distance.toStringAsFixed(1)} km'),
            _buildTripDetail(Icons.access_time, 'TIME', '$time min'),
            _buildTripDetail(
                Icons.attach_money, 'PRICE', '\$${price.toStringAsFixed(2)}'),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 45,
          child: ElevatedButton(
            onPressed: onConfirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF21B573),
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Confirm',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
