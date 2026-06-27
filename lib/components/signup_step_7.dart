import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mighty_fitness/controllers/home_page_controller/home_page_workout_list_controller.dart';
import 'package:mighty_fitness/extensions/app_button.dart';
import 'package:mighty_fitness/extensions/common.dart';
import 'package:mighty_fitness/extensions/extension_util/int_extensions.dart';
import 'package:mighty_fitness/extensions/extension_util/list_extensions.dart';
import 'package:mighty_fitness/extensions/extension_util/string_extensions.dart';
import 'package:mighty_fitness/extensions/shared_pref.dart';
import 'package:mighty_fitness/extensions/text_styles.dart';
import 'package:mighty_fitness/main.dart';
import 'package:mighty_fitness/models/register_request.dart';
import 'package:mighty_fitness/network/rest_api.dart';
import 'package:mighty_fitness/utils/app_common.dart';
import 'package:mighty_fitness/utils/app_constants.dart';
import 'package:mighty_fitness/utils/subscription_navigation.dart';

class SignUpStep7Component extends StatefulWidget {
  const SignUpStep7Component({super.key});

  @override
  State<SignUpStep7Component> createState() => _SignUpStep7ComponentState();
}

class _SignUpStep7ComponentState extends State<SignUpStep7Component> {
  final List<int> workoutOptions = [3, 6]; // only 3 and 6 days
  int selectedIndex = 0;
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final savedDays = resolveWorkoutDaysCount(userStore.workoutDaysNo);
    selectedIndex = workoutOptions.indexOf(savedDays);
    if (selectedIndex < 0) selectedIndex = 0;
  }

  List<String> _defaultWorkoutDays(int count) {
    const weekdayPresets = <int, List<String>>{
      3: <String>['Monday', 'Wednesday', 'Friday'],
      6: <String>[
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
      ],
    };

    const allWeekdays = <String>[
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    if (weekdayPresets.containsKey(count)) {
      return List<String>.from(weekdayPresets[count]!);
    }

    return allWeekdays.take(count.clamp(1, allWeekdays.length)).toList();
  }

  Future<void> _completeRegistration() async {
    if (isSubmitting) return;

    isSubmitting = true;
    appStore.setLoading(true);

    final selectedWorkoutDaysCount = workoutOptions[selectedIndex];
    final workoutDays = _defaultWorkoutDays(selectedWorkoutDaysCount);

    await userStore.setWorkoutDaysNo(selectedWorkoutDaysCount);
    await userStore.setWorkoutDays(workoutDays);
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
      userProfile.workoutDaysNo = selectedWorkoutDaysCount.toString();
      userProfile.workoutDays = selectedWorkoutDaysCount.toString();
      userProfile.workoutTime = userStore.workoutDaysNo;
      userProfile.hasInjury = userStore.injury.toLowerCase() == "yes" ? 1 : 0;
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
        "workout_days": workoutDays,
        "has_injury":
            userStore.injury.validate().toLowerCase() == 'yes' ? 1 : 0,
        "joints": userStore.injuredJoints.validate(),
        "injury_info": userStore.medCond.validate(),
        "equipments": userStore.equipments.validate(),
        "accepted_terms": 1,
        "accepted_privacy": 1,
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

      openPostAuthDestination(forceFreeAutopayPrompt: true);
    } catch (e) {
      toast(e.toString());
    } finally {
      appStore.setLoading(false);
      isSubmitting = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      // backgroundColor: cs.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          20.height,

          /// ================= TITLE =================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              "How Many Days Can You Workout?",
              style: boldTextStyle(size: 22).copyWith(color: cs.onSurface),
            ),
          ),

          20.height,

          /// ================= OPTIONS =================
          Center(
            child: Wrap(
              spacing: 18,
              children: List.generate(workoutOptions.length, (index) {
                final bool selected = selectedIndex == index;

                return GestureDetector(
                  onTap: () {
                    setState(() => selectedIndex = index);
                  },
                  child: Container(
                    height: 90,
                    width: 100,
                    decoration: BoxDecoration(
                      color: selected
                          ? cs.primary
                          : (isDark ? cs.surface : cs.surfaceContainerHighest),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? cs.primary
                            : cs.onSurface.withOpacity(0.15),
                        width: 1.2,
                      ),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: cs.primary.withOpacity(0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ]
                          : [],
                    ),
                    child: Center(
                      child: Text(
                        '${workoutOptions[index]}',
                        style: TextStyle(
                          color: selected ? cs.onPrimary : cs.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

          60.height,

          /// ================= NEXT BUTTON =================
          Padding(
            padding: const EdgeInsets.all(16),
            child: AppButton(
              text: languages.lblNext,
              width: MediaQuery.sizeOf(context).width,
              color: cs.primary,
              onTap: () async {
                if (kDebugMode) {
                  print(
                      "Selected workout days: ${workoutOptions[selectedIndex]}");
                }
                await _completeRegistration();
              },
            ),
          ),
        ],
      ),
    );
  }
}
