

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:zoom_way/screens/main/home_screen.dart';
import 'package:zoom_way/screens/main/onboarding_screen_3.dart';

class OnboardingScreen2 extends StatelessWidget {
  const OnboardingScreen2({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF33B9A0), // لون الخلفية
      body: Column(
        children: [
          SizedBox(height: 80.h), // رفع النص للأعلى قليلاً
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0.w),
            child: Column(
              children: [
                Text(
                  'Request a Ride in Seconds!',
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 10.h),
                Text(
                  'Set your destination, choose your ride, and get matched with a nearby driver instantly',
                  style: TextStyle(fontSize: 16.sp, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          SizedBox(height: 20.h), // مسافة قبل الصورة

          /// جعل الصورة تأخذ العرض بالكامل دون فقد أي جزء
          Expanded(
            child: Image.asset(
              'assets/images/Img_car2.png', // استبدال الصورة القديمة بالجديدة
              width: double.infinity,
              fit: BoxFit.fitWidth, // يجعل العرض يغطي الشاشة بدون قص الصورة
            ),
          ),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HomeScreen(),
                      ),
                      (route) => false,
                    );
                  },
                  child: Text(
                    'Skip',
                    style: TextStyle(fontSize: 16.sp, color: Colors.white),
                  ),
                ),
                FloatingActionButton(
                  backgroundColor: Colors.white,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const OnboardingScreen3(),
                      ),
                    );
                  },
                  child: const Icon(Icons.arrow_forward, color: Colors.blue),
                ),
              ],
            ),
          ),
          SizedBox(height: 20.h), // مسافة أسفل الأزرار
        ],
      ),
    );
  }
}
