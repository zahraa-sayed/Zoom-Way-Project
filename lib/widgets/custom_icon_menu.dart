import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomIconMenu extends StatefulWidget {
  final String userName;
  final String userStatus;
  final String profileImagePath;

  const CustomIconMenu({
    super.key,
    required this.userName,
    required this.userStatus,
    required this.profileImagePath,
  });

  @override
  State<CustomIconMenu> createState() => _CustomIconMenuState();
}

class _CustomIconMenuState extends State<CustomIconMenu>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isMenuOpen = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    setState(() {
      _isMenuOpen = !_isMenuOpen;
      if (_isMenuOpen) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Backdrop - only visible when menu is open
        if (_isMenuOpen)
          GestureDetector(
            onTap: _toggleMenu,
            child: Container(
              color: Colors.black.withOpacity(0.4),
              width: double.infinity,
              height: double.infinity,
            ),
          ),

        // Animated Menu Panel
        AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          left: _isMenuOpen ? 0 : -280.w,
          top: 0,
          bottom: 0,
          width: 280.w,
          child: Material(
            elevation: 8,
            color: Colors.white,
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User profile section
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24.r,
                          backgroundImage: AssetImage(widget.profileImagePath),
                        ),
                        SizedBox(width: 12.w),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.userName,
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              widget.userStatus,
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 30.h),

                    // Menu items
                    _buildMenuItem(
                        Icons.flag_outlined, 'My Trips', Colors.blue),
                    _buildMenuItem(Icons.account_balance_wallet_outlined,
                        'Earnings', Colors.orange),
                    _buildMenuItem(Icons.help_outline, 'Help', Colors.purple),
                    _buildMenuItem(
                        Icons.shield_outlined, 'Safety Center', Colors.blue),
                    _buildMenuItem(
                        Icons.settings_outlined, 'Settings', Colors.grey),

                    const Spacer(),

                    // Go Offline button
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                          vertical: 10.h, horizontal: 16.w),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.power_settings_new,
                            color: Colors.blue,
                            size: 18.sp,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            'Go Offline',
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.w600,
                              fontSize: 14.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Menu Button - positioned similar to your existing MapScreen
        Positioned(
          top: 44.h,
          left: 16.w,
          child: SizedBox(
            width: 48.w, // Set a fixed width
            height: 48.w, // Set a fixed height (using width for perfect circle)
            child: Stack(
              fit: StackFit.loose,
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () {
                    _toggleMenu;
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(IconData icon, String title, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20.sp,
            ),
          ),
          SizedBox(width: 16.w),
          Text(
            title,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
