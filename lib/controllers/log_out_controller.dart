import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart'; // <-- for kDebugMode
import 'package:mighty_fitness/utils/app_constants.dart';
import 'package:mighty_fitness/network/api_urls.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/sign_in_screen.dart';

class LogoutController {
  final String baseUrl = ApiEndpoints.endpoint("logout");

  Future<void> logoutUser(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(TOKEN);

      if (kDebugMode) print('🔹 Retrieved Token: $token');

      if (token == null || token.isEmpty) {
        _showGetSnackBar('Token not found. Please login again.', isError: true);
        return;
      }

      if (kDebugMode) print('🔸 Sending logout request to $baseUrl');

      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (kDebugMode) {
        print('🔸 Logout Response Code: ${response.statusCode}');
        print('🔸 Logout Response Body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (kDebugMode) print('✅ Logout Success: $data');

        await prefs.clear();

        _showGetSnackBar('Successfully logged out!', isError: false);

        await Future.delayed(const Duration(seconds: 2));
        Get.offAll(() => SignInScreen(),
            transition: Transition.fadeIn,
            duration: const Duration(milliseconds: 400));
      } else if (response.statusCode == 401) {
        if (kDebugMode) print('⚠️ Session expired');
        _showGetSnackBar('Session expired. Please login again.', isError: true);

        await prefs.clear();
        await Future.delayed(const Duration(seconds: 2));
        Get.offAll(() => SignInScreen(),
            transition: Transition.fadeIn,
            duration: const Duration(milliseconds: 400));
      } else {
        if (kDebugMode) print('❌ Logout failed: ${response.body}');
        _showGetSnackBar('Something went wrong. Please try again.', isError: true);
      }
    } catch (e) {
      if (kDebugMode) print('🚨 Logout Error: $e');
      _showGetSnackBar('Error: $e', isError: true);
    }
  }

  void _showGetSnackBar(String message, {bool isError = false}) {
    Get.snackbar(
      isError ? 'Error' : 'Success',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor:
          isError ? Colors.redAccent.shade200.withOpacity(0.9) : Colors.grey.shade900,
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
