import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/api/driver_api_services.dart';
import 'driver.sign.up.dart';
import 'driver_home_screen.dart';


class DriverLogin extends StatefulWidget {
  const DriverLogin({super.key});

  @override
  State<DriverLogin> createState() => _DriverLoginState();
}

class _DriverLoginState extends State<DriverLogin> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final DriverApiService _apiService = DriverApiService();

  bool _isLoading = false;
  String _errorMessage = '';

// Enhanced API call error handling for login
  Future<void> _handleLogin() async {
    debugPrint('Starting login process...');
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      if (!_validateLoginForm()) {
        debugPrint('Form validation failed');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      debugPrint('Attempting login with email: ${_emailController.text}');
      final response = await _apiService.login(
        email: _emailController.text,
        password: _passwordController.text,
      );

      debugPrint('Login response received: $response');

      if (response['success']) {
        debugPrint('Login successful, saving driver ID');
        final prefs = await SharedPreferences.getInstance();
        // Fix: Access user data from the correct path in response
        final userData = response['data']['user'];
        if (userData != null && userData['id'] != null) {
          await prefs.setString('driver_id', userData['id'].toString());
          debugPrint('Driver ID saved: ${userData['id']}');

          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DriverHomeScreen()),
          );
        } else {
          debugPrint('Error: User data or ID is null');
          setState(() {
            _errorMessage = 'Invalid user data received';
          });
        }
      } else {
        debugPrint('Login failed: ${response['message']}');
        setState(() {
          _errorMessage =
              response['message'] ?? 'Login failed. Please try again.';
        });
      }
    } catch (e) {
      debugPrint('Login error occurred: $e');
      setState(() {
        if (e.toString().contains('SocketException') ||
            e.toString().contains('Connection refused')) {
          _errorMessage = 'Network error. Please check your connection.';
          debugPrint('Network error detected');
        } else if (e.toString().contains('timeout')) {
          _errorMessage = 'Request timed out. Please try again.';
          debugPrint('Request timeout detected');
        } else {
          _errorMessage = 'An unexpected error occurred: ${e.toString()}';
          debugPrint('Unexpected error: $e');
        }
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        debugPrint('Login process completed');
      }
    }
  }

// Add form validation for login
  bool _validateLoginForm() {
    if (_emailController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your email';
      });
      return false;
    }

    if (_passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your password';
      });
      return false;
    }

    return true;
  }

  Future<void> _handleGoogleLogin() async {
    // Implement Google login logic here
    // This would typically involve using a package like google_sign_in
    // and then sending the token to your backend
    setState(() {
      _errorMessage = 'Google login not implemented yet';
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Image.asset(
                    'assets/images/logo2.png',
                    height: 180,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Login',
                  style: TextStyle(
                    color: Color(0xFF022736),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                // Show error message if any
                if (_errorMessage.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _errorMessage,
                      style: TextStyle(color: Colors.red.shade800),
                    ),
                  ),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.email),
                    hintText: 'Email or User Name',
                    hintStyle: const TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.lock_outline),
                    hintText: 'Password',
                    hintStyle: const TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      // Implement forgot password functionality
                    },
                    child: const Text(
                      'Forget Password?',
                      style: TextStyle(
                        color: Color(0xFF022736),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _handleLogin,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          backgroundColor: const Color(0xFF33B9A0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        child: const Text(
                          'Login',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: _handleGoogleLogin,
                  icon: Image.asset(
                    'assets/images/google.png',
                    height: 40,
                    width: 40,
                    fit: BoxFit.cover,
                  ),
                  label: const Text(
                    'Login With Google',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Don't have an account?",
                      style: TextStyle(
                        color: Colors.black,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const SignUpApp()),
                        );
                      },
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(
                          color: Color(0xFF022736),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
