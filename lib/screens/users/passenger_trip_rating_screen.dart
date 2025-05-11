import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Rating Cubit for managing rating state
class RatingCubit extends Cubit<int> {
  RatingCubit() : super(0);

  void setRating(int rating) {
    emit(rating);
  }
}

// Trip Rating Screen
class PassengerTripRatingScreen extends StatelessWidget {
  const PassengerTripRatingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4CD964), // Matching screen background
      body: SafeArea(
        child: BlocProvider(
          create: (context) => RatingCubit(),
          child: const TripRatingBody(),
        ),
      ),
    );
  }
}

// Trip Rating Body Widget
class TripRatingBody extends StatelessWidget {
  const TripRatingBody({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Back Button and Empty Space
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),

        // Main Content Container
        Expanded(
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Profile Section
                  const ProfileSection(),

                  const SizedBox(height: 20),

                  // Trip Question
                  const Text(
                    'How is your trip?',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    'Your feedback will help improve\ndriving experience',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Star Rating Widget
                  const StarRatingWidget(),

                  const Spacer(),

                  // Submit Button
                  ElevatedButton(
                    onPressed: () {
                      // TODO: Implement submit logic
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CD964),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: const Text(
                      'Submit Review',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Profile Section
class ProfileSection extends StatelessWidget {
  const ProfileSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundImage: AssetImage('assets/images/Passenger.png'),
        ),
        SizedBox(height: 10),
        Text(
          'Gregory Smith',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
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
                color: const Color(0xFFFFC700),
                size: 50,
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
