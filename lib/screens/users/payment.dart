import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PassengetPaymentScreen extends StatelessWidget {
  const PassengetPaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with back button and title
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                    child: const Icon(Icons.chevron_left, size: 30),
                  ),
                  SizedBox(width: 80.w),
                  const Text(
                    'ZoomWayPay',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Balance label
              Text(
                'Balance',
                style: TextStyle(
                  fontSize: 20.sp,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 8),

              // Balance amount
              const Row(
                children: [
                  Text(
                    'EGP',
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(width: 4),
                  Text(
                    '0.00 >',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Payment methods list
              _buildPaymentMethodItem(
                context,
                title: 'Balance',
                iconPlaceholder: 'assets/images/balance.png',
                showChevron: false,
              ),

              const Divider(height: 1),

              _buildPaymentMethodItem(
                context,
                title: 'Cash',
                iconPlaceholder: 'assets/images/cash.png',
                showChevron: true,
              ),

              const Divider(height: 1),

              _buildPaymentMethodItem(
                context,
                title: 'Credit / Debit Card',
                iconPlaceholder: 'assets/images/credit_card.png',
                showChevron: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodItem(
    BuildContext context, {
    required String title,
    required String iconPlaceholder,
    required bool showChevron,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        children: [
          // Icon placeholder - you will replace this with your actual icon path
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Image.asset(
                iconPlaceholder,
              
              ),
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
          ),

          if (showChevron)
            const Icon(
              Icons.chevron_right,
              color: Colors.grey,
            ),
        ],
      ),
    );
  }
}
