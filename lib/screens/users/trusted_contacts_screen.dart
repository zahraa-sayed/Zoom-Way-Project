import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// CUBIT
class TrustedContactsCubit extends Cubit<TrustedContactsState> {
  TrustedContactsCubit() : super(TrustedContactsInitial());

  void addTrustedContact() {
    emit(TrustedContactsLoading());
    // Simulate API call
    Future.delayed(const Duration(seconds: 1), () {
      emit(TrustedContactsLoaded());
    });
  }
}

// STATES
abstract class TrustedContactsState {}

class TrustedContactsInitial extends TrustedContactsState {}

class TrustedContactsLoading extends TrustedContactsState {}

class TrustedContactsLoaded extends TrustedContactsState {}

class TrustedContactsError extends TrustedContactsState {
  final String message;
  TrustedContactsError(this.message);
}

// CONSTANTS
class AppColors {
  static const Color primary = Color(0xFF26A69A);
  static const Color secondary = Color(0xFF2D7A9C);
  static const Color background = Colors.white;
  static const Color textPrimary = Colors.black;
  static const Color textSecondary = Colors.grey;
}

// MAIN SCREEN
class TrustedContactsScreen extends StatelessWidget {
  const TrustedContactsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TrustedContactsCubit(),
      child: const TrustedContactsView(),
    );
  }
}

// VIEW
class TrustedContactsView extends StatelessWidget {
  const TrustedContactsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const AppHeader(title: 'Trusted Contacts'),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 16.h),
                      const TitleText(
                        text: 'Keep your loved ones in the loop.',
                      ),
                      SizedBox(height: 12.h),
                      const SubtitleText(
                        text:
                            'Your Trusted Contacts can see your trip details in a single tap.',
                      ),
                      SizedBox(height: 48.h),
                      const Center(
                        child: ContactImage(),
                      ),
                      SizedBox(height: 48.h),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(24.w),
              child: const AddContactButton(),
            ),
          ],
        ),
      ),
    );
  }
}

// REUSABLE COMPONENTS
class AppHeader extends StatelessWidget {
  final String title;

  const AppHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Row(
        children: [
          BackButton(
            onPressed: () => Navigator.pop(context),
          ),
          const Spacer(),
          Text(
            title,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class TitleText extends StatelessWidget {
  final String text;

  const TitleText({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return AutoSizeText(
      text,
      maxLines: 1,
      style: TextStyle(
        fontSize: 24.sp,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class SubtitleText extends StatelessWidget {
  final String text;

  const SubtitleText({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 16.sp,
        color: AppColors.textSecondary,
      ),
    );
  }
}

class ContactImage extends StatefulWidget {
  const ContactImage({super.key});

  @override
  State<ContactImage> createState() => _ContactImageState();
}

class _ContactImageState extends State<ContactImage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          ),
        );
      },
      child: Container(
        width: 300.w,
        height: 300.w,
        decoration: const BoxDecoration(
          color: Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Image.asset(
          'assets/images/trusted_contact_image.png',
          width: 150.w,
          height: 150.w,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const Text('Image not found!');
          },
        ),
      ),
    );
  }
}

// class ContactIllustration extends StatefulWidget {
//   const ContactIllustration({super.key});

//   @override
//   State<ContactIllustration> createState() => _ContactIllustrationState();
// }

// class _ContactIllustrationState extends State<ContactIllustration>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _controller;
//   late Animation<double> _scaleAnimation;
//   late Animation<double> _opacityAnimation;

//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 800),
//     );

//     _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
//       CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
//     );

//     _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
//       CurvedAnimation(parent: _controller, curve: Curves.easeIn),
//     );

//     _controller.forward();
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return AnimatedBuilder(
//       animation: _controller,
//       builder: (context, child) {
//         return Opacity(
//           opacity: _opacityAnimation.value,
//           child: Transform.scale(
//             scale: _scaleAnimation.value,
//             child: child,
//           ),
//         );
//       },
//       child: Container(
//           width: 200.w,
//           height: 200.w, // Using width for both to maintain aspect ratio
//           decoration: BoxDecoration(
//             color: Colors.lightBlue.shade50,
//             shape: BoxShape.circle,
//           ),
//           child: Image.asset('assets/images/trusted_contact_image.png')),
//     );
//   }
// }

class AddContactButton extends StatelessWidget {
  const AddContactButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TrustedContactsCubit, TrustedContactsState>(
      builder: (context, state) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: double.infinity,
          height: 56.h,
          child: ElevatedButton(
            onPressed: state is TrustedContactsLoading
                ? null
                : () =>
                    context.read<TrustedContactsCubit>().addTrustedContact(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.primary.withOpacity(0.7),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            child: state is TrustedContactsLoading
                ? SizedBox(
                    width: 24.w,
                    height: 24.w,
                    child: const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    'Add Trusted Contacts',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        );
      },
    );
  }
}
