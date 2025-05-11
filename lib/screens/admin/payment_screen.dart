import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zoom_way/logic/cubit/admin_cubit/payment_cubit.dart';

class AdminPaymentsScreen extends StatefulWidget {
  const AdminPaymentsScreen({super.key});

  @override
  State<AdminPaymentsScreen> createState() => _AdminPaymentsScreenState();
}

class _AdminPaymentsScreenState extends State<AdminPaymentsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<PaymentCubit>().loadPayments();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF26B99A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF26B99A),
        elevation: 0,
        title: const Text(
          'Payments',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF2F2F2),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: BlocBuilder<PaymentCubit, PaymentState>(
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.error != null) {
              return Center(child: Text(state.error!));
            }

            if (state.payments.isEmpty) {
              return const Center(child: Text('No payments found'));
            }

            return RefreshIndicator(
              onRefresh: () => context.read<PaymentCubit>().loadPayments(),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.payments.length,
                itemBuilder: (context, index) {
                  final payment = state.payments[index];
                  final pickupLocation = payment.ride['pickup_location'] != null
                      ? jsonDecode(payment.ride['pickup_location'])['address']
                      : 'Unknown pickup';
                  final dropoffLocation = payment.ride['dropoff_location'] !=
                          null
                      ? jsonDecode(payment.ride['dropoff_location'])['address']
                      : 'Unknown dropoff';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: PaymentCard(
                      originAddress: pickupLocation,
                      destinationAddress: dropoffLocation,
                      amount: payment.amount,
                      paymentMethod: payment.paymentMethod,
                      paymentMethodColor:
                          payment.paymentMethod.toLowerCase() == 'card'
                              ? const Color(0xFF26B99A)
                              : Colors.blue,
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class PaymentCard extends StatelessWidget {
  final String originAddress;
  final String destinationAddress;
  final double amount;
  final String paymentMethod;
  final Color paymentMethodColor;

  const PaymentCard({
    super.key,
    required this.originAddress,
    required this.destinationAddress,
    required this.amount,
    required this.paymentMethod,
    required this.paymentMethodColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // المسار مع طريقة الدفع
          Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // أيقونات المسار
                    Column(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: const Color(0xFF26B99A),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                        ),
                        Container(
                          width: 2,
                          height: 30,
                          color: Colors.grey.withOpacity(0.3),
                        ),
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    // العناوين
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            originAddress,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            destinationAddress,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // طريقة الدفع
              Positioned(
                top: 16,
                right: 16,
                child: Text(
                  paymentMethod,
                  style: TextStyle(
                    color: paymentMethodColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 1),
          // معلومات المبلغ
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.attach_money,
                          color: Colors.grey,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '\$${amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Icon(
                  Icons.chevron_right,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
