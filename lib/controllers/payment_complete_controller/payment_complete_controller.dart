import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:mighty_fitness/network/api_urls.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PaymentCompleteController extends GetxController {
  static String get _paymentUrl => ApiEndpoints.endpoint("payment-complete");
  static const String _kSubscriptionId = "ACTIVE_SUBSCRIPTION_ID";

  final RxBool isSubmitting = false.obs;

  // =====================================================
  // 💳 PAYMENT COMPLETE + INVOICE
  // =====================================================
  Future<bool> completePayment({
    required String razorpayPaymentId,
    int? subscriptionId,
  }) async {
    if (isSubmitting.value) return false;

    try {
      isSubmitting.value = true;
      final normalizedPaymentId = razorpayPaymentId.trim();
      if (normalizedPaymentId.isEmpty) {
        throw Exception("Payment ID missing");
      }

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("TOKEN");
      final int effectiveSubscriptionId =
          subscriptionId ?? prefs.getInt(_kSubscriptionId) ?? 0;

      if (token == null || token.isEmpty) {
        throw Exception("User not logged in");
      }

      if (effectiveSubscriptionId == 0) {
        throw Exception(
          "Subscription ID missing. Pass subscriptionId or create subscription first.",
        );
      }

      final response = await http.post(
        Uri.parse(_paymentUrl),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
        body: {
          "subscription_id": effectiveSubscriptionId.toString(),
          "razorpay_payment_id": normalizedPaymentId,
        },
      ).timeout(const Duration(seconds: 20));

      Map<String, dynamic> decoded = const {};
      if (response.body.trim().isNotEmpty) {
        final body = jsonDecode(response.body);
        if (body is Map<String, dynamic>) {
          decoded = body;
        }
      }

      final String message =
          (decoded["message"]?.toString().trim().isNotEmpty ?? false)
              ? decoded["message"].toString()
              : "Payment failed";

      final bool hasStatusFlag = decoded.containsKey("status");
      final bool apiSuccess = hasStatusFlag
          ? decoded["status"] == true
          : response.statusCode == 200;

      if (!apiSuccess) {
        throw Exception(message);
      }

      // Clear saved active subscription only after successful verification.
      await prefs.remove(_kSubscriptionId);

      Get.snackbar(
        "Success 🎉",
        decoded['message'] ?? "Payment successful",
        snackPosition: SnackPosition.BOTTOM,
      );

      debugPrint("🧾 Invoice Generated Successfully");
      return true;
    } on TimeoutException {
      Get.snackbar(
        "Payment Error",
        "Request timed out. Please try again.",
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } catch (e) {
      Get.snackbar(
        "Payment Error",
        "Payment verification failed. Please try again.",
        snackPosition: SnackPosition.BOTTOM,
      );
      debugPrint("❌ Payment Complete Error: $e");
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }
}
