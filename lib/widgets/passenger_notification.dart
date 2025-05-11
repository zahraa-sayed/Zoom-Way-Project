import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:zoom_way/data/api/passengers_api_service.dart';
import 'package:zoom_way/screens/users/passenger_notifiation.dart';
 // Update import

class PassengerNotificationIconWidget extends StatelessWidget {
  const PassengerNotificationIconWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: Stream.periodic(const Duration(seconds: 30)).asyncMap((_) async {
        final token = await ApiService.getToken();
        if (token == null) return {'success': false, 'data': []};
        return ApiService().getNotifications();
      }),
      builder: (context, snapshot) {
        return Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications),
              onPressed: () async {
                final token = await ApiService.getToken();
                if (token == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please login to view notifications')),
                  );
                  return;
                }
                if (context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationScreen(),
                    ),
                  );
                }
              },
            ),
            if (snapshot.hasData &&
                snapshot.data!['success'] &&
                (snapshot.data!['data'] as List).isNotEmpty)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 12,
                    minHeight: 12,
                  ),
                  child: Text(
                    '${(snapshot.data!['data'] as List).length}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8.sp,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
