import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mighty_fitness/controllers/apply_coupon_controller/access_gate_controller.dart';
import 'package:mighty_fitness/controllers/home_page_controller/home_page_workout_list_controller.dart';

class CouponController extends GetxController {
  final RxBool isApplying = false.obs;

  static const String _url =
      "https://fitness.completepersonaltraining.com/api/apply-coupon";

  /// ============================================================
  /// 🔥 APPLY COUPON (HARD LOCK + SAFE FLOW)
  /// ============================================================
  Future<void> applyCoupon({required String code}) async {
    /// 🔒 HARD LOCK (double tap / double API hit protection)
    if (isApplying.value) {
      debugPrint("⛔ Coupon already applying, ignoring tap");
      return;
    }

    final trimmedCode = code.trim();
    if (trimmedCode.isEmpty) {
      Get.snackbar("Invalid Coupon", "Please enter a coupon code");
      return;
    }

    isApplying.value = true;
    debugPrint("🟡 APPLY COUPON STARTED");
    debugPrint("📝 Coupon Code Entered: $trimmedCode");

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("TOKEN");

      debugPrint("🔐 TOKEN FOUND: ${token != null}");

      if (token == null || token.isEmpty) {
        Get.snackbar("Error", "User not logged in");
        return;
      }

      final uri = Uri.parse(_url).replace(
        queryParameters: <String, String>{"code": trimmedCode},
      );
      debugPrint("🌐 API URL: $uri");

      final response = await http.post(
        uri,
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      ).timeout(const Duration(seconds: 20));

      debugPrint("📡 STATUS CODE: ${response.statusCode}");
      debugPrint("📦 RAW RESPONSE: ${response.body}");

      Map<String, dynamic> jsonData = const {};
      if (response.body.isNotEmpty) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          jsonData = decoded;
        }
      }
      final message =
          (jsonData["message"]?.toString().trim().isNotEmpty ?? false)
              ? jsonData["message"].toString()
              : "Coupon not valid";

      /// ===============================
      /// ✅ SUCCESS
      /// ===============================
      if (response.statusCode == 200 && jsonData["status"] == true) {
        final appliedCode = jsonData["data"]?["coupon_code"];

        // 💾 SAVE LOCALLY
        await prefs.setBool("HAS_COUPON_ACCESS", true);
        await prefs.setString("APPLIED_COUPON", appliedCode ?? "");

        debugPrint("💾 HAS_COUPON_ACCESS = true");
        debugPrint("💾 APPLIED_COUPON = $appliedCode");

        // 🔓 ACCESS GATE UPDATE
        if (Get.isRegistered<AccessGateController>()) {
          Get.find<AccessGateController>().grantAccess();
          debugPrint("🔓 AccessGateController UPDATED");
        }

        // 🔄 HOME / DASHBOARD REFRESH
        if (Get.isRegistered<HomePageController>()) {
          Get.find<HomePageController>().onCouponApplied();
          debugPrint("🔄 HomePageController refreshed");
        }

        Get.snackbar(
          "Success 🎉",
          jsonData["message"] ?? "Coupon applied successfully",
        );

        // ❌ CLOSE DIALOG (ONLY ON SUCCESS)
        // ❌ CLOSE COUPON DIALOG (SAFE & GUARANTEED)
        if (Get.isDialogOpen == true) {
          debugPrint("❎ Closing Coupon Dialog");

          // Tiny delay to avoid snackbar/dialog clash.
          Future.delayed(const Duration(milliseconds: 250), () {
            if (Get.isDialogOpen == true) {
              Get.back();
            }
          });
        }
      }

      /// ===============================
      /// ❌ INVALID / FAILED
      /// ===============================
      else {
        Get.snackbar(
          "Invalid Coupon",
          message,
        );
      }
    } on TimeoutException {
      Get.snackbar("Network Error", "Request timed out. Please try again.");
    } catch (e, s) {
      debugPrint("🔥 COUPON ERROR: $e");
      debugPrint("📍 STACKTRACE: $s");
      Get.snackbar("Error", "Something went wrong. Please try again.");
    } finally {
      /// 🔓 UNLOCK BUTTON
      isApplying.value = false;
      debugPrint("🟢 APPLY COUPON FLOW FINISHED");
    }
  }
}
