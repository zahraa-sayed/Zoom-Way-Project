import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

import 'ride_confirmation_screen.dart';
import 'package:zoom_way/data/api/passengers_api_service.dart';

class SelectAddressScreen extends StatefulWidget {
  const SelectAddressScreen({super.key});

  @override
  State<SelectAddressScreen> createState() => _SelectAddressScreenState();
}

class _SelectAddressScreenState extends State<SelectAddressScreen> {
  final TextEditingController destinationController = TextEditingController();
  final FocusNode destinationFocusNode = FocusNode();

  geo.Position? currentPosition;
  String pickupAddress = '';
  bool isLoadingLocation = true;

  List<Map<String, dynamic>> filteredPlaces = [];

  final List<Map<String, dynamic>> fallbackPlaces = [
    // ======= Cairo =======
    {"name": "Cairo Tower", "lat": 30.0459, "lng": 31.2243},
    {"name": "The Egyptian Museum", "lat": 30.0478, "lng": 31.2336},
    {"name": "Khan El Khalili", "lat": 30.0477, "lng": 31.2627},
    {"name": "Al-Azhar Mosque", "lat": 30.0444, "lng": 31.2625},
    {"name": "The Hanging Church", "lat": 30.0063, "lng": 31.2305},
    {"name": "Tahrir Square", "lat": 30.0444, "lng": 31.2357},
    {"name": "Cairo Citadel", "lat": 30.0280, "lng": 31.2614},
    {"name": "Giza Pyramids", "lat": 29.9792, "lng": 31.1342},
    {"name": "Cairo International Airport", "lat": 30.1219, "lng": 31.4056},
    {"name": "City Stars Mall", "lat": 30.0721, "lng": 31.3455},
    {"name": "Zamalek District", "lat": 30.0614, "lng": 31.2196},
    {"name": "Mohamed Naguib Metro Station", "lat": 30.0635, "lng": 31.2479},

    // ======= Fayoum =======
    {"name": "Fayoum City", "lat": 29.3084, "lng": 30.8428},
    {"name": "Lake Qarun", "lat": 29.5113, "lng": 30.6298},
    {"name": "Wadi El Rayan", "lat": 29.2206, "lng": 30.5886},
    {"name": "Tunis Village", "lat": 29.4514, "lng": 30.6580},
    {
      "name": "Valley of the Whales (Wadi Al-Hitan)",
      "lat": 29.2516,
      "lng": 30.3725
    },
    {"name": "Fayoum University", "lat": 29.3100, "lng": 30.8400},
    {"name": "Fayoum Stadium", "lat": 29.3167, "lng": 30.8333},
    {"name": "Qasr Qarun Temple", "lat": 29.4785, "lng": 30.4971},
    {"name": "Dimai (Soknopaiou Nesos)", "lat": 29.5112, "lng": 30.7273},
    {"name": "Medinet Madi", "lat": 29.2063, "lng": 30.4565},
    {"name": "Magic Lake", "lat": 29.2347, "lng": 30.5120},
    {"name": "Rayan Waterfalls", "lat": 29.2573, "lng": 30.5832},
    {"name": "Kom Oshim Museum", "lat": 29.4963, "lng": 30.8351},
    {"name": "Ain El Selein Park", "lat": 29.3158, "lng": 30.8377},
    {"name": "Abgig Water Wheel", "lat": 29.3123, "lng": 30.8384},

    // ======= Alexandria =======
    {"name": "Alexandria Library", "lat": 31.2089, "lng": 29.9092},
    {"name": "Citadel of Qaitbay", "lat": 31.2135, "lng": 29.8855},
    {"name": "Montaza Palace", "lat": 31.2856, "lng": 30.0168},
    {"name": "Stanley Bridge", "lat": 31.2386, "lng": 29.9660},
    {"name": "Corniche Alexandria", "lat": 31.2156, "lng": 29.9020},
    {"name": "Alexandria University", "lat": 31.2045, "lng": 29.9028},
    {"name": "San Stefano Grand Plaza", "lat": 31.2394, "lng": 29.9601},
    {"name": "Alexandria Train Station", "lat": 31.1975, "lng": 29.8925},
  ];

  @override
  void initState() {
    super.initState();
    getCurrentLocation();
    destinationFocusNode.addListener(() {
      if (!destinationFocusNode.hasFocus) {
        FocusScope.of(context).unfocus();
      }
    });
  }

  @override
  void dispose() {
    destinationController.dispose();
    destinationFocusNode.dispose();
    super.dispose();
  }

