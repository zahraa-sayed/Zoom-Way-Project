import 'package:flutter/material.dart';
import 'package:zoom_way/data/api/passengers_api_service.dart';
import 'package:zoom_way/screens/users/change_password_screen.dart';
import 'package:zoom_way/screens/users/delete_account_screen.dart';


class PassengerProfileScreen extends StatefulWidget {
  const PassengerProfileScreen({super.key});

  @override
  State<PassengerProfileScreen> createState() => _PassengerProfileScreenState();
}

class _PassengerProfileScreenState extends State<PassengerProfileScreen> {
  Map<String, dynamic>? userData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    debugPrint('Initializing PassengerProfileScreen');
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      debugPrint('Loading user profile data...');
      final response = await ApiService().getUserProfile();

      if (response['success']) {
        debugPrint('Profile data loaded successfully');
        setState(() {
          userData = response['data']['user'];
          isLoading = false;
        });
        debugPrint('User data: $userData');
      } else {
        debugPrint('Failed to load profile: ${response['message']}');
        setState(() {
          isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['message'])),
          );
        }
      }
    } catch (e) {
      debugPrint('Error in _loadUserProfile: $e');
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load profile')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      debugPrint('Showing loading indicator');
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Split the name into first and last name
    List<String> nameParts = (userData?['name'] ?? '').split(' ');
    String firstName = nameParts.isNotEmpty ? nameParts[0] : '';
    String lastName =
        nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

    debugPrint('Building profile screen with data');
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'My Profile',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile picture section
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Row(
                children: [
                  const SizedBox(width: 24),
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: userData!['photo_url'] != null &&
                            userData!['photo_url'].isNotEmpty
                        ? NetworkImage(userData!['photo_url'])
                        : null,
                    child: userData!['photo_url'] == null ||
                            userData!['photo_url'].isEmpty
                        ? const Icon(Icons.person, size: 50, color: Colors.grey)
                        : null,
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      // Handle edit profile picture
                    },
                    child: const Row(
                      children: [
                        Text(
                          'Edit Profile Picture',
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.chevron_right,
                          color: Colors.black54,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
              ),
            ),

            const Divider(height: 1),

            // First Name
            _buildProfileField(
              label: 'First Name',
              value: firstName,
              onTap: () {
                debugPrint('First name tapped: $firstName');
                _showEditNameDialog(context, firstName, true);
              },
            ),

            // Last Name
            _buildProfileField(
              label: 'Last Name',
              value: lastName,
              onTap: () {
                debugPrint('Last name tapped: $lastName');
                _showEditNameDialog(context, lastName, false);
              },
            ),

            const SizedBox(height: 20),

            // Mobile Number
            _buildProfileField(
              label: 'Mobile Number',
              value: userData?['phone_number'] ?? 'Not set',
              showArrow: true,
              onTap: () {
                debugPrint('Phone number tapped: ${userData?['phone_number']}');
              },
            ),

            // Email
            _buildProfileField(
              label: 'Email',
              value: userData?['email'] ?? 'Not set',
              additionalText: userData?['email_verified_at'] != null
                  ? 'Verified'
                  : 'Unverified',
              additionalTextColor: userData?['email_verified_at'] != null
                  ? Colors.green
                  : Colors.redAccent,
              showArrow: true,
              onTap: () {
                debugPrint('Email tapped: ${userData?['email']}');
              },
            ),

            // Address - Replace this with the new address selector
            _buildAddressSelector(),

            // Update the Password field onTap handler
            _buildProfileField(
              label: 'Password',
              showArrow: true,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ChangePasswordScreen(),
                  ),
                );
              },
            ),

            // Third-party Account
            _buildProfileField(
              label: 'Third-party Account',
              showArrow: true,
              onTap: () {
                // Handle third-party account management
              },
            ),

            // Device Management
            _buildProfileField(
              label: 'Device Management',
              showArrow: true,
              onTap: () {
                // Handle device management
              },
            ),

            // Delete Account
            _buildProfileField(
              label: 'Delete Account',
              showArrow: true,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DeleteAccountScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileField({
    required String label,
    String? value,
    String? additionalText,
    Color? additionalTextColor,
    bool showArrow = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (value != null) const SizedBox(height: 4),
                  if (value != null)
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.black,
                      ),
                    ),
                ],
              ),
            ),
            if (additionalText != null)
              Text(
                additionalText,
                style: TextStyle(
                  color: additionalTextColor ?? Colors.black54,
                  fontSize: 14,
                ),
              ),
            if (showArrow)
              const Icon(
                Icons.chevron_right,
                color: Colors.black45,
              ),
          ],
        ),
      ),
    );
  }

  void _showEditNameDialog(
      BuildContext context, String currentName, bool isFirstName) {
    final TextEditingController controller =
        TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${isFirstName ? 'First' : 'Last'} Name'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Enter your ${isFirstName ? 'first' : 'last'} name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              // Save the updated name
              Navigator.pop(context);
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressSelector() {
    final List<String> addressOptions = ['Cairo', 'Giza', 'Fayoum'];
    String currentAddress = userData?['address'] ?? 'Cairo';

    // Ensure the current address is one of the valid options
    if (!addressOptions.contains(currentAddress)) {
      currentAddress = 'Cairo';
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Address',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: addressOptions.map((address) {
              final bool isSelected = address == currentAddress;
              return GestureDetector(
                onTap: () {
                  if (address != currentAddress) {
                    setState(() {
                      userData?['address'] = address;
                    });
                    _updateUserAddress(address);
                  }
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue : Colors.grey[200],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? Colors.blue : Colors.grey[300]!,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    address,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Future<void> _updateUserAddress(String newAddress) async {
    try {
      final response = await ApiService().updateUserProfile({
        'address': newAddress,
      });

      if (response['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Address updated to $newAddress')),
        );
        // Refresh user data
        _loadUserProfile();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(response['message'] ?? 'Failed to update address')),
        );
      }
    } catch (e) {
      debugPrint('Error updating address: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update address')),
      );
    }
  }
}
