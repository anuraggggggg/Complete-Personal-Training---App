import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:mighty_fitness/controllers/home_page_controller/home_page_workout_list_controller.dart';
import 'package:mighty_fitness/extensions/app_button.dart';
import 'package:mighty_fitness/extensions/common.dart';
import 'package:mighty_fitness/extensions/extension_util/context_extensions.dart';
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

class SignUpStep10Component extends StatefulWidget {
  const SignUpStep10Component({super.key});

  @override
  State<SignUpStep10Component> createState() => _SignUpStep10ComponentState();
}

class _SignUpStep10ComponentState extends State<SignUpStep10Component> {
  String? selected; // yes / no

  // ================= SAVE DATA =================
  Future<void> saveData() async {
    hideKeyboard(context);

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

    appStore.setLoading(true);

await registerApi(req).then((res) async {
  appStore.setLoading(false);

  /// ✅ LOGIN STATE (MEMORY)
  userStore.setLogin(true);
  userStore.setToken(res.data!.apiToken.validate());

  /// ✅ LOGIN STATE (PERSISTENT - SPLASH SAFE)
  await setValue(IS_LOGIN, true);
  await setValue(TOKEN, res.data!.apiToken.validate());
  await setValue(USER_ID, res.data!.id);

  /// OPTIONAL
  await setValue("SHOW_COUPON_DIALOG", true);

  /// 🧹 CLEAR OLD USER CONTROLLERS
  if (Get.isRegistered<HomePageController>()) {
    Get.delete<HomePageController>(force: true);
  }

  /// 🔄 FETCH FRESH USER PROFILE (WAIT!)
  await getUSerDetail(context, res.data!.id);

  /// 🚀 GO TO DASHBOARD (NEW TASK)
  DashboardScreen().launch(context, isNewTask: true);
});


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
          60.height,

          /// ================= TITLE =================
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              "Do You Have Any Injury?",
              style: boldTextStyle(size: 22)
                  .copyWith(color: cs.onSurface),
            ),
          ),

          80.height,

          /// ================= OPTIONS =================
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildOption("Yes", cs, isDark),
              _buildOption("No", cs, isDark),
            ],
          ),

          80.height,

          /// ================= NEXT BUTTON =================
          Padding(
            padding: const EdgeInsets.all(16),
            child: AppButton(
              text: languages.lblNext,
              width: context.width(),
              color: cs.primary,
              onTap: () async {
                if (selected == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: cs.primary,
                      content: Text(
                        "Please select an option",
                        style: TextStyle(
                          color: cs.onPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                  return;
                }

                if (selected == "no") {
                  await saveData();
                } else {
                  appStore.signUpIndex = 9;
                  setState(() {});
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // ================= OPTION CARD =================
  Widget _buildOption(String value, ColorScheme cs, bool isDark) {
    final bool isSelected = selected == value.toLowerCase();

    return GestureDetector(
      onTap: () {
        setState(() {
          selected = value.toLowerCase();
          userStore.setInjury(selected!);
        });
      },
      child: Container(
        height: 70,
        width: 130,
        decoration: BoxDecoration(
          color: isSelected
              ? cs.primary
              : (isDark ? cs.surface : cs.surfaceContainerHighest),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? cs.primary
                : cs.onSurface.withOpacity(0.15),
          ),
          boxShadow: isSelected
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
            value,
            style: TextStyle(
              color:
                  isSelected ? cs.onPrimary : cs.onSurface,
              fontWeight: FontWeight.w600,
              fontSize: 19,
            ),
          ),
        ),
      ),
    );
  }
}
