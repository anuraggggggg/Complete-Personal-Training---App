import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mighty_fitness/extensions/shared_pref.dart';
import 'package:mighty_fitness/main.dart';
import 'package:mighty_fitness/models/body_type_list.dart';
import 'package:mighty_fitness/models/level_type_list.dart';
import 'package:mighty_fitness/network/network_utils.dart';
import 'package:mighty_fitness/screens/dashboard_screen.dart';
import 'package:mighty_fitness/models/workout_type_list.dart';

class CompleteProfileController extends GetxController {
  // ================= GLOBAL STATE =================
  final RxBool isLoading = false.obs;

  // ================= TEXT CONTROLLERS =================
  final ageCtrl = TextEditingController();
  final weightCtrl = TextEditingController();
  final heightCtrl = TextEditingController();
  final workoutTimeCtrl = TextEditingController();

  // ================= BASIC VALUES =================
  final RxString weightUnit = 'kg'.obs;
  final RxString heightUnit = 'cm'.obs;

  // ================= GOAL (workouttype-list API) =================
  final RxBool isGoalLoading = false.obs;
  final RxList<Data> goalList = <Data>[].obs;
  final Rx<Data?> selectedGoal = Rx<Data?>(null);

  // ================= LEVEL (level-list API) =================
  final RxBool isLevelLoading = false.obs;
  final RxList<LevelData> levelList = <LevelData>[].obs;
  final Rx<LevelData?> selectedLevel = Rx<LevelData?>(null);

  // ================= WORKOUT DAYS =================
  // ================= WORKOUT DAYS COUNT =================
  final RxInt workoutDaysCount = 3.obs; // default 3

  // ================= BODY PART (bodypart-list API) =================
  final RxBool isBodyPartLoading = false.obs;
  final RxList<BodyPartData> bodyPartList = <BodyPartData>[].obs;
  final Rx<BodyPartData?> selectedBodyPart = Rx<BodyPartData?>(null);

  // ================= INIT =================
  @override
  void onInit() {
    super.onInit();
    fetchGoalList();
    fetchLevelList();
    fetchBodyPartList();
  }

