import 'dart:async';

import 'package:flutter/material.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();

    // تشغيل الأنيميشن بعد نصف ثانية
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _opacity = 1.0;
      });
    });

    // الانتقال إلى الصفحة التالية بعد 3 ثوانٍ
    Timer(const Duration(seconds: 4), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD7F7EB), // الخلفية تغطي الشاشة بالكامل
      body: Center(
        child: AnimatedOpacity(
          duration: const Duration(seconds: 4),
          opacity: _opacity,
          curve: Curves.easeInOut,
          child: Image.asset(
            'assets/images/logo.png', // Fixed path to match actual location
            width: 300,
            height: 300,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
