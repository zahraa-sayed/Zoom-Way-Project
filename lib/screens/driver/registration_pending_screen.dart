import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zoom_way/data/api/driver_api_services.dart';
import 'package:zoom_way/screens/driver/driver_home_screen.dart';


class RegistrationPendingScreen extends StatefulWidget {
  const RegistrationPendingScreen({super.key});

  @override
  State<RegistrationPendingScreen> createState() =>
      _RegistrationPendingScreenState();
}

class _RegistrationPendingScreenState extends State<RegistrationPendingScreen> {
  bool _isLoading = false;
  String _statusMessage = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Registration Status Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Registration Status Title
                    const Text(
                      'Registration Submitted',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),

                    // Awaiting Admin Approval
                    const Text(
                      'Awaiting Admin Approval',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: Colors.redAccent,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // Status Icon
                    const Icon(
                      Icons.hourglass_top,
                      size: 80,
                      color: Colors.amber,
                    ),
                    const SizedBox(height: 32),

                    // Status Description
                    const Text(
                      'Your profile has been submitted and is currently under review.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      'Please wait for admin approval before you can start using the app.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      'We\'ll notify you once your account is verified and activated.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // Refresh Status Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _checkApprovalStatus,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3EB8A5),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          disabledBackgroundColor: Colors.grey.shade300,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Refresh Status',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                      ),
                    ),

                    if (_statusMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Text(
                          _statusMessage,
                          style: TextStyle(
                            color: _statusMessage.contains('approved')
                                ? Colors.green
                                : Colors.red,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                    const SizedBox(height: 16),
                    const Text(
                      'This process might take up to 24 hours.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _checkApprovalStatus() async {
    setState(() {
      _isLoading = true;
      _statusMessage = '';
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      // Try both possible token keys
      final token =
          prefs.getString('driver_token') ?? prefs.getString('auth_token');
      debugPrint('Checking approval status. Token: $token');
      debugPrint('All SharedPrefs keys: ${prefs.getKeys()}');

      if (token == null) {
        setState(() {
          _isLoading = false;
          _statusMessage = 'Authentication error. Please login again.';
        });
        debugPrint(
            'No auth token found. Please ensure token is saved during login.');
        return;
      }

      final response = await DriverApiService().checkApprovalStatus();
      debugPrint('Approval status API response: $response');

      if (response['success']) {
        final bool isApproved = response['is_approved'] ?? false;
        debugPrint('Driver approval status: $isApproved');

        if (isApproved) {
          setState(() {
            _statusMessage = 'Your account has been approved!';
          });
          debugPrint('Account approved. Navigating to DriverHomeScreen...');
          Future.delayed(const Duration(seconds: 2), () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const DriverHomeScreen()),
              (route) => false,
            );
          });
        } else {
          debugPrint('Account not approved yet. Showing SnackBar.');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Your account is still pending approval. Please wait for verification.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        setState(() {
          _statusMessage = response['message'] ?? 'Failed to check status.';
        });
        debugPrint('API call failed: ${response['message']}');
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error checking status: $e';
      });
      debugPrint('Exception occurred while checking approval status: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Approval status check complete.');
    }
  }
}
