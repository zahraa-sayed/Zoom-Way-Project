import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';


class PermissionHandler {
  static final PermissionHandler _instance = PermissionHandler._internal();
  factory PermissionHandler() => _instance;
  PermissionHandler._internal();

  Future<bool> checkAndRequestLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Request location service to be enabled
      await Geolocator.openLocationSettings();
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Open app settings to allow user to enable permission
      await openAppSettings();
      return false;
    }

    return true;
  }

  Future<bool> checkAndRequestNotificationPermission() async {
    final status = await Permission.notification.status;
    if (status.isDenied) {
      final result = await Permission.notification.request();
      return result.isGranted;
    }
    return status.isGranted;
  }

  Future<bool> checkAndRequestAllRequiredPermissions() async {
    final locationGranted = await checkAndRequestLocationPermission();
    final notificationGranted = await checkAndRequestNotificationPermission();

    return locationGranted && notificationGranted;
  }
}
