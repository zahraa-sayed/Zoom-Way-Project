// import 'dart:io';

// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:yaaa_raab/Api_Helper/driver_api_services.dart';
// import 'package:yaaa_raab/screens/driver/driver_info_screen.dart';

// // States
// abstract class RegistrationState {}

// class RegistrationInitial extends RegistrationState {}

// class RegistrationLoading extends RegistrationState {}

// class RegistrationSuccess extends RegistrationState {}

// class RegistrationError extends RegistrationState {
//   final String message;
//   RegistrationError(this.message);
// }

// // Cubit
// class RegistrationCubit extends Cubit<RegistrationState> {
//   final DriverApiService _apiService = DriverApiService();

//   RegistrationCubit() : super(RegistrationInitial());

//   Future<void> submitRegistration({
//     required NameInputState driverData,
//     required Map<String, File> documents,
//     required String email,
//     required String password,
//     required String passwordConfirmation,
//   }) async {
//     emit(RegistrationLoading());

//     try {
//       final result = await _apiService.registerDriver(
//         name: "${driverData.firstName} ${driverData.lastName}",
//         email: email,
//         phoneNumber: driverData.phoneNumber,
//         carModel: driverData.carModel,
//         password: password,
//         passwordConfirmation: passwordConfirmation,
//         address: driverData.address,
//         licenseNumber: driverData.licenseNumber,
//         drivingExperience: driverData.drivingExperience,
//         licensePlate: driverData.licensePlate,
//         carColor: driverData.carColor,
//         manufacturingYear: driverData.manufacturingYear,
//         idCardFront: documents['ID Front']!,
//         idCardBack: documents['ID Back']!,
//         licenseFront: documents['License Front']!,
//         licenseBack: documents['License Back']!,
//         drivingLicenseFront: documents['Driving License Front']!,
//         drivingLicenseBack: documents['Driving License Back']!,
//       );

//       if (result['success']) {
//         emit(RegistrationSuccess());
//       } else {
//         emit(RegistrationError(result['message'] ?? 'Registration failed'));
//       }
//     } catch (e) {
//       emit(RegistrationError(e.toString()));
//     }
//   }
// }

// class RegistrationConfirmationScreen extends StatelessWidget {
//   final NameInputState driverData;
//   final Map<String, File> documents;
//   final String email;
//   final String password;
//   final String passwordConfirmation;

//   const RegistrationConfirmationScreen({
//     super.key,
//     required this.driverData,
//     required this.documents,
//     required this.email,
//     required this.password,
//     required this.passwordConfirmation,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return BlocProvider(
//       create: (context) => RegistrationCubit(),
//       child: Scaffold(
//         body: SafeArea(
//           child: Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Column(
//               children: [
//                 const Text('Confirm Registration'),
//                 const Spacer(),
//                 _buildSubmitButton(context),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildSubmitButton(BuildContext context) {
//     return BlocConsumer<RegistrationCubit, RegistrationState>(
//       listener: (context, state) {
//         if (state is RegistrationSuccess) {
//           Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(
//                 builder: (context) => const RegistrationSuccessScreen()),
//           );
//         }
//         if (state is RegistrationError) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text(state.message)),
//           );
//         }
//       },
//       builder: (context, state) {
//         return SizedBox(
//           width: double.infinity,
//           child: ElevatedButton(
//             onPressed: state is RegistrationLoading
//                 ? null
//                 : () => _submitRegistration(context),
//             child: state is RegistrationLoading
//                 ? const CircularProgressIndicator()
//                 : const Text('Complete Registration'),
//           ),
//         );
//       },
//     );
//   }

//   void _submitRegistration(BuildContext context) {
//     context.read<RegistrationCubit>().submitRegistration(
//           driverData: driverData,
//           documents: documents,
//           email: email,
//           password: password,
//           passwordConfirmation: passwordConfirmation,
//         );
//   }
// }

// class RegistrationSuccessScreen extends StatelessWidget {
//   const RegistrationSuccessScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Icon(Icons.check_circle, color: Colors.green, size: 100),
//             const Text('Registration Successful!'),
//             TextButton(
//               onPressed: () =>
//                   Navigator.popUntil(context, (route) => route.isFirst),
//               child: const Text('Return to Home'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