  // ================= FETCH GOAL LIST =================
  Future<void> fetchGoalList() async {
    try {
      isGoalLoading.value = true;

      final response = await buildHttpResponse(
        'workouttype-list',
        method: HttpMethod.GET,
      );

      if (response.statusCode != 200) {
        throw Exception('Goal API failed');
      }

      final decoded = jsonDecode(response.body);
      final model = WorkoutTypeList.fromJson(decoded);

      goalList.assignAll(model.data ?? []);

      if (goalList.isNotEmpty) {
        selectedGoal.value = goalList.first;
        selectedGoal.refresh();
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load goals');
    } finally {
      isGoalLoading.value = false;
    }
  }

  // ================= FETCH LEVEL LIST =================
  Future<void> fetchLevelList() async {
    try {
      isLevelLoading.value = true;

      final response = await buildHttpResponse(
        'level-list',
        method: HttpMethod.GET,
      );

      if (response.statusCode != 200) {
        throw Exception('Level API failed');
      }

      final decoded = jsonDecode(response.body);
      final model = LevelTypeList.fromJson(decoded);

      levelList.assignAll(model.data ?? []);

      if (levelList.isNotEmpty) {
        selectedLevel.value = levelList.first;
        selectedLevel.refresh();
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load levels');
    } finally {
      isLevelLoading.value = false;
    }
  }

  Future<void> submitProfile() async {
    if (!_isFormValid()) return;

    try {
      isLoading.value = true;
      final age = int.tryParse(ageCtrl.text.trim());
      final workoutTime = int.tryParse(workoutTimeCtrl.text.trim()) ?? 30;
      if (age == null) {
        Get.snackbar('Validation', 'Enter a valid age');
        return;
      }

      final email = userStore.email.isNotEmpty
          ? userStore.email
          : getStringAsync("TEMP_EMAIL");
      final firstName = userStore.fName.isNotEmpty
          ? userStore.fName
          : getStringAsync("TEMP_FIRST_NAME");
      final lastName = userStore.lName.isNotEmpty
          ? userStore.lName
          : getStringAsync("TEMP_LAST_NAME");

      /// 🔥 SAFE USERNAME (backend required)
      final username = userStore.displayName.isNotEmpty
          ? userStore.displayName
          : email.split('@').first;

      final request = {
        // ✅ REQUIRED USER FIELDS
        "username": username,
        "email": email,
        "first_name": firstName,
        "last_name": lastName,

        // OPTIONAL
        "player_id": null,

        // ✅ PROFILE DATA
        "user_profile": {
          "age": age,
          "weight": weightCtrl.text,
          "weight_unit": weightUnit.value,
          "height": heightCtrl.text,
          "height_unit": heightUnit.value,

          "goal": selectedGoal.value!.id,
          "workout_level": selectedLevel.value!.id,
          "workout_days": workoutDaysCount.value,
          "workout_time": workoutTime,
          "workout_mode": selectedGoal.value!.id,

          "has_injury": 0,
          "injury_info": null,

          // 🔥 backend expects string / csv
          "equipment_ids": selectedBodyPart.value!.id.toString(),
        }
      };

      debugPrint("📤 UPDATE PROFILE REQUEST => $request");

      final response = await buildHttpResponse(
        'update-profile',
        request: request,
        method: HttpMethod.POST,
      );

      debugPrint("📡 STATUS => ${response.statusCode}");
      debugPrint("📨 BODY => ${response.body}");

      if (response.statusCode != 200) {
        throw Exception("Update profile failed");
      }

      /// ✅ SAVE LOCALLY
      userStore.setAge(ageCtrl.text);
      userStore.setWeight(weightCtrl.text);
      userStore.setHeight(heightCtrl.text);
      userStore.setWeightUnit(weightUnit.value);
      userStore.setHeightUnit(heightUnit.value);

      Get.snackbar(
        "Success",
        "Profile updated successfully",
        snackPosition: SnackPosition.TOP,
      );

      Get.offAll(() => DashboardScreen());
    } catch (e) {
      debugPrint("❌ PROFILE UPDATE ERROR => $e");

      Get.snackbar(
        "Error",
        "Profile update failed",
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // ================= FETCH BODY PART LIST =================
  Future<void> fetchBodyPartList() async {
    try {
      isBodyPartLoading.value = true;

      debugPrint('🚀 [BodyPart] Fetch started');

      final response = await buildHttpResponse(
        'bodypart-list',
        method: HttpMethod.GET,
      );

      debugPrint('📡 [BodyPart] STATUS => ${response.statusCode}');
      debugPrint('📨 [BodyPart] BODY => ${response.body}');

      if (response.statusCode != 200) {
        throw Exception(
          'BodyPart API failed | '
          'Status: ${response.statusCode} | '
          'Body: ${response.body}',
        );
      }

      final decoded = jsonDecode(response.body);
      final model = BodyPartTypeList.fromJson(decoded);

      bodyPartList.assignAll(model.data);

      if (bodyPartList.isNotEmpty) {
        selectedBodyPart.value = bodyPartList.first;
        selectedBodyPart.refresh();
      }

      debugPrint('✅ [BodyPart] Loaded: ${bodyPartList.length}');
    } catch (e, s) {
      // 🔥 FULL ERROR PRINT
      debugPrint('❌ [BodyPart] ERROR => $e');
      debugPrint('🧵 [BodyPart] STACKTRACE => $s');

      Get.snackbar(
        'Error',
        e.toString(), // 👈 REAL ERROR MESSAGE
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isBodyPartLoading.value = false;
      debugPrint('🏁 [BodyPart] Fetch finished');
    }
  }

  bool _isFormValid() {
    if (ageCtrl.text.isEmpty) {
      Get.snackbar('Validation', 'Enter age');
      return false;
    }

    if (weightCtrl.text.isEmpty) {
      Get.snackbar('Validation', 'Enter weight');
      return false;
    }

    if (heightCtrl.text.isEmpty) {
      Get.snackbar('Validation', 'Enter height');
      return false;
    }

    if (selectedGoal.value == null) {
      Get.snackbar('Validation', 'Select goal');
      return false;
    }

    if (selectedLevel.value == null) {
      Get.snackbar('Validation', 'Select workout level');
      return false;
    }

    if (selectedBodyPart.value == null) {
      Get.snackbar('Validation', 'Select body part');
      return false;
    }

    if (workoutDaysCount.value == 0) {
      Get.snackbar('Validation', 'Select workout days');
      return false;
    }

    return true;
  }

//   // ================= TOGGLE DAY =================
//  void toggleDay(String day) {
//   selectedDays.contains(day)
//       ? selectedDays.remove(day)
//       : selectedDays.add(day);
// }

  // ================= DISPOSE =================
  @override
  void onClose() {
    ageCtrl.dispose();
    weightCtrl.dispose();
    heightCtrl.dispose();
    workoutTimeCtrl.dispose();
    super.onClose();
  }
}



