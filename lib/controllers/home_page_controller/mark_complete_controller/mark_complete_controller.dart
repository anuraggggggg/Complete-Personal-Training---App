import 'package:get/get.dart';
import 'package:mighty_fitness/utils/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../models/exercise_complete_response_model.dart';

class MarkCompleteController extends GetxController {
  
  var isLoading = false.obs;
  var isCompleted = false.obs;

  Future<void> markExerciseComplete({
    required int exerciseId,
    int? workoutId,
  }) async {
    isLoading.value = true;

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int? userId = prefs.getInt(USER_ID);
      String? token = prefs.getString(TOKEN);

      var url = Uri.parse(
        'https://fitness.completepersonaltraining.com/api/exercise/complete'
        '?user_id=$userId&exercise_id=$exerciseId'
        '${workoutId != null ? '&workout_id=$workoutId' : ''}',
      );

      print('📡 API Request URL: $url');

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('🔁 Response Status Code: ${response.statusCode}');
      print('📦 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);
        var result = ExerciseCompleteResponse.fromJson(jsonResponse);

        if (result.success == true) {
          isCompleted.value = true;
          _showDarkSnackbar(
            title: '✅ Success',
            message: result.message ?? 'Exercise completed successfully!',
            color: Colors.greenAccent.withOpacity(0.2),
            icon: Icons.check_circle_outline,
          );
        } else {
          _showDarkSnackbar(
            title: '⚠️ Error',
            message: result.message ?? 'Failed to complete exercise.',
            color: Colors.redAccent.withOpacity(0.2),
            icon: Icons.error_outline,
          );
        }
      } else {
        _showDarkSnackbar(
          title: 'Server Error',
          message: 'Status Code: ${response.statusCode}',
          color: Colors.orangeAccent.withOpacity(0.2),
          icon: Icons.warning_amber_rounded,
        );
      }
    } catch (e) {
      print('❌ Exception: $e');
      _showDarkSnackbar(
        title: 'Error',
        message: e.toString(),
        color: Colors.redAccent.withOpacity(0.2),
        icon: Icons.error,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// 🔥 Custom Animated Dark Snackbar
  void _showDarkSnackbar({
    required String title,
    required String message,
    required Color color,
    required IconData icon,
  }) {
    Get.snackbar(
      '',
      '',
      titleText: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 22),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ],
      ),
      messageText: Text(
        message,
        style: const TextStyle(color: Colors.white70, fontSize: 14),
      ),
      backgroundColor: Colors.black.withOpacity(0.9),
      borderRadius: 16,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(14),
      snackPosition: SnackPosition.TOP,
      animationDuration: const Duration(milliseconds: 400),
      duration: const Duration(seconds: 3),
      forwardAnimationCurve: Curves.easeOutBack,
      reverseAnimationCurve: Curves.easeIn,
      isDismissible: true,
      barBlur: 8,
      overlayBlur: 0,
    );
  }
}
