import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:zoom_way/screens/driver/driv.log.in.dart';
import '../admin/passenger_details.dart';
import 'log.in_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with close button and title
            Container(
              color: Colors.white,
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop();
                      },
                      child: const Icon(Icons.close),
                    ),
                    SizedBox(height: 16.h),
                    const Text(
                      'Settings',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16.h),
            // Settings list - first group
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  _buildSettingsItem(context, 'My Profile'),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  _buildSettingsItem(context, 'Privacy'),
                ],
              ),
            ),

            SizedBox(height: 16.h),

            // Settings list - second group
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  _buildSettingsItem(context, 'About Zoomway'),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  _buildSettingsItem(context, 'Sign Out'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsItem(BuildContext context, String title) {
    return InkWell(
      onTap: () async {
        if (title == 'Sign Out') {
          try {
            // Show loading indicator
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                return const Center(child: CircularProgressIndicator());
              },
            );

            // Clear stored data
            final prefs = await SharedPreferences.getInstance();
            await prefs.clear();

            // Remove loading indicator
            Navigator.pop(context);

            // Navigate to login screen and remove all previous routes
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const DriverLogin ()),
              (Route<dynamic> route) => false,
            );
          } catch (e) {
            // Remove loading indicator if still showing
            Navigator.pop(context);

            // Show error message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Error signing out')),
            );
          }
        } else if (title == 'My Profile') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>  PassengerProfileScreen(passengerId: 2,),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Navigating to $title')),
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}

