import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mighty_fitness/extensions/extension_util/string_extensions.dart';
import 'package:mighty_fitness/extensions/shared_pref.dart';
import 'package:mighty_fitness/main.dart';
import 'package:mighty_fitness/models/advance_and_begineer_model.dart';
import 'package:mighty_fitness/models/wrokout_muscle_gain_and_loss_list.dart';
import 'package:mighty_fitness/models/workout_type_list.dart';
import 'package:mighty_fitness/network/network_utils.dart';
import 'package:mighty_fitness/controllers/workout_mode_update_controller/workout_mode_controller.dart';
import 'package:mighty_fitness/service/firebase_user_activity_service.dart';
import 'package:mighty_fitness/utils/app_common.dart';
import 'package:mighty_fitness/utils/app_constants.dart';
import 'package:mighty_fitness/utils/subscription_navigation.dart';

class CompleteProfileReintegratedController extends GetxController {
  final RxBool isLoading = false.obs;

  final ageCtrl = TextEditingController();
  final weightCtrl = TextEditingController();
  final heightCtrl = TextEditingController();
  final workoutTimeCtrl = TextEditingController();

  final RxString weightUnit = 'kg'.obs;
  final RxString heightUnit = 'cm'.obs;

  // workout_mode => workouttype-list (WrokoutTypeList / Data)
  final RxBool isWorkoutModeLoading = false.obs;
  final RxList<Data> workoutModeList = <Data>[].obs;
  final Rx<Data?> selectedWorkoutMode = Rx<Data?>(null);

  // workout_level => level-list (AdvanceAndBegineerModel / LevelData)
  final RxBool isWorkoutLevelLoading = false.obs;
  final RxList<AdvanceAndBegineerData> workoutLevelList =
      <AdvanceAndBegineerData>[].obs;
  final Rx<AdvanceAndBegineerData?> selectedWorkoutLevel =
      Rx<AdvanceAndBegineerData?>(null);

  // goal => bodypart-list (WrokoutMuscleGainAndLossList / BodyPartData)
  final RxBool isGoalLoading = false.obs;
  final RxList<WrokoutMuscleGainAndLossData> goalList =
      <WrokoutMuscleGainAndLossData>[].obs;
  final Rx<WrokoutMuscleGainAndLossData?> selectedGoal =
      Rx<WrokoutMuscleGainAndLossData?>(null);

  final RxInt workoutDaysCount = 3.obs;

  @override
  void onInit() {
    super.onInit();
    workoutDaysCount.value = resolveWorkoutDaysCount(
      userStore.workoutDaysNo,
      fallback: getIntAsync(WORKOUT_DAYS_NO, defaultValue: 3),
    );
    fetchWorkoutModes();
    fetchWorkoutLevels();
    fetchGoals();
  }

  Future<void> setSelectedGoal(WrokoutMuscleGainAndLossData? goal) async {
    selectedGoal.value = goal;
    if (goal?.id != null) {
      await userStore.setGoal(goal!.id.toString());
    }
  }

  Future<void> fetchWorkoutModes() async {
    try {
      isWorkoutModeLoading.value = true;
      final response =
          await buildHttpResponse('workouttype-list', method: HttpMethod.GET);
      if (response.statusCode != 200) {
        throw Exception('workouttype-list failed');
      }

      final decoded = jsonDecode(response.body);
      final model = WrokoutTypeList.fromJson(decoded);
      workoutModeList.assignAll(model.data ?? []);
      if (workoutModeList.isNotEmpty) {
        final int? savedModeId = int.tryParse(userStore.workLoc);
        final Data? matchedMode = savedModeId == null
            ? null
            : workoutModeList
                .firstWhereOrNull((item) => item.id == savedModeId);
        selectedWorkoutMode.value =
            matchedMode ?? selectedWorkoutMode.value ?? workoutModeList.first;
      }
    } catch (_) {
      Get.snackbar('Error', 'Failed to load workout modes');
    } finally {
      isWorkoutModeLoading.value = false;
    }
  }

  Future<void> fetchWorkoutLevels() async {
    try {
      isWorkoutLevelLoading.value = true;
      final response =
          await buildHttpResponse('level-list', method: HttpMethod.GET);
      if (response.statusCode != 200) throw Exception('level-list failed');

      final decoded = jsonDecode(response.body);
      final model = AdvanceAndBegineerModel.fromJson(decoded);
      workoutLevelList.assignAll(model.data ?? []);
      if (workoutLevelList.isNotEmpty) {
        final int? savedLevelId = int.tryParse(userStore.level);
        final AdvanceAndBegineerData? matchedLevel = savedLevelId == null
            ? null
            : workoutLevelList
                .firstWhereOrNull((item) => item.id == savedLevelId);
        selectedWorkoutLevel.value = matchedLevel ??
            selectedWorkoutLevel.value ??
            workoutLevelList.first;
      }
    } catch (_) {
      Get.snackbar('Error', 'Failed to load workout levels');
    } finally {
      isWorkoutLevelLoading.value = false;
    }
  }

