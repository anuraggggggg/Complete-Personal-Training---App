import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mighty_fitness/app_theme.dart';
import 'package:mighty_fitness/controllers/home_page_controller/home_page_workout_list_controller.dart';
import 'package:mighty_fitness/controllers/workout_mode_controller/workout_mode_controller.dart';
import 'package:mighty_fitness/extensions/common.dart';
import 'package:mighty_fitness/extensions/extension_util/int_extensions.dart';
import 'package:mighty_fitness/extensions/extension_util/list_extensions.dart';
import 'package:mighty_fitness/extensions/extension_util/string_extensions.dart';
import 'package:mighty_fitness/extensions/extension_util/widget_extensions.dart';
import 'package:mighty_fitness/extensions/shared_pref.dart';
import 'package:mighty_fitness/extensions/text_styles.dart';
import 'package:mighty_fitness/main.dart';
import 'package:mighty_fitness/models/register_request.dart';
import 'package:mighty_fitness/network/rest_api.dart';
import 'package:mighty_fitness/screens/dashboard_screen.dart';
import 'package:mighty_fitness/utils/app_common.dart';
import 'package:mighty_fitness/utils/app_constants.dart';

class SignUpStep12Component extends StatefulWidget {
  const SignUpStep12Component({super.key});

  @override
  State<SignUpStep12Component> createState() => _SignUpStep12ComponentState();
}

class _SignUpStep12ComponentState extends State<SignUpStep12Component> {
  bool tappedHome = false;
  bool tappedGym = false;
  bool isSubmitting = false;

  final workoutCtrl = Get.put(WorkoutModeController());

  Future<void> _registerWithWorkoutMode(int modeId) async {
    if (isSubmitting || modeId <= 0) return;

    isSubmitting = true;
    appStore.setLoading(true);

    await userStore.setWorkoutLoc(modeId.toString());
    hideKeyboard(context);

    try {
      UserProfile userProfile = UserProfile();

      userProfile.age =
          userStore.age.toString().isNotEmpty ? userStore.age : null;
      userProfile.height = userStore.height.validate();
      userProfile.heightUnit = userStore.heightUnit.validate();
      userProfile.weight = userStore.weight.validate();
      userProfile.weightUnit = userStore.weightUnit.validate();
      userProfile.goal = int.tryParse(userStore.goal);
      userProfile.workoutMode = int.tryParse(userStore.workLoc);
      userProfile.workoutLevel = int.tryParse(userStore.level);
      userProfile.workoutDays = userStore.workoutDays.join(",");
      userProfile.workoutTime = userStore.workoutDaysNo;
      userProfile.hasInjury =
          userStore.injury.toLowerCase() == "yes" ? 1 : 0;
      userProfile.equipmentIds = userStore.equipments.join(",");

      Map<String, dynamic> req = {
        'first_name': userStore.fName.validate(),
        'last_name': userStore.lName.validate(),
        'username': getBoolAsync(IS_OTP) != true
            ? userStore.email.validate()
            : userStore.phoneNo.validate(),
        'email': userStore.email.validate(),
        'password': userStore.password.validate(),
        'user_type': LoginUser,
        'status': statusActive,
        'phone_number': userStore.phoneNo.validate(),
        'gender': userStore.gender.validate().toLowerCase(),
        'user_profile': userProfile.toJson(),
        "player_id": getStringAsync(PLAYER_ID).validate(),
        "goal": userStore.goal.validate(),
        "workout_mode": userStore.workLoc.validate(),
        "workout_level": userStore.level.validate(),
        "workout_days_no": userStore.workoutDaysNo.validate(),
        "workout_days": userStore.workoutDays.validate(),
        "has_injury":
            userStore.injury.validate().toLowerCase() == 'yes' ? 1 : 0,
        "joints": userStore.injuredJoints.validate(),
        "injury_info": userStore.medCond.validate(),
        "equipments": userStore.equipments.validate(),
        if (getBoolAsync(IS_OTP) != false) "login_type": LoginTypeOTP,
      };

      final res = await registerApi(req);

      await userStore.setLogin(true);
      await userStore.setToken(res.data!.apiToken.validate());

      await setValue(IS_LOGIN, true);
      await setValue(TOKEN, res.data!.apiToken.validate());
      await setValue(USER_ID, res.data!.id);
      await setValue("SHOW_COUPON_DIALOG", true);

      if (Get.isRegistered<HomePageController>()) {
        Get.delete<HomePageController>(force: true);
      }

      await getUSerDetail(context, res.data!.id);

      if (mounted) {
        DashboardScreen().launch(context, isNewTask: true);
      }
    } catch (e) {
      toast(e.toString());
    } finally {
      appStore.setLoading(false);
      isSubmitting = false;
    }
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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
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
                            if (isSubmitting) return;
                            setState(() {
                              tappedHome = true;
                              tappedGym = false;
                            });
                            await _registerWithWorkoutMode(workoutCtrl.homeId.value);
                          },
                        ),
                        _buildWorkoutCard(
                          label: 'Gym',
                          imagePath: 'assets/gym.png',
                          selected: tappedGym,
                          onTap: () async {
                            if (isSubmitting) return;
                            setState(() {
                              tappedGym = true;
                              tappedHome = false;
                            });
                            await _registerWithWorkoutMode(workoutCtrl.gymId.value);
                          },
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      'Select Home or Gym to complete registration',
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
          color: selected ? primary.withOpacity(0.15) : Colors.white.withOpacity(0.05),
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
