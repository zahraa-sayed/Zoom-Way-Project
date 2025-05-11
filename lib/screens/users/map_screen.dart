import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zoom_way/screens/users/ai_chat_screen.dart';
import 'package:zoom_way/screens/users/log.in_screen.dart';
import 'package:zoom_way/screens/users/passenger_history.dart';
import 'package:zoom_way/screens/users/select_address_screen.dart';
import 'package:zoom_way/screens/users/payment.dart';
import 'package:zoom_way/screens/users/message_center_screen.dart';
import 'package:zoom_way/screens/users/safety_tools_screen.dart';
import 'package:zoom_way/screens/users/setting.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zoom_way/widgets/passenger_notification.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
 
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // Controller for Google Maps
  GoogleMapController? _mapController;

  // Initial camera position - Birmingham coordinates
  static const CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(52.4814, -1.8998), // Birmingham coordinates
    zoom: 14.0,
  );
  Future<void> _checkAuthAndNavigate() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (mounted) {
      if (token == null) {
        // Navigate to login if no token
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const PassengerLogin(),
          ),
        );
      } else {
        // Navigate to select address if authenticated
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SelectAddressScreen(
             
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: const [
          PassengerNotificationIconWidget(), // Add notification icon here
          SizedBox(width: 8),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              // Profile Section
              Padding(
                padding: EdgeInsets.all(16.w),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 25.r,
                      backgroundColor: Colors.grey[200],
                      backgroundImage:
                          const AssetImage('assets/images/Frame 1.png'),
                    ),
                    SizedBox(width: 16.w),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Radwa Ahm...',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'Edit personal info >',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(),

              // Menu Items with proper spacing and icons
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8.h),
                child: ListTile(
                  leading: Icon(Icons.calendar_today,
                      color: Colors.blue, size: 22.sp),
                  title: Text('MY Trips', style: TextStyle(fontSize: 15.sp)),
                  minLeadingWidth: 20.w,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const PassengerHistoryScreen()),
                    );
                  },
                ),
              ),
              ListTile(
                leading: Icon(Icons.payment, color: Colors.green, size: 22.sp),
                title: Text('Payment', style: TextStyle(fontSize: 15.sp)),
                minLeadingWidth: 20.w,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const PassengetPaymentScreen()),
                  );
                },
              ),
              ListTile(
                leading:
                    Icon(Icons.headphones, color: Colors.blue, size: 22.sp),
                title: Text('Help', style: TextStyle(fontSize: 15.sp)),
                minLeadingWidth: 20.w,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AIChatScreen()),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.message, color: Colors.blue, size: 22.sp),
                title: Text('Messages', style: TextStyle(fontSize: 15.sp)),
                minLeadingWidth: 20.w,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => BlocProvider(
                              create: (context) => MessageCenterCubit(),
                              child: const MessageCenterScreen(),
                            )),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.shield, color: Colors.blue, size: 22.sp),
                title: Text('Safety Center', style: TextStyle(fontSize: 15.sp)),
                minLeadingWidth: 20.w,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SafetyToolsScreen()),
                  );
                },
              ),
              ListTile(
                leading:
                    Icon(Icons.settings, color: Colors.grey[700], size: 22.sp),
                title: Text('Settings', style: TextStyle(fontSize: 15.sp)),
                minLeadingWidth: 20.w,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SettingsScreen()),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.group_add, color: Colors.blue, size: 22.sp),
                title:
                    Text('Invite Friends', style: TextStyle(fontSize: 15.sp)),
                minLeadingWidth: 20.w,
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          // Google Maps Integration (replacing the static image)
          SizedBox(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: GoogleMap(
              initialCameraPosition: _initialCameraPosition,
              mapType: MapType.normal,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
              },
            ),
          ),

          // Bottom Card with Illustration and Button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding:
                  EdgeInsets.only(left: 16.0.r, right: 16.0.r, bottom: 24.0.r),
              child: Container(
                height: 380.h,
                width: 402.w,
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Illustration from Image 2
                    SizedBox(
                      height: 160.h,
                      child: Image.asset(
                        'assets/images/image2-removebg-preview.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    SizedBox(height: 24.h),

                    // Unavailable Text
                    Text(
                      'Zoomway is currently unavailable\nin your area',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                        height: 1.3,
                      ),
                    ),
                    SizedBox(height: 30.h),

                    // Enter Address Button
                    Container(
                      width: double.infinity,
                      height: 56.h,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.r),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4AD4B0).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _checkAuthAndNavigate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4AD4B0),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: Text(
                          'Enter Address',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
