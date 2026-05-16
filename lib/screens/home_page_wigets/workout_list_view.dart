import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mighty_fitness/controllers/home_page_controller/home_page_workout_list_controller.dart';
import 'package:mighty_fitness/models/cuircuite_exercise_model.dart';

class WorkoutListView extends StatefulWidget {
  final Workout todayWorkout;

  const WorkoutListView({
    super.key,
    required this.todayWorkout,
  });

  @override
  State<WorkoutListView> createState() => _WorkoutListViewState();
}

class _WorkoutListViewState extends State<WorkoutListView> {
  final HomePageController controller =
      Get.find<HomePageController>();

  bool _imagesPrecached = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_imagesPrecached) {
      _imagesPrecached = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        for (final ex in widget.todayWorkout.exercises ?? []) {
          final url = ex.exerciseGifUrl; // ✅ FIXED
          if (url != null && url.isNotEmpty) {
            precacheImage(
              CachedNetworkImageProvider(url),
              context,
            );
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final today = widget.todayWorkout;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          "Today's ${today.workoutName ?? ''}",
          style: GoogleFonts.montserrat(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: cs.onSurface,
          ),
        ),

        const SizedBox(height: 24),

        Obx(
          () => controller.isWorkoutCompleted.value
              ? _completedBox()
              : _attendanceButton(today.workoutId ?? 0),
        ),
      ],
    );
  }

  Widget _completedBox() => const SizedBox();

  Widget _attendanceButton(int id) => const SizedBox();
}