  Future<void> fetchGoals() async {
    try {
      isGoalLoading.value = true;
      final response =
          await buildHttpResponse('bodypart-list', method: HttpMethod.GET);
      if (response.statusCode != 200) throw Exception('bodypart-list failed');

      final decoded = jsonDecode(response.body);
      final model = WrokoutMuscleGainAndLossList.fromJson(decoded);
      goalList.assignAll(model.data);
      if (goalList.isNotEmpty) {
        final int? savedGoalId = int.tryParse(userStore.goal);
        final WrokoutMuscleGainAndLossData? matchedGoal = savedGoalId == null
            ? null
            : goalList.firstWhereOrNull((item) => item.id == savedGoalId);

        selectedGoal.value =
            matchedGoal ?? selectedGoal.value ?? goalList.first;
      }
    } catch (_) {
      Get.snackbar('Error', 'Failed to load goals');
    } finally {
      isGoalLoading.value = false;
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
          : getStringAsync('TEMP_EMAIL');
      final firstName = userStore.fName.isNotEmpty
          ? userStore.fName
          : getStringAsync('TEMP_FIRST_NAME');
      final lastName = userStore.lName.isNotEmpty
          ? userStore.lName
          : getStringAsync('TEMP_LAST_NAME');
      final providerId = getStringAsync('TEMP_PROVIDER_ID');
      final idToken = getStringAsync('TEMP_ID_TOKEN');
      final accessToken = getStringAsync('TEMP_ACCESS_TOKEN');
      final loginType = getStringAsync('TEMP_LOGIN_TYPE').isNotEmpty
          ? getStringAsync('TEMP_LOGIN_TYPE')
          : 'google';

      final mode = selectedWorkoutMode.value!;
      final level = selectedWorkoutLevel.value!;
      final goal = selectedGoal.value!;
      final workoutDays = _defaultWorkoutDays(workoutDaysCount.value);

      debugPrint(
        'PROFILE SELECTED => '
        'workout_level(id:${level.id}, name:${level.title}), '
        'workout_mode(id:${mode.id}, name:${mode.title}), '
        'goal(id:${goal.id}, name:${goal.title})',
      );

      final request = <String, dynamic>{
        'username': userStore.displayName.isNotEmpty
            ? userStore.displayName
            : email.split('@').first,
        'email': email,
        'provider_id': providerId,
        'login_type': loginType,
        'first_name': firstName,
        'last_name': lastName,
        'player_id': getStringAsync(PLAYER_ID).validate(),
        'user_type': LoginUser,
        'status': statusActive,
        'goal': goal.id,
        'workout_mode': mode.id,
        'workout_level': level.id,
        'workout_days_no': workoutDaysCount.value,
        'workout_days': workoutDays,
        'has_injury': 0,
        'injury_info': null,
        'equipments': <String>[goal.id.toString()],
        'accepted_terms': 1,
        'accepted_privacy': 1,
        'user_profile': <String, dynamic>{
          'age': age,
          'weight': weightCtrl.text,
          'weight_unit': weightUnit.value,
          'height': heightCtrl.text,
          'height_unit': heightUnit.value,
          'goal': goal.id,
          'workout_mode': mode.id,
          'workout_level': level.id,
          'workout_days_no': workoutDaysCount.value,
          'workout_days': workoutDaysCount.value,
          'workout_time': workoutTime,
          'has_injury': 0,
          'injury_info': null,
          'equipment_ids': goal.id.toString(),
        },
      };

      if (idToken.isNotEmpty) request['id_token'] = idToken;
      request['accessToken'] = accessToken.isNotEmpty
          ? accessToken
          : (idToken.isNotEmpty ? idToken : '');
      request['access_token'] = accessToken;

      debugPrint('UPDATE PROFILE REQUEST => $request');

      final response = await buildHttpResponse(
        'google-auth',
        request: request,
        method: HttpMethod.POST,
      );

      debugPrint('STATUS => ${response.statusCode}');
      debugPrint('BODY => ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Profile submit failed');
      }

      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic> && decoded['data'] != null) {
        final data = decoded['data'] as Map<String, dynamic>;
        final apiToken = data['api_token']?.toString() ?? '';
        if (apiToken.isNotEmpty) {
          await setValue(TOKEN, apiToken);
          await setValue(USER_ID, data['id']);
          await setValue(IS_LOGIN, true);
          await setValue(IS_SOCIAL, true);
          await userStore.setToken(apiToken);
          await userStore.setUserID(data['id']);
          await userStore.setLogin(true);
          await FirebaseUserActivityService.instance.trackGoogleAuth(
            user: data,
            request: request,
            action: 'register',
          );
        }
      }

      await userStore.setAge(ageCtrl.text);
      await userStore.setWeight(weightCtrl.text);
      await userStore.setHeight(heightCtrl.text);
      await userStore.setWeightUnit(weightUnit.value);
      await userStore.setHeightUnit(heightUnit.value);
      await userStore.setGoal(goal.id.toString());
      await userStore.setWorkoutLoc(mode.id?.toString() ?? '');
      await userStore.setlevel(level.id?.toString() ?? '');
      await userStore.setWorkoutDaysNo(workoutDaysCount.value);
      await userStore.setWorkoutDays(workoutDays);
      await setValue(WORKOUT_MODE, mode.id ?? 1);

      if (Get.isRegistered<WorkoutModeUpdateController>()) {
        Get.find<WorkoutModeUpdateController>().workoutMode.value =
            mode.id ?? 1;
      }

      openPostAuthDestination(forceFreeAutopayPrompt: true);
    } catch (e) {
      debugPrint('PROFILE SUBMIT ERROR => $e');
      Get.snackbar('Error', 'Profile submit failed');
    } finally {
      isLoading.value = false;
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
    if (selectedWorkoutLevel.value == null) {
      Get.snackbar('Validation', 'Select workout level');
      return false;
    }
    if (selectedWorkoutMode.value == null) {
      Get.snackbar('Validation', 'Select workout mode');
      return false;
    }
    if (selectedGoal.value == null) {
      Get.snackbar('Validation', 'Select goal');
      return false;
    }
    if (workoutDaysCount.value == 0) {
      Get.snackbar('Validation', 'Select workout days');
      return false;
    }
    return true;
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

  @override
  void onClose() {
    ageCtrl.dispose();
    weightCtrl.dispose();
    heightCtrl.dispose();
    workoutTimeCtrl.dispose();
    super.onClose();
  }
}
