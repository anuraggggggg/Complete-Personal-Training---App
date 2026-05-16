import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mighty_fitness/app_theme.dart';
import 'package:mighty_fitness/controllers/workout_mode_controller/workout_mode_controller.dart';
import 'package:mighty_fitness/extensions/text_styles.dart';
import 'package:mighty_fitness/main.dart';

class SignUpStep12Component extends StatefulWidget {
  const SignUpStep12Component({super.key});

  @override
  State<SignUpStep12Component> createState() => _SignUpStep12ComponentState();
}

class _SignUpStep12ComponentState extends State<SignUpStep12Component> {
  bool tappedHome = false;
  bool tappedGym = false;

  final workoutCtrl = Get.put(WorkoutModeController());

  Future<void> _saveWorkoutModeAndContinue(int modeId) async {
    if (modeId <= 0) return;
    await userStore.setWorkoutLoc(modeId.toString());
    appStore.signUpIndex = 6;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        if (workoutCtrl.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return Stack(
          children: [
            Positioned.fill(
              child: FittedBox(
                fit: BoxFit.cover,
                child: Image.asset(
                  tappedHome ? 'assets/home.png' : 'assets/gym.png',
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.6),
                    Colors.black.withOpacity(0.9),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                child: Column(
                  children: [
                    Text(
                      'Where Do You Workout ?',
                      style: boldTextStyle(size: 24, color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 200),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildWorkoutCard(
                          label: 'Home',
                          imagePath: 'assets/home.png',
                          selected: tappedHome,
                          onTap: () async {
                            setState(() {
                              tappedHome = true;
                              tappedGym = false;
                            });
                            await _saveWorkoutModeAndContinue(
                                workoutCtrl.homeId.value);
                          },
                        ),
                        _buildWorkoutCard(
                          label: 'Gym',
                          imagePath: 'assets/gym.png',
                          selected: tappedGym,
                          onTap: () async {
                            setState(() {
                              tappedGym = true;
                              tappedHome = false;
                            });
                            await _saveWorkoutModeAndContinue(
                                workoutCtrl.gymId.value);
                          },
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      'Select Home or Gym to continue',
                      style: secondaryTextStyle(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildWorkoutCard({
    required String label,
    required String imagePath,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        width: 140,
        height: 160,
        padding: const EdgeInsets.all(12),
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          color: selected
              ? primary.withOpacity(0.15)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? primary : Colors.transparent,
            width: 2,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: primary.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.fitHeight,
                  width: double.infinity,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
