

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zoom_way/logic/cubit/admin_cubit/feedback_cubit.dart';

class FeedbacksScreen extends StatelessWidget {
  const FeedbacksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => FeedbackCubit()..loadFeedbacks(),
      child: Scaffold(
        backgroundColor: const Color(0xFF26B99A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF26B99A),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'Feedbacks',
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
          child: BlocBuilder<FeedbackCubit, FeedbackState>(
            builder: (context, state) {
              if (state.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state.error != null) {
                return Center(child: Text(state.error!));
              }
              if (state.feedbacks.isEmpty) {
                return const Center(child: Text('No feedbacks available'));
              }

              return RefreshIndicator(
                onRefresh: () async {
                  await context.read<FeedbackCubit>().loadFeedbacks();
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.feedbacks.length,
                  itemBuilder: (context, index) {
                    final feedback = state.feedbacks[index];
                    final ride = feedback['ride'] ?? {};

                    return Column(
                      children: [
                        FeedbackCard(
                          originAddress: _parseCoordinates(
                              ride['pickup_location'] ?? '',
                              isOrigin: true),
                          destinationAddress: _parseCoordinates(
                              ride['dropoff_location'] ?? '',
                              isOrigin: false),
                          driverName:
                              feedback['driver']?['name'] ?? 'Unknown Driver',
                          driverComment:
                              feedback['driver_comment'] ?? 'No comment',
                          passengerName: feedback['passenger']?['name'] ??
                              'Unknown Passenger',
                          passengerComment:
                              feedback['passenger_comment'] ?? 'No comment',
                          driverRating: int.tryParse(
                                  feedback['driver_rating']?.toString() ??
                                      '') ??
                              0,
                          passengerRating: int.tryParse(
                                  feedback['passenger_rating']?.toString() ??
                                      '') ??
                              0,
                          status: ride['status'] ?? 'complete',
                        ),
                        const SizedBox(height: 16),
                      ],
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

String _parseCoordinates(String locationJson, {bool isOrigin = true}) {
  try {
    final Map<String, dynamic> location = jsonDecode(locationJson);
    return isOrigin
        ? location['longitude'].toString()
        : location['latitude'].toString();
  } catch (e) {
    return 'Unknown';
  }
}

// Keep existing FeedbackCard and StarRating classes unchanged
class FeedbackCard extends StatelessWidget {
  final String originAddress;
  final String destinationAddress;
  final String driverName;
  final String driverComment;
  final String passengerName;
  final String passengerComment;
  final int driverRating;
  final int passengerRating;

  final String status;

  const FeedbackCard({
    super.key,
    required this.originAddress,
    required this.destinationAddress,
    required this.driverName,
    required this.driverComment,
    required this.passengerName,
    required this.passengerComment,
    required this.driverRating,
    required this.passengerRating,
    required this.status,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // الجزء العلوي: المسار مع حالة "complete"
          Stack(
            children: [
              // المسار
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
              // علامة "complete"
              Positioned(
                top: 16,
                right: 16,
                child: Text(
                  status,
                  style: TextStyle(
                    color: status.toLowerCase() == 'complete'
                        ? const Color(0xFF26B99A)
                        : Colors.orange,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 1),
          // تعليق السائق
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  driverName,
                  style: const TextStyle(
                    color: Color(0xFF26B99A),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      driverComment,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                      ),
                    ),
                    // تقييم النجوم للسائق
                    StarRating(rating: driverRating),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // تعليق الراكب
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  passengerName,
                  style: const TextStyle(
                    color: Color(0xFF26B99A),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      passengerComment,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                      ),
                    ),
                    // تقييم النجوم للراكب
                    StarRating(rating: passengerRating),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class StarRating extends StatelessWidget {
  final int rating;
  final int maxRating;

  const StarRating({
    super.key,
    required this.rating,
    this.maxRating = 5,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxRating, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          color:
              index < rating ? const Color(0xFFFFB74D) : Colors.grey.shade300,
          size: 20,
        );
      }),
    );
  }
}
