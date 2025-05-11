import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'driv.log.in.dart'; // صفحة تسجيل دخول السائق
import '../admin/passenger_details.dart'; // صفحة البروفايل (مؤقتًا مستخدم بروفايل الراكب)

class DriverSettingsScreen extends StatelessWidget {
  const DriverSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
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
                      'Driver Settings',
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

            // First group (without Privacy)
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  _buildSettingsItem(context, 'My Profile'),
                ],
              ),
            ),

            SizedBox(height: 16.h),

            // Second group
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
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                return const Center(child: CircularProgressIndicator());
              },
            );

            final prefs = await SharedPreferences.getInstance();
            await prefs.clear();

            Navigator.pop(context);

            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const DriverLogin()),
              (Route<dynamic> route) => false,
            );
          } catch (e) {
            Navigator.pop(context);

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Error signing out')),
            );
          }
        } else if (title == 'My Profile') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PassengerProfileScreen(passengerId: 2),
              // ✳️ غيّريها لـ DriverProfileScreen لما تجهزيه
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
              style: const TextStyle(fontSize: 16),
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
