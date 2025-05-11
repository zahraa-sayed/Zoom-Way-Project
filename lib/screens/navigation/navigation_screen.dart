import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:zoom_way/services/navigation_service.dart';

class NavigationScreen extends StatefulWidget {
  final LatLng pickup;
  final LatLng destination;

  const NavigationScreen({
    Key? key,
    required this.pickup,
    required this.destination,
  }) : super(key: key);

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  final NavigationService _navigationService = NavigationService();
  GoogleMapController? _mapController;
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};
  String _nextInstruction = '';
  double _remainingDistance = 0;
  int _remainingTime = 0;

  @override
  void initState() {
    super.initState();
    _initializeNavigation();
  }

  Future<void> _initializeNavigation() async {
    await _navigationService.initialize(apiKey: "AIzaSyBY2pivmzKyBmo224QdJbizGLTFrNUZ2UA");
    _setupRoute();
    _setupLocationListener();
  }

  void _setupRoute() async {
    try {
      final route =
          await _navigationService.getRoute(widget.pickup, widget.destination);
      setState(() {
        _polylines = {
          Polyline(
            polylineId: const PolylineId('route'),
            points: route,
            color: Colors.blue,
            width: 5,
          ),
        };
        _markers = {
          Marker(
            markerId: const MarkerId('pickup'),
            position: widget.pickup,
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueGreen),
          ),
          Marker(
            markerId: const MarkerId('destination'),
            position: widget.destination,
            icon:
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          ),
        };
      });
    } catch (e) {
      print('Error setting up route: $e');
    }
  }

  void _setupLocationListener() {
    _navigationService.locationStream.listen((position) {
      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(position.latitude, position.longitude),
              zoom: 15,
            ),
          ),
        );
        _updateNavigationInfo(position);
      }
    });
  }

  void _updateNavigationInfo(Position position) {
    // Update next instruction, remaining distance, and time
    // This would be implemented based on the current position and route
    setState(() {
      _nextInstruction = 'Turn right in 200m';
      _remainingDistance = 5.2;
      _remainingTime = 15;
    });
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
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _nextInstruction,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Text('${_remainingDistance.toStringAsFixed(1)} km'),
                        Text('$_remainingTime min'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              onPressed: () {
                // Emergency button functionality
              },
              backgroundColor: Colors.red,
              child: const Icon(Icons.warning),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _navigationService.dispose();
    super.dispose();
  }
}
