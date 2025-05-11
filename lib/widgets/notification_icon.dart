import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:zoom_way/data/api/driver_api_services.dart';
import 'package:zoom_way/screens/driver/notification_screen.dart';


class NotificationIconWidget extends StatelessWidget {
  const NotificationIconWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.notifications),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const DriverNotificationScreen(),
              ),
            );
          },
        ),
        Positioned(
          right: 8,
          top: 8,
          child: StreamBuilder<Map<String, dynamic>>(
            stream: Stream.periodic(const Duration(seconds: 30))
                .asyncMap((_) => DriverApiService().getNotifications()),
            builder: (context, snapshot) {
              if (snapshot.hasData &&
                  snapshot.data!['success'] &&
                  (snapshot.data!['data'] as List).isNotEmpty) {
                return Container(
                  padding: EdgeInsets.all(4.r),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    (snapshot.data!['data'] as List).length.toString(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10.sp,
                    ),
                  ),
                );
              }
              return const SizedBox();
            },
          ),
        ),
      ],
    );
  }
}
