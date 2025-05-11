import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:zoom_way/data/api/driver_api_services.dart';

class DriverNotificationScreen extends StatefulWidget {
  const DriverNotificationScreen({super.key});

  @override
  State<DriverNotificationScreen> createState() =>
      _DriverNotificationScreenState();
}

class _DriverNotificationScreenState extends State<DriverNotificationScreen> {
  final DriverApiService _apiService = DriverApiService();
  List<dynamic> notifications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final result = await _apiService.getNotifications();
    debugPrint('Notifications API Response: $result');
    if (result['success']) {
      debugPrint('Notifications data: ${result['data']}');
      setState(() {
        notifications = result['data'];
        isLoading = false;
      });
    }
  }

  Future<void> _deleteNotification(String id) async {
    final result = await _apiService.deleteNotification(id);
    if (result['success']) {
      setState(() {
        notifications
            .removeWhere((notification) => notification['id'].toString() == id);
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notification deleted'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Failed to delete notification'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : notifications.isEmpty
              ? Center(
                  child: Text(
                    'No notifications',
                    style: TextStyle(fontSize: 16.sp),
                  ),
                )
              : ListView.builder(
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    debugPrint('Notification item $index: $notification');
                    return Dismissible(
                      key: Key(notification['id'].toString()),
                      onDismissed: (_) =>
                          _deleteNotification(notification['id'].toString()),
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: EdgeInsets.only(right: 20.w),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      child: ListTile(
                        title: Text(
                          notification['data']['title'] ?? 'No Title',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(notification['data']['message'] ??
                                'No Message'),
                            if (notification['data']['ride_details'] !=
                                null) ...[
                              SizedBox(height: 4.h),
                              Text(
                                'Passenger: ${notification['data']['ride_details']['passenger']}',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                'Distance: ${notification['data']['ride_details']['distance']} km',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              DateTime.parse(notification['created_at'])
                                  .toLocal()
                                  .toString()
                                  .split(' ')[0],
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              DateTime.parse(notification['created_at'])
                                  .toLocal()
                                  .toString()
                                  .split(' ')[1]
                                  .split('.')[0],
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
