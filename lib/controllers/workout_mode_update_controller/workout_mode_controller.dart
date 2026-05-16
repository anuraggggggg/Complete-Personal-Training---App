import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:mighty_fitness/network/api_urls.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WorkoutModeUpdateController extends GetxController {
  /// 1 = Gym, 2 = Home
  final RxInt workoutMode = 1.obs;
  final RxBool isLoading = false.obs;

  // 🔥 REQUIRED BY UI
  bool get isGym => workoutMode.value == 1;
  bool get isHome => workoutMode.value == 2;

  static const String _baseUrl = ApiEndpoints.baseUrl;

  @override
  void onInit() {
    super.onInit();
    _loadSavedMode();
  }

  // 🔥 CALLED FROM PROFILE SCREEN
  Future<void> updateWorkoutMode(int mode) async {
    if (workoutMode.value == mode) {
      // Already selected → soft feedback
      _showSnack(
        title: "Already Selected",
        message:
            mode == 1 ? "Gym mode already active" : "Home mode already active",
        isSuccess: false,
      );
      return;
    }

    try {
      isLoading.value = true;

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("TOKEN");
      if (token == null) return;

      final response = await http.post(
        Uri.parse("$_baseUrl/update-workout-mode"),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "workout_mode": mode,
        }),
      );

      log("WorkoutMode API → ${response.body}");

      if (response.statusCode == 200) {
        workoutMode.value = mode;
        await prefs.setInt("WORKOUT_MODE", mode);

        // ✅ SUCCESS SNACKBAR
        _showSnack(
          title: "Workout Mode Updated",
          message: mode == 1
              ? "Gym workout mode activated 💪"
              : "Home workout mode activated 🏠",
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
      log("WorkoutMode ERROR → $e");

      _showSnack(
        title: "Error",
        message: "Something went wrong. Please try again",
        isSuccess: false,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadSavedMode() async {
    final prefs = await SharedPreferences.getInstance();
    workoutMode.value = prefs.getInt("WORKOUT_MODE") ?? 1;
  }

  // ================== SNACKBAR ==================
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
}
