import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zoom_way/data/api/admin_api_service.dart';


class Payment {
  final int id;
  final String paymentMethod;
  final String status;
  final double amount;
  final String createdAt;
  final Map<String, dynamic> ride;

  Payment({
    required this.id,
    required this.paymentMethod,
    required this.status,
    required this.amount,
    required this.createdAt,
    required this.ride,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'],
      paymentMethod: json['payment_method'],
      status: json['status'],
      amount: (json['amount'] as num).toDouble(),
      createdAt: json['created_at'],
      ride: json['ride'] ?? {},
    );
  }
}

class PaymentState {
  final List<Payment> payments;
  final bool isLoading;
  final String? error;

  PaymentState({
    this.payments = const [],
    this.isLoading = false,
    this.error,
  });
}

class PaymentCubit extends Cubit<PaymentState> {
  final AdminApiService _apiService = AdminApiService();

  PaymentCubit() : super(PaymentState());

  Future<void> loadPayments() async {
    emit(PaymentState(isLoading: true));
    try {
      final response = await _apiService.getPayments();

      if (response['success'] == true && response['data'] != null) {
        final List<Payment> payments =
            (response['data']['payments'] as List? ?? [])
                .map((payment) => Payment.fromJson(payment))
                .toList();

        emit(PaymentState(payments: payments));
        debugPrint('Payments loaded successfully: ${payments.length} payments');
      } else {
        emit(PaymentState(error: 'Failed to load payments'));
        debugPrint('Failed to load payments: $response');
      }
    } catch (e) {
      print('Error loading payments: $e');
      emit(PaymentState(error: 'Failed to load payments'));
    }
  }
}
