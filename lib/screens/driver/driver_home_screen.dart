import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zoom_way/data/api/driver_api_services.dart';
import 'package:zoom_way/screens/driver/driver_history_screen.dart';
import 'package:zoom_way/screens/driver/driver_setting_screen.dart';
import 'package:zoom_way/screens/users/safety_tools_screen.dart';
import 'package:zoom_way/screens/users/setting.dart';
import 'package:zoom_way/screens/driver/ride_request_screen.dart';
import 'package:zoom_way/widgets/notification_icon.dart';

import 'ai_chat_driver.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _driverName = 'Driver';
  bool _isOnline = false;

  @override
  void initState() {
    super.initState();
    _loadDriverProfile();
  }

  Future<void> _loadDriverProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('driver_name') ?? 'Driver';
    setState(() => _driverName = name);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: const SizedBox.shrink(), // العنوان
        actions: const [NotificationIconWidget()],
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      drawer: _buildDrawer(),
      body: _buildMainContent(),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(40),
        ),
      ),
      child: Column(
        children: [
          _buildProfileHeader(),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  bottomLeft: Radius.circular(40),
                ),
              ),
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _menuItem("assets/images/trips.png", 'MY Trips', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DriverHistoryScreen(),
                      ),
                    );
                  }),
                  _menuItem(
                      "assets/images/payment_icon.png", 'Earnings', () {}),
                  _menuItem("assets/images/feedback_icon.png", 'Help', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const AIChatScreen(), // فتح شاشة الـ AIChatScreen هنا
                      ),
                    );
                  }),
                  _menuItem("assets/images/safety.png", 'Safety Tools', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SafetyToolsScreen(),
                      ),
                    );
                  }),
                  _menuItem("assets/images/setting.png", 'Settings', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DriverSettingsScreen(),
                      ),
                    );
                  }),
                  const Divider(thickness: 0.5),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Switch(
                          value: _isOnline,
                          activeColor: const Color(0x8096948C),
                          inactiveThumbColor: const Color(0x8096948C),
                          onChanged: (value) {
                            setState(() => _isOnline = value);
                            _updateDriverStatus(value);
                          },
                        ),
                        const SizedBox(width: 8),
                        const Text('Go Offline'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
      color: const Color(0xFFE0E0E0).withOpacity(0.2),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            child: Icon(Icons.person, size: 40, color: Colors.grey),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _driverName.length > 15
                      ? "${_driverName.substring(0, 12)}..."
                      : _driverName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Edit personal info >",
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuItem(String iconPath, String title, VoidCallback onTap) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 5.h),
      leading: SizedBox(
        width: 24.w,
        height: 24.w,
        child: Image.asset(iconPath),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _buildMainContent() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          children: [
            const SizedBox(height: 16),
            // النصوص فوق الصورة
            const Text(
              'Welcome to ZoomWay!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Your journey starts here.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            // ثم الصورة بعد النصوص
            Center(
              child: Image.asset(
                'assets/images/map_placeholder.png',
                width: MediaQuery.of(context).size.width *
                    0.8, // Adjust width as needed
                height: MediaQuery.of(context).size.width *
                    0.8, // Adjust height as needed
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 30.0),
              child: Text(
                'Use the side menu or tap the button below to view your ride requests',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RideRequestScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3EB8A5),
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 4,
              ),
              child: const Text(
                'Show Ride Requests',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _updateDriverStatus(bool isOnline) async {
    try {
      final response = await DriverApiService().updateDriverStatus(isOnline);
      if (!response['success']) {
        _showError(response['message'] ?? 'Failed to update status');
        setState(() => _isOnline = !isOnline);
      }
    } catch (e) {
      _showError('Error updating status: $e');
      setState(() => _isOnline = !isOnline);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}
