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
import 'package:mighty_fitness/utils/app_common.dart';
import 'package:mighty_fitness/utils/app_constants.dart';

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
    workoutDaysCount.value = resolveWorkoutDaysCount(
      userStore.workoutDaysNo,
      fallback: getIntAsync(WORKOUT_DAYS_NO, defaultValue: 3),
    );
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
      final model = WrokoutTypeList.fromJson(decoded);

      goalList.assignAll(model.data ?? []);

      if (goalList.isNotEmpty) {
        final int? savedGoalId = int.tryParse(userStore.workLoc);
        final Data? matchedGoal = savedGoalId == null
            ? null
            : goalList.firstWhereOrNull((item) => item.id == savedGoalId);
        selectedGoal.value =
            matchedGoal ?? selectedGoal.value ?? goalList.first;
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
        final int? savedLevelId = int.tryParse(userStore.level);
        final LevelData? matchedLevel = savedLevelId == null
            ? null
            : levelList.firstWhereOrNull((item) => item.id == savedLevelId);
        selectedLevel.value =
            matchedLevel ?? selectedLevel.value ?? levelList.first;
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
      final providerId = getStringAsync("TEMP_PROVIDER_ID");
      final idToken = getStringAsync("TEMP_ID_TOKEN");
      final loginType = getStringAsync("TEMP_LOGIN_TYPE").isNotEmpty
          ? getStringAsync("TEMP_LOGIN_TYPE")
          : "google";
      final selectedGoalData = selectedGoal.value;
      final selectedLevelData = selectedLevel.value;
      final selectedBodyPartData = selectedBodyPart.value;

      /// 🔥 SAFE USERNAME (backend required)
      final username = userStore.displayName.isNotEmpty
          ? userStore.displayName
          : email.split('@').first;

      final request = {
        // ✅ REQUIRED USER FIELDS
        "username": username,
        "email": email,
        "provider_id": providerId,
        "login_type": loginType,
        "first_name": firstName,
        "last_name": lastName,
        "workout_days_no": workoutDaysCount.value,
        "accepted_terms": 1,
        "accepted_privacy": 1,

        // OPTIONAL
        "player_id": null,

        // ✅ PROFILE DATA
        "user_profile": {
          "age": age,
          "weight": weightCtrl.text,
          "weight_unit": weightUnit.value,
          "height": heightCtrl.text,
          "height_unit": heightUnit.value,

          "goal": selectedBodyPartData?.id ?? selectedGoalData!.id,
          "workout_level": selectedLevelData!.id,
          "workout_days_no": workoutDaysCount.value,
          "workout_days": workoutDaysCount.value,
          "workout_time": workoutTime,
          // "workout_mode": selectedGoalData.id,

          "has_injury": 0,
          "injury_info": null,

          // 🔥 backend expects string / csv
        }
      };

      if (selectedBodyPartData != null) {
        (request["user_profile"] as Map<String, dynamic>)["equipment_ids"] =
            selectedBodyPartData.id.toString();
      }
      if (idToken.isNotEmpty) {
        request["id_token"] = idToken;
      }

      debugPrint("📤 UPDATE PROFILE REQUEST => $request");

      debugPrint(
        "PROFILE MAP => "
        "goal_from_body_part(id:${selectedBodyPartData?.id}, name:${selectedBodyPartData?.title}), "
        "workout_mode_from_dropdown(id:${selectedGoalData?.id}, name:${selectedGoalData?.title}), "
        "level(id:${selectedLevelData?.id}, name:${selectedLevelData?.title}), "
        "bodyPart(id:${selectedBodyPartData?.id}, name:${selectedBodyPartData?.title}), "
        "workout_days:${workoutDaysCount.value}, workout_time:$workoutTime",
      );

      final response = await buildHttpResponse(
        'google-auth',
        request: request,
        method: HttpMethod.POST,
      );

      debugPrint("📡 STATUS => ${response.statusCode}");
      debugPrint("📨 BODY => ${response.body}");

      if (response.statusCode != 200) {
        throw Exception("Update profile failed");
      }
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic> && decoded['data'] != null) {
        final data = decoded['data'] as Map<String, dynamic>;
        final profile = data['user_profile_data'];

        if (profile is Map<String, dynamic>) {
          int? asInt(dynamic v) => int.tryParse(v?.toString() ?? '');

          final resGoalId = asInt(profile['goal']);
          final resLevelId = asInt(profile['workout_level']);
          final resModeId = asInt(profile['workout_mode']);
          final resEquipRaw = profile['equipment_ids'];
          final resEquipId = resEquipRaw is List && resEquipRaw.isNotEmpty
              ? asInt(resEquipRaw.first)
              : asInt(resEquipRaw);

          final goalMatch = goalList.where((e) => e.id == resGoalId);
          final levelMatch = levelList.where((e) => e.id == resLevelId);
          final bodyMatch = bodyPartList.where((e) => e.id == resEquipId);
          final resGoalName =
              goalMatch.isNotEmpty ? goalMatch.first.title : null;
          final resLevelName =
              levelMatch.isNotEmpty ? levelMatch.first.title : null;
          final resBodyName =
              bodyMatch.isNotEmpty ? bodyMatch.first.title : null;

          debugPrint(
            "PROFILE RESPONSE MAP => "
            "goal(id:$resGoalId, name:$resGoalName), "
            "level(id:$resLevelId, name:$resLevelName), "
            "workout_mode(id:$resModeId, name:$resGoalName), "
            "equipment(id:$resEquipId, name:$resBodyName)",
          );
        }

        final apiToken = data['api_token']?.toString() ?? '';
        if (apiToken.isNotEmpty) {
          await setValue(TOKEN, apiToken);
          await setValue(USER_ID, data['id']);
          await setValue(IS_LOGIN, true);
          await setValue(IS_SOCIAL, true);
          await userStore.setToken(apiToken);
          await userStore.setUserID(data['id']);
          await userStore.setLogin(true);
        }
      }

      /// ✅ SAVE LOCALLY
      userStore.setAge(ageCtrl.text);
      userStore.setWeight(weightCtrl.text);
      userStore.setHeight(heightCtrl.text);
      userStore.setWeightUnit(weightUnit.value);
      userStore.setHeightUnit(heightUnit.value);
      userStore.setWorkoutDaysNo(workoutDaysCount.value);
      userStore
          .setWorkoutDays(defaultWorkoutDaysForCount(workoutDaysCount.value));

      Get.offAll(() => DashboardScreen());
    } catch (e) {
      debugPrint("❌ PROFILE UPDATE ERROR => $e");
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
