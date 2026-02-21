import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mighty_fitness/models/home_page_workout_list_request.dart';
import 'package:mighty_fitness/screens/exercise_detail_screen.dart';

class StretchingCard extends StatelessWidget {
  final WorkoutsForToday today;

  const StretchingCard({
    super.key,
    required this.today,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final stretchingVideo = today.stetchVideo ?? "";
    if (stretchingVideo.isEmpty) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () {
        Get.to(
          () => ExerciseDetailsScreen(
            exercise: Exercises.empty(),
            id: 0,
            name: "Stretching",
            videoPath: stretchingVideo,
            instruction: "Stretch properly after workout.",
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 25),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),

          /// 🌙 DARK / ☀️ LIGHT GRADIENT
          gradient: isDark
              ? const LinearGradient(
                  colors: [
                    Color(0xFF0E0E0E),
                    Color(0xFF050505),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : LinearGradient(
                  colors: [
                    cs.surface,
                    cs.surfaceContainerHighest,
                  ],
                ),

          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : cs.onSurface.withOpacity(0.08),
          ),
        ),
        child: Row(
          children: [
            /// 🧘 ICON
            Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark
                    ? Colors.white.withOpacity(0.08)
                    : cs.primary.withOpacity(0.1),
              ),
              child: Icon(
                Icons.self_improvement,
                color: isDark ? Colors.white : cs.primary,
                size: 22,
              ),
            ),

            const SizedBox(width: 14),

            /// TEXT
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Stretching",
                    style: GoogleFonts.montserrat(
                      color: isDark ? Colors.white : cs.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Cool down • Improve flexibility",
                    style: GoogleFonts.montserrat(
                      color: isDark
                          ? Colors.white70
                          : cs.onSurface.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            /// ▶ PLAY BUTTON
            Container(
              height: 36,
              width: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : cs.primary,
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
