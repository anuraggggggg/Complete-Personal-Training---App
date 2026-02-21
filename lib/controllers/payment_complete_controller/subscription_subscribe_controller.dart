import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:mighty_fitness/models/subscription_id_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SubscriptionSubscribeController extends GetxController {
  static const String _subscribeUrl =
      "https://fitness.completepersonaltraining.com/api/subscribe-package";

  static const String _kSubscriptionId = "ACTIVE_SUBSCRIPTION_ID";

  final RxBool isLoading = false.obs;
  final RxInt subscriptionId = 0.obs;

  // =====================================================
  // 🔥 SUBSCRIBE PACKAGE
  // =====================================================
  Future<void> subscribePackage({
    required int packageId,
    String? referralCode,
  }) async {
    try {
      isLoading.value = true;

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("TOKEN");
      if (token == null || token.isEmpty) {
        throw Exception("User not logged in");
      }

      final Map<String, String> body = {
        "package_id": packageId.toString(),
      };
      final normalizedReferral = referralCode?.trim() ?? "";
      if (normalizedReferral.isNotEmpty) {
        body["referral_code"] = normalizedReferral;
      }

      final response = await http
          .post(
            Uri.parse(_subscribeUrl),
            headers: {
              "Authorization": "Bearer $token",
              "Accept": "application/json",
            },
            body: body,
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode != 200) {
        throw Exception("Subscribe failed");
      }

      final decoded = jsonDecode(response.body);
      final model = SubscriptionIDModel.fromJson(decoded);

      /// 🔥 VERY IMPORTANT
      subscriptionId.value = model.data?.id ?? 0;

      await prefs.setInt(_kSubscriptionId, subscriptionId.value);

      debugPrint(
        "✅ Subscription Created => ID: ${subscriptionId.value}",
      );
    } on TimeoutException {
      Get.snackbar("Error", "Request timed out. Please try again.");
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  // =====================================================
  // 🔁 RESTORE SUBSCRIPTION ID
  // =====================================================
  Future<int> getSavedSubscriptionId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kSubscriptionId) ?? 0;
  }
}
