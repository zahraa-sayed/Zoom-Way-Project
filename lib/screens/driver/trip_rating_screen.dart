import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:zoom_way/screens/driver/driver_home_screen.dart';

// Rating Cubit for managing rating state
class RatingCubit extends Cubit<int> {
  RatingCubit() : super(0);

  void setRating(int rating) {
    emit(rating);
  }
}

// Trip Rating Screen
class TripRatingScreen extends StatefulWidget {
  final String passengerName;
  final String passengerId;
  final String? avatarUrl;
  final int rideId;
  final int driverId;

  const TripRatingScreen({
    Key? key,
    required this.passengerName,
    required this.passengerId,
    this.avatarUrl,
    required this.rideId,
    required this.driverId,
  }) : super(key: key);

  @override
  State<TripRatingScreen> createState() => _TripRatingScreenState();
}

class _TripRatingScreenState extends State<TripRatingScreen> {
  late RatingCubit _ratingCubit;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _ratingCubit = RatingCubit();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Rate Your Trip'),
      ),
      body: BlocProvider(
        create: (context) => _ratingCubit,
        child: TripRatingBody(
          commentController: _commentController,
          rideId: widget.rideId,
          driverId: widget.driverId,
          passengerName: widget.passengerName,
          passengerId: widget.passengerId,
          avatarUrl: widget.avatarUrl,
        ),
      ),
    );
  }
}

// Trip Rating Body Widget
class TripRatingBody extends StatelessWidget {
  final TextEditingController commentController;
  final int rideId;
  final int driverId;
  final String passengerName;
  final String passengerId;
  final String? avatarUrl;

  const TripRatingBody({
    Key? key,
    required this.commentController,
    required this.rideId,
    required this.driverId,
    required this.passengerName,
    required this.passengerId,
    this.avatarUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Section
          const ProfileSection(),

          const SizedBox(height: 16),

          // Star Rating Widget
          const StarRatingWidget(),

          const SizedBox(height: 16),

          // Comment Input
          CommentInputWidget(),

          const SizedBox(height: 16),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B5AFB),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              final rating = context.read<RatingCubit>().state;
              final feedbackData = {
                "ride_id": rideId,
                "passenger_rating": rating.toDouble(),
                "driver_rating": rating.toDouble(),
                "passenger_comments": commentController.text,
                "driver_comments": commentController.text,
                "driver_id": driverId,
                "passenger_id": int.tryParse(passengerId) ?? 0,
              };
              final response = await submitFeedback(feedbackData);
              if (response['success'] == true) {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Thank you!'),
                    content: const Text('Your feedback has been submitted.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const DriverHomeScreen(),
                          ),
                        ),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              } else {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Error'),
                    content: Text(response['data']?.toString() ??
                        'Failed to submit feedback.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              }
            },
            child: const Text('Submit Review',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// Profile Section
class ProfileSection extends StatelessWidget {
  const ProfileSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        children: [
          // Profile Image
          CircleAvatar(
            radius: 30,
            backgroundImage: AssetImage('assets/images/Frame 1.png'),
          ),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Rate your trip',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Star Rating Widget
class StarRatingWidget extends StatelessWidget {
  const StarRatingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RatingCubit, int>(
      builder: (context, currentRating) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            return IconButton(
              icon: Icon(
                index < currentRating ? Icons.star : Icons.star_border,
                color: Colors.yellow[700],
                size: 40,
              ),
              onPressed: () {
                context.read<RatingCubit>().setRating(index + 1);
              },
            );
          }),
        );
      },
    );
  }
}

// Comment Input Widget
class CommentInputWidget extends StatelessWidget {
  final TextEditingController _commentController = TextEditingController();

  CommentInputWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _commentController,
      maxLines: 4,
      decoration: InputDecoration(
        hintText: 'Write a comment',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}

Future<Map<String, dynamic>> submitFeedback(Map<String, dynamic> data) async {
  final url = Uri.parse('https://dd26-41-33-95-84.ngrok-free.app/api/feedback');
  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(data),
  );
  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    return jsonDecode(response.body);
  }
}
