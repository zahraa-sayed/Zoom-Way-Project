import 'package:flutter/material.dart';
import 'package:zoom_way/data/api/admin_api_service.dart';
import 'package:zoom_way/screens/admin/add_admin_screen.dart';
import 'package:zoom_way/screens/admin/admin_login_screen.dart';
import 'package:zoom_way/screens/admin/drivers_screen.dart';
import 'package:zoom_way/screens/admin/feedbacks_screen.dart';
import 'package:zoom_way/screens/admin/history_screen.dart';
import 'package:zoom_way/screens/admin/notification_screen.dart';
import 'package:zoom_way/screens/admin/passangers_screen.dart';
import 'package:zoom_way/screens/admin/payment_screen.dart';


class AdminDashboard extends StatelessWidget {
  final String? adminName;

  const AdminDashboard({super.key, required this.adminName});

  Future<void> _handleLogout(BuildContext context) async {
    final api = AdminApiService();
    final success = await api.logout();
    if (success) {
      // Clear all screens and go to login
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AdminLogin()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logout failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Profile section with green background
          Container(
            padding: const EdgeInsets.all(20),
            color: const Color(0xFF26B99A),
            child: SafeArea(
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 40, color: Colors.grey),
                  ),
                  const SizedBox(width: 15),
                  Text(
                    adminName ?? 'Admin',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () => _handleLogout(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Log Out'),
                  ),
                ],
              ),
            ),
          ),

          // Menu items in curved container
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(top: 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildMenuItem(context,
                      name: 'assets/images/passenger_icon.png',
                      title: 'Passengers',
                      page: const PassengersScreen()),
                  _buildMenuItem(context,
                      name: 'assets/images/driver_icon.png',
                      title: 'Drivers',
                      page: const DriversScreen()),
                  _buildMenuItem(context,
                      name: 'assets/images/rides_icon.png',
                      title: 'Rides',
                      page: const HistoryScreen()),
                  _buildMenuItem(context,
                      name: 'assets/images/payment_icon.png',
                      title: 'Payments',
                      page: const AdminPaymentsScreen()),
                  _buildMenuItem(context,
                      name: 'assets/images/feedback_icon.png',
                      title: 'Feedbacks',
                      page: const FeedbacksScreen()),
                  _buildMenuItem(context,
                      name: 'assets/images/notification_icon.png',
                      title: 'Notifications',
                      page: const NotificationsScreen()),
                  _buildMenuItem(context,
                      name: 'assets/images/new_admin_icon.png',
                      title: 'Add New admin',
                      page: const AddAdminScreen()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required String name,
    required String title,
    required Widget page,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        leading: Image.asset(name),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => page),
          );
        },
      ),
    );
  }
}
