import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SafetyToolsScreen extends StatelessWidget {
  const SafetyToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SafetyToolsCubit(),
      child: const Scaffold(
        backgroundColor: Colors.white,
        body: SafetyToolsView(),
      ),
    );
  }
}

// MARK: - Main View
class SafetyToolsView extends StatelessWidget {
  const SafetyToolsView({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SafetyHeaderCard(),
            SizedBox(height: 12.h),
            const SafetyToolsList(),
          ],
        ),
      ),
    );
  }
}

// MARK: - Header Component
class SafetyHeaderCard extends StatelessWidget {
  const SafetyHeaderCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 0.28.sh,
      decoration: BoxDecoration(
        color: const Color(0xFF8EDDFD),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(12.r),
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Full safety tools image
          Image.asset(
            'assets/images/safety_tools_image.png',
            fit: BoxFit.fitHeight,
            width: 1.sw,
            height: 600.h,
          ),

          // Sound waves on the sides (decorative elements)
          Positioned(
            bottom: 30.h,
            left: 20.w,
            child: Icon(
              Icons.wifi,
              size: 24.sp,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
          Positioned(
            bottom: 30.h,
            right: 20.w,
            child: Icon(
              Icons.wifi,
              size: 24.sp,
              color: Colors.white.withOpacity(0.6),
            ),
          ),

          // Safety Tools circular container positioned over the image
          Positioned(
            bottom: -30.h, // Positioning to overlap with the content below
            child: Container(
              width: 0.9.sw,
              padding: EdgeInsets.symmetric(vertical: 16.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(
                    54.r), // Make it circular with large radius
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  'Safety Tools',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// MARK: - Safety Tools List Component
class SafetyToolsList extends StatelessWidget {
  const SafetyToolsList({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 30.h, 16.w,
          16.h), // Extra top margin for the overlapping circular container
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Trusted Contacts in separate gray container
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: Row(
                children: [
                  // Title and subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Trusted Contacts',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16.sp,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'Share trip quickly',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Add Now button
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blue,
                    ),
                    child: const Text('Add Now'),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 16.h),

          // Other safety tools in white container with rounded corners
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Trip Sharing
                SafetyToolItem(
                  icon: Icons.share_location,
                  iconColor: Colors.blue,
                  title: 'Trip Sharing',
                  subtitle: 'Real-time updates',
                  actionWidget: TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.black54,
                    ),
                    child: const Text('See More'),
                  ),
                ),

                const Divider(height: 1),

                // Trip Monitoring
                BlocBuilder<SafetyToolsCubit, SafetyToolsState>(
                    builder: (context, state) {
                  return SafetyToolItem(
                    icon: Icons.track_changes,
                    iconColor: Colors.blue,
                    title: 'Trip Monitoring',
                    subtitle: 'Alarm and help',
                    actionWidget: Switch(
                      value: state.isTripMonitoringEnabled,
                      onChanged: (value) {
                        context
                            .read<SafetyToolsCubit>()
                            .toggleTripMonitoring(value);
                      },
                      activeColor: Colors.blue,
                    ),
                  );
                }),

                const Divider(height: 1),

                // Police Assistance
                SafetyToolItem(
                  icon: Icons.local_police,
                  iconColor: Colors.red,
                  title: 'Police Assistance',
                  subtitle: 'Tap for police',
                  actionWidget: TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.black54,
                    ),
                    child: const Text('See More'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// MARK: - Safety Tool Item Component
class SafetyToolItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget actionWidget;

  const SafetyToolItem({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.actionWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        children: [
          // Icon
          Container(
            width: 40.w,
            height: 40.h,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 20.sp,
            ),
          ),
          SizedBox(width: 16.w),

          // Title and subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16.sp,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),

          // Action widget (button or switch)
          actionWidget,
        ],
      ),
    );
  }
}

// Keep the Cubit implementation unchanged
class SafetyToolsState {
  final bool isTripMonitoringEnabled;

  SafetyToolsState({
    this.isTripMonitoringEnabled = true,
  });

  SafetyToolsState copyWith({
    bool? isTripMonitoringEnabled,
  }) {
    return SafetyToolsState(
      isTripMonitoringEnabled:
          isTripMonitoringEnabled ?? this.isTripMonitoringEnabled,
    );
  }
}

class SafetyToolsCubit extends Cubit<SafetyToolsState> {
  SafetyToolsCubit() : super(SafetyToolsState());

  void toggleTripMonitoring(bool enabled) {
    emit(state.copyWith(isTripMonitoringEnabled: enabled));
  }

  // Add methods for other safety tool interactions as needed
  void addTrustedContact() {
    // Implementation for adding trusted contacts
  }

  void shareTrip() {
    // Implementation for trip sharing
  }

  void requestPoliceAssistance() {
    // Implementation for police assistance
  }
}
