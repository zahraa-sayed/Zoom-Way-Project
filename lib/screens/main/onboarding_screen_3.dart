import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:zoom_way/screens/main/home_screen.dart';

class OnboardingScreen3 extends StatelessWidget {
  const OnboardingScreen3({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF95B6FF), // لون الخلفية
      body: Column(
        children: [
          SizedBox(height: 80.h), // responsive height
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0.w),
            child: Column(
              children: [
                Text(
                  'Ride your Way',
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 10.h),
                Text(
                  'Choose from a variety of car options to fit your needs..png',
                  style: TextStyle(fontSize: 16.sp, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          SizedBox(height: 20.h), // responsive space

          /// جعل الصورة تأخذ العرض بالكامل دون فقد أي جزء
          Expanded(
            child: Image.asset(
              'assets/images/Img_car4.png', // استبدال الصورة القديمة بالجديدة
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
                        builder: (context) => const HomeScreen(),
                      ),
                    );
                  },
                  child: const Icon(Icons.arrow_forward, color: Colors.blue),
                ),
              ],
            ),
          ),
          SizedBox(height: 20.h), // responsive space
        ],
      ),
    );
  }
}
