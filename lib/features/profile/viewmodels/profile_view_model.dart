import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mighty_fitness/core/mvvm/base_view_model.dart';
import 'package:mighty_fitness/controllers/home_page_controller/home_page_workout_list_controller.dart';
import 'package:mighty_fitness/features/profile/data/profile_repository.dart';
import 'package:mighty_fitness/models/workout_type_response.dart';
import 'package:mighty_fitness/screens/sign_in_screen.dart';
import 'package:mighty_fitness/utils/app_constants.dart';
import 'package:mighty_fitness/extensions/shared_pref.dart';
import 'package:mighty_fitness/main.dart';

class ProfileViewModel extends BaseViewModel {
  ProfileViewModel({ProfileRepository? repository})
      : _repository = repository ?? ProfileRepository();

  final ProfileRepository _repository;

  final RxInt workoutMode = 1.obs;
  final RxInt gymModeId = 1.obs;
  final RxInt homeModeId = 2.obs;
  final RxBool isWorkoutModeLoading = false.obs;
  final RxBool isLoggingOut = false.obs;
  final RxBool isDeletingAccount = false.obs;

  bool get isGym => workoutMode.value == gymModeId.value;
  bool get isHome => workoutMode.value == homeModeId.value;

  @override
  void onInit() {
    super.onInit();
    _initWorkoutModes();
  }

  Future<void> _initWorkoutModes() async {
    final token = await _repository.getToken();
    if (token != null && token.isNotEmpty) {
      final modeResponse = await _repository.fetchWorkoutModes(token: token);
      _extractWorkoutModeIds(modeResponse);
    }
    await _loadSavedMode();
  }

  Future<void> _loadSavedMode() async {
    final int? savedWorkLoc = int.tryParse(userStore.workLoc);
    final int savedMode = savedWorkLoc != null && savedWorkLoc > 0
        ? savedWorkLoc
        : await _repository.getSavedWorkoutMode();
    workoutMode.value = savedMode > 0 ? savedMode : gymModeId.value;
  }

  Future<void> refreshWorkoutModeFromStore() async {
    await _loadSavedMode();
  }

  void _extractWorkoutModeIds(WorkoutTypeResponse? response) {
    final items = response?.data ?? <WorkoutTypeModel>[];
    for (final item in items) {
      final title = (item.title ?? '').trim().toLowerCase();
      if (title.contains('gym') && item.id != null) {
        gymModeId.value = item.id!;
      }
      if (title.contains('home') && item.id != null) {
        homeModeId.value = item.id!;
      }
    }
  }

  Future<void> updateWorkoutMode(int mode) async {
    if (workoutMode.value == mode) {
      _showSnack(
        title: "Already Selected",
        message: mode == gymModeId.value
            ? "Gym mode already active"
            : "Home mode already active",
        isSuccess: false,
      );
      return;
    }

    try {
      isWorkoutModeLoading.value = true;

      final token = await _repository.getToken();
      if (token == null || token.isEmpty) {
        _showSnack(
          title: "Error",
          message: "User not logged in",
          isSuccess: false,
        );
        return;
      }

      final response = await _repository.updateWorkoutMode(
        token: token,
        mode: mode,
      );
      log("WorkoutMode API -> ${response.body}");

      if (response.statusCode == 200) {
        workoutMode.value = mode;
        await _repository.saveWorkoutMode(mode);
        await userStore.setWorkoutLoc(mode.toString());
        await setValue(WORKOUT_MODE, mode);
        if (Get.isRegistered<HomePageController>()) {
          Get.find<HomePageController>().fetchHomePageData(force: true);
        }
        _showSnack(
          title: "Workout Mode Updated",
          message: mode == gymModeId.value
              ? "Gym workout mode activated"
              : "Home workout mode activated",
          isSuccess: true,
        );
      } else {
        _showSnack(
          title: "Failed",
          message: "Unable to update workout mode",
          isSuccess: false,
        );
      }
    } catch (e) {
      log("WorkoutMode ERROR -> $e");
      _showSnack(
        title: "Error",
        message: "Something went wrong. Please try again",
        isSuccess: false,
      );
    } finally {
      isWorkoutModeLoading.value = false;
    }
  }

