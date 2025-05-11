import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../bloc/trip_state_bloc.dart';
import '../../domain/models/trip_state.dart';
import '../controllers/trip_controller.dart';

class TripMap extends StatefulWidget {
  final String googleMapsApiKey;
  final int rideId;
  final LatLng initialLocation;
  final LatLng pickupLocation;
  final LatLng destinationLocation;

  const TripMap({
    Key? key,
    required this.googleMapsApiKey,
    required this.rideId,
    required this.initialLocation,
    required this.pickupLocation,
    required this.destinationLocation,
  }) : super(key: key);

  @override
  State<TripMap> createState() => _TripMapState();
}

class _TripMapState extends State<TripMap> {
  GoogleMapController? _mapController;
  Set<Polyline> _polylines = {};
  late final TripController _tripController;
  String _eta = '';
  double _distance = 0.0;

  @override
  void initState() {
    super.initState();
    _tripController = TripController(
      googleMapsApiKey: widget.googleMapsApiKey,
      onStateChanged: _handleStateChanged,
      onRoutesChanged: _handleRoutesChanged,
      onETAUpdated: _handleETAUpdated,
    );

    // Start the trip immediately
    _tripController.startTrip(
      rideId: widget.rideId,
      driverLocation: widget.initialLocation,
      pickupLocation: widget.pickupLocation,
      destinationLocation: widget.destinationLocation,
    );
  }

  @override
  void dispose() {
    _tripController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _handleStateChanged(TripState newState) {
    context.read<TripStateBloc>().add(
          UpdateTripState(
            newState: newState,
            currentLocation: widget.initialLocation,
          ),
        );
  }

  void _handleRoutesChanged(Set<Polyline> routes) {
    setState(() {
      _polylines = routes;
    });
  }

  void _handleETAUpdated(String eta, double distance) {
    setState(() {
      _eta = eta;
      _distance = distance;
    });
  }

  void _onArrivedAtPickup() {
    _tripController.arrivedAtPickup(widget.rideId);
  }

  void _onStartRide() {
    _tripController.startRide(
      rideId: widget.rideId,
      currentLocation: widget.pickupLocation,
      destinationLocation: widget.destinationLocation,
    );
  }

  void _onCompleteTrip() {
    _tripController.completeTrip(widget.rideId);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: widget.initialLocation,
            zoom: 15,
          ),
          onMapCreated: (controller) {
            _mapController = controller;
          },
          polylines: _polylines,
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          zoomControlsEnabled: true,
          mapToolbarEnabled: true,
        ),
        // ETA and Distance Display
        if (_eta.isNotEmpty)
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Text('ETA',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(_eta),
                      ],
                    ),
                    Column(
                      children: [
                        const Text('Distance',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('${_distance.toStringAsFixed(1)} km'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        // Action Buttons
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: BlocBuilder<TripStateBloc, TripStateState>(
            builder: (context, state) {
              return Column(
                children: [
                  if (state.currentState == TripState.going_to_passenger)
                    ElevatedButton(
                      onPressed: _onArrivedAtPickup,
                      child: const Text('Arrived at Pickup'),
                    ),
                  if (state.currentState == TripState.arrived)
                    ElevatedButton(
                      onPressed: _onStartRide,
                      child: const Text('Start Ride'),
                    ),
                  if (state.currentState == TripState.in_progress)
                    ElevatedButton(
                      onPressed: _onCompleteTrip,
                      child: const Text('Complete Trip'),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
