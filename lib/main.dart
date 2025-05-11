import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zoom_way/data/api/passengers_api_service.dart';
import 'package:zoom_way/logic/cubit/admin_cubit/driver_details_cubit.dart';
import 'package:zoom_way/logic/cubit/admin_cubit/feedback_cubit.dart';
import 'package:zoom_way/logic/cubit/admin_cubit/history_cubit.dart';
import 'package:zoom_way/logic/cubit/admin_cubit/notification_cubit.dart';
import 'package:zoom_way/logic/cubit/admin_cubit/payment_cubit.dart';
import 'package:zoom_way/logic/cubit/driver_cubit/document_upload_cubit.dart';
import 'package:zoom_way/logic/cubit/driver_cubit/name_input_cubit.dart';
import 'package:zoom_way/screens/admin/drivers_screen.dart';
import 'package:zoom_way/screens/admin/passangers_screen.dart';
import 'package:zoom_way/screens/main/splash_screen.dart';

import 'package:zoom_way/screens/users/ride_share_screen.dart';
import 'package:zoom_way/screens/users/trusted_contacts_screen.dart';

Future<void> _loadAuthToken() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final userData = prefs.getString('user_data');

    if (token != null) {
      await ApiService.setAuthToken(token);
      debugPrint('Auth token loaded successfully');

      if (userData != null) {
        debugPrint('User data loaded successfully');
      } else {
        debugPrint('No user data found');
      }
    }
  } catch (e) {
    debugPrint('Error loading auth token: $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _loadAuthToken();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // Driver-related Cubits
        BlocProvider(
          create: (context) => DocumentUploadCubit(),
        ),
        BlocProvider(
          create: (context) => NameInputCubit(registrationData: {}),
        ),
        // User-related Cubits
       
       
        BlocProvider(
          create: (context) => TrustedContactsCubit(),
        ),
        // Admin-related Cubits
        BlocProvider(
          create: (context) => DriverCubit(),
        ),
        // Add PassengerCubit here
        BlocProvider(
          create: (context) => PassengerCubit(),
        ),
        // In the MultiBlocProvider providers list, add:
        BlocProvider(
          create: (context) => HistoryCubit(),
        ),
        // Add these imports

        // In MultiBlocProvider, add these providers
        BlocProvider(
          create: (context) => FeedbackCubit(),
        ),
        BlocProvider(
          create: (context) => PaymentCubit(),
        ),
        BlocProvider(
          create: (context) => NotificationCubit(),
        ),
        BlocProvider(
          create: (context) => DriverCubit(),
        ),
        BlocProvider(
          create: (context) =>
              DriverDetailsCubit(0), // Add this with a default ID
        ),
      ],
      child: ScreenUtilInit(
        designSize: const Size(360, 690),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (_, child) {
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: SplashScreen(),
          );
        },
      ),
    );
  }
}