  Future<void> logoutUser() async {
    if (isLoggingOut.value) return;
    isLoggingOut.value = true;

    try {
      final token = await _repository.getToken();
      if (token == null || token.isEmpty) {
        _showGetSnackBar('Token not found. Please login again.', isError: true);
        isLoggingOut.value = false;
        return;
      }

      final response = await _repository.logout(token: token);

      if (response.statusCode == 200) {
        if (response.body.trim().isNotEmpty) {
          jsonDecode(response.body);
        }
        await _repository.clearSession();
        _showGetSnackBar('Successfully logged out!', isError: false);

        await Future.delayed(const Duration(seconds: 2));
        Get.offAll(
          () => SignInScreen(),
          transition: Transition.fadeIn,
          duration: const Duration(milliseconds: 400),
        );
      } else if (response.statusCode == 401) {
        _showGetSnackBar('Session expired. Please login again.', isError: true);
        await _repository.clearSession();
        await Future.delayed(const Duration(seconds: 2));
        Get.offAll(
          () => SignInScreen(),
          transition: Transition.fadeIn,
          duration: const Duration(milliseconds: 400),
        );
      } else {
        _showGetSnackBar('Something went wrong. Please try again.',
            isError: true);
      }
    } catch (e) {
      _showGetSnackBar('Error: $e', isError: true);
    } finally {
      isLoggingOut.value = false;
    }
  }

  Future<void> deleteAccount() async {
    if (isDeletingAccount.value) return;
    isDeletingAccount.value = true;

    try {
      final token = await _repository.getToken();
      if (token == null || token.isEmpty) {
        _showGetSnackBar('Token not found. Please login again.', isError: true);
        return;
      }

      final response = await _repository.deleteAccount(token: token);

      if (response.statusCode == 200) {
        if (response.body.trim().isNotEmpty) {
          jsonDecode(response.body);
        }

        await _repository.clearSession();
        await userStore.clearUserData();
        await userStore.setUserEmail('');
        await userStore.setToken('');
        await userStore.setUserID(0);
        await userStore.setLogin(false);

        _showGetSnackBar('Account deleted successfully!', isError: false);

        await Future.delayed(const Duration(seconds: 2));
        Get.offAll(
          () => SignInScreen(),
          transition: Transition.fadeIn,
          duration: const Duration(milliseconds: 400),
        );
      } else {
        _showGetSnackBar('Unable to delete account. Please try again.',
            isError: true);
      }
    } catch (e) {
      _showGetSnackBar('Error: $e', isError: true);
    } finally {
      isDeletingAccount.value = false;
    }
  }

  void _showSnack({
    required String title,
    required String message,
    required bool isSuccess,
  }) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      borderRadius: 14,
      backgroundColor:
          isSuccess ? const Color(0xFF00C853) : const Color(0xFFD32F2F),
      colorText: Colors.white,
      icon: Icon(
        isSuccess ? Icons.check_circle : Icons.info,
        color: Colors.white,
      ),
      duration: const Duration(seconds: 2),
    );
  }

  void _showGetSnackBar(String message, {bool isError = false}) {
    Get.snackbar(
      isError ? 'Error' : 'Success',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: isError
          ? Colors.redAccent.shade200.withOpacity(0.9)
          : Colors.grey.shade900,
      colorText: Colors.white,
      icon: Icon(
        isError ? Icons.error_outline : Icons.check_circle_outline,
        color: Colors.white,
      ),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: const Duration(seconds: 2),
      animationDuration: const Duration(milliseconds: 500),
      snackStyle: SnackStyle.FLOATING,
      shouldIconPulse: true,
      barBlur: 15,
    );
  }
}
