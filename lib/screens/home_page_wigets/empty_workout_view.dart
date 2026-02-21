import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

class EmptyWorkoutView extends StatelessWidget {
  final ColorScheme cs;

  const EmptyWorkoutView({super.key, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.green.withOpacity(0.12),
            ),
            child: Center(
              child: Lottie.asset(
                'assets/checkmark.json',
                width: 170,
                height: 170,
                repeat: true,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Workout Completed!",
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36),
            child: Text(
              "Great job! You’ve successfully completed today’s workout.\n\n"
              "Take some time to rest, hydrate yourself,\n"
              "and come back even stronger tomorrow 💪",
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 14.5,
                height: 1.6,
                fontWeight: FontWeight.w500,
                color: cs.onSurface.withOpacity(0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
