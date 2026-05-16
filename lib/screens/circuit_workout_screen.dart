import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:mighty_fitness/controllers/circuite_exercise_controller/circuite_exercise_controller.dart';
import 'package:mighty_fitness/screens/circuit_exercise_detail_screen.dart';

class CircuitWorkoutScreen extends StatelessWidget {
  CircuitWorkoutScreen({super.key});

  final CircularWorkoutController controller =
      Get.find<CircularWorkoutController>();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Color(0xFF1D1D1D),

      // ───────── APP BAR ─────────
      appBar: AppBar(
        backgroundColor: Color(0xFF1D1D1D),
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Icon(
              Icons.arrow_back_ios_new,
              size: 20,
              color: cs.onSurface,
            ),
          ),
        ),
        title: Text(
          "Circuit Workout",
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: cs.onSurface,
          ),
        ),
      ),

      // ───────── BODY ─────────
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(
            child: CircularProgressIndicator(color: cs.primary),
          );
        }

        if (controller.workouts.isEmpty) {
          return Center(
            child: Text(
              "No circuit workout available",
              style: GoogleFonts.montserrat(
                color: cs.onSurface.withOpacity(0.6),
              ),
            ),
          );
        }

        return Container(
          color: Colors.transparent,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.workouts.length,
            itemBuilder: (context, wIndex) {
              final workout = controller.workouts[wIndex];
              final exercises = workout.exercises ?? [];

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ───── WORKOUT TITLE ─────
                  Text(
                    workout.workoutName ?? "Workout",
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ───── WARMUP CARD ─────
                  if (workout.warmupVideo != null &&
                      workout.warmupVideo!.isNotEmpty)
                    _warmupCard(
                      cs: cs,
                      workoutName: workout.workoutName ?? "Warmup",
                      onTap: () {
                        if (exercises.isEmpty) return;
                        Get.to(
                          () => CircuitExerciseDetailScreen(
                            exercise: exercises.first,
                            index: 0,
                          ),
                          transition: Transition.fadeIn,
                        );
                      },
                    ),

                  const SizedBox(height: 16),

                  // ───── EXERCISES ─────
                  ...List.generate(exercises.length, (index) {
                    final ex = exercises[index];

                    return GestureDetector(
                      onTap: () {
                        Get.to(
                          () => CircuitExerciseDetailScreen(
                            exercise: ex,
                            index: index,
                          ),
                          transition: Transition.rightToLeft,
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(
                              sigmaX: 10, sigmaY: 10),
                          child: Container(
                            margin:
                                const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.04),
                              borderRadius:
                                  BorderRadius.circular(16),
                              border: Border.all(
                                color:
                                    Colors.white.withOpacity(0.12),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    ex.title ?? "",
                                    style: GoogleFonts.montserrat(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: cs.onSurface,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.play_circle_fill_rounded,
                                  color: cs.primary,
                                  size: 28,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 28),
                ],
              );
            },
          ),
        );
      }),
    );
  }

  // ───────── WARMUP CARD ─────────
  Widget _warmupCard({
    required ColorScheme cs,
    required String workoutName,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              cs.primary.withOpacity(0.9),
              cs.primary.withOpacity(0.6),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: cs.primary.withOpacity(0.35),
              blurRadius: 22,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(
              Icons.play_circle_fill_rounded,
              color: Colors.white,
              size: 42,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "START WARMUP",
                    style: GoogleFonts.montserrat(
                      color: Colors.white70,
                      fontSize: 11,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    workoutName,
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