  Future<void> getCurrentLocation() async {
    setState(() => isLoadingLocation = true);
    try {
      bool serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await geo.Geolocator.openLocationSettings();
        return;
      }

      geo.LocationPermission permission =
          await geo.Geolocator.checkPermission();
      if (permission == geo.LocationPermission.denied) {
        permission = await geo.Geolocator.requestPermission();
        if (permission == geo.LocationPermission.denied) {
          setState(() => isLoadingLocation = false);
          return;
        }
      }

      if (permission == geo.LocationPermission.deniedForever) {
        setState(() => isLoadingLocation = false);
        return;
      }

      geo.Position position = await geo.Geolocator.getCurrentPosition(
        desiredAccuracy: geo.LocationAccuracy.high,
      );

      List<geocoding.Placemark> placemarks =
          await geocoding.placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      geocoding.Placemark place = placemarks.first;

      setState(() {
        currentPosition = position;
        pickupAddress =
            "${place.street}, ${place.locality}, ${place.administrativeArea}";
        isLoadingLocation = false;
      });
    } catch (e) {
      print("Location error: $e");
      setState(() => isLoadingLocation = false);
    }
  }

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double R = 6371;
    final double dLat = (lat2 - lat1) * (pi / 180.0);
    final double dLon = (lon2 - lon1) * (pi / 180.0);
    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180.0) *
            cos(lat2 * pi / 180.0) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  Future<void> onPlaceSelected(Map<String, dynamic> place) async {
    if (currentPosition == null) return;

    final prefs = await SharedPreferences.getInstance();
    final passengerId = prefs.getInt('passenger_id');
    if (passengerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Passenger ID not found. Please login again.')),
      );
      return;
    }

    final pickupLocation = {
      "latitude": currentPosition!.latitude,
      "longitude": currentPosition!.longitude,
    };
    final dropoffLocation = {
      "latitude": place['lat'],
      "longitude": place['lng'],
    };
    final distance = calculateDistance(
      currentPosition!.latitude,
      currentPosition!.longitude,
      place['lat'],
      place['lng'],
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final response = await ApiService.createRide(
        region: 'cairo',
        pickupLocation: pickupLocation,
        dropoffLocation: dropoffLocation,
        passengerId: passengerId,
        distance: distance,
      );

      Navigator.pop(context); // Dismiss loading dialog

      if (response != null && response['ride'] != null) {
        String resolvedPassengerId = (response['passenger'] != null &&
                response['passenger']['id'] != null)
            ? response['passenger']['id'].toString()
            : passengerId.toString();

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RideConfirmationScreen(
              rideId: response['ride']['id'],
              pickupLat: currentPosition!.latitude,
              pickupLng: currentPosition!.longitude,
              dropoffLat: place['lat'],
              dropoffLng: place['lng'],
              dropoffName: place['name'],
              passengerId: resolvedPassengerId,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('There is no drivers available')),
        );
      }
    } catch (e) {
      Navigator.pop(context); // Dismiss loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Select Address',
            style: TextStyle(color: Colors.white, fontSize: 22)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: BackButton(color: Colors.white),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/1.png', fit: BoxFit.cover),
          ),
          if (isLoadingLocation)
            const Center(child: CircularProgressIndicator())
          else
            Column(
              children: [
                const SizedBox(height: kToolbarHeight + 24),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      buildReadOnlyField('Pickup location', pickupAddress),
                      const SizedBox(height: 12),
                      buildSearchField(),
                    ],
                  ),
                ),
                if (filteredPlaces.isNotEmpty)
                  Expanded(
                    child: ListView.builder(
                      itemCount: filteredPlaces.length,
                      itemBuilder: (_, index) {
                        final place = filteredPlaces[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          child: ListTile(
                            leading: const Icon(Icons.location_on),
                            title: Text(place['name']),
                            onTap: () => onPlaceSelected(place),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget buildReadOnlyField(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          const Icon(Icons.place, size: 20, color: Colors.black),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSearchField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(28),
      ),
      child: TextField(
        controller: destinationController,
        focusNode: destinationFocusNode,
        onChanged: (query) {
          setState(() {
            if (query.isNotEmpty) {
              filteredPlaces = fallbackPlaces
                  .where((place) =>
                      place['name'].toLowerCase().contains(query.toLowerCase()))
                  .toList();
            } else {
              filteredPlaces = [];
            }
          });
        },
        decoration: const InputDecoration(
          hintText: 'Where to?',
          border: InputBorder.none,
          icon: Icon(Icons.search),
        ),
        style: const TextStyle(fontSize: 16, color: Colors.black),
      ),
    );
  }
}
