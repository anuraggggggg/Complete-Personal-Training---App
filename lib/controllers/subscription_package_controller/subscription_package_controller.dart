import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mighty_fitness/Chat/model/subscription_diet_plan_model.dart';
import 'package:mighty_fitness/extensions/extension_util/int_extensions.dart';
import 'package:mighty_fitness/network/network_utils.dart';

/// 💳 PAYMENT METHODS
enum PaymentMethod { razorpay, stripe, free }

class SubscriptionPlanController extends GetxController {
  // =====================================================
  // UI STATE
  // =====================================================
  final RxBool isLoading = false.obs;
  final RxBool isSubmitting = false.obs;
  final RxString errorMessage = ''.obs;

  // =====================================================
  // DATA
  // =====================================================
  final RxList<Data> plans = <Data>[].obs;

  /// ✅ SELECTED PLAN
  final Rx<Data?> selectedPlan = Rx<Data?>(null);

  /// 🔗 REFERRAL CODE (OPTIONAL)
  final RxString referralCode = ''.obs;

  // =====================================================
  // GETTERS
  // =====================================================
  int get selectedPackageId => selectedPlan.value?.id ?? 0;

  bool get hasReferralCode => referralCode.value.trim().isNotEmpty;

  // =====================================================
  // 📦 FETCH SUBSCRIPTION PLANS
  // =====================================================
  Future<void> fetchPlans() async {
    try {
      isLoading.value = true;

      final response = await buildHttpResponse(
        'subscription-plan',
        method: HttpMethod.GET,
      );

      if (!response.statusCode.isSuccessful()) {
        throw Exception("Failed to load subscription plans");
      }

      final decoded = jsonDecode(response.body);
      final model = SubscriptionDietPlan.fromJson(decoded);

      plans.assignAll(model.data ?? []);
    } catch (e) {
      errorMessage.value = e.toString();
      debugPrint("❌ fetchPlans error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // =====================================================
  // ✅ SELECT PLAN
  // =====================================================
  void selectPlan(Data plan) {
    selectedPlan.value = plan;

    debugPrint(
      "✅ Plan Selected => ID: ${plan.id}, Name: ${plan.name}",
    );
  }

  // =====================================================
  // 🏷 SET REFERRAL CODE (FROM REFERRAL CONTROLLER / UI)
  // =====================================================
  void setReferralCode(String code) {
    referralCode.value = code.trim();

    debugPrint("🎁 Referral Code Set => ${referralCode.value}");
  }

  // =====================================================
  // 🚀 SUBSCRIBE PACKAGE (MAIN API)
  // =====================================================
  Future<bool> subscribePackage({
    required PaymentMethod paymentMethod,
    String paymentStatus = "paid",
  }) async {
    if (selectedPlan.value == null) {
      Get.snackbar("Error", "No plan selected");
      return false;
    }

    try {
      isSubmitting.value = true;

      final Map<String, dynamic> body = {
        "package_id": selectedPlan.value!.id,
        "payment_status": paymentStatus,
        "payment_method": paymentMethod.name,
      };

      /// 🔥 ADD REFERRAL CODE IF AVAILABLE
      if (hasReferralCode) {
        body["referral_code"] = referralCode.value;
      }

      debugPrint("📤 SUBSCRIBE PACKAGE BODY => $body");

      final response = await buildHttpResponse(
        'subscribe-package',
        request: body,
        method: HttpMethod.POST,
      );

      if (!response.statusCode.isSuccessful()) {
        throw Exception("Subscription failed");
      }

      final decoded = jsonDecode(response.body);

      Get.snackbar(
        "Success 🎉",
        decoded['message'] ?? "Subscription successful",
        snackPosition: SnackPosition.BOTTOM,
      );

      return true;
    } catch (e) {
      debugPrint("❌ subscribePackage error: $e");

      Get.snackbar(
        "Error",
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  // =====================================================
  // INIT
  // =====================================================
  @override
  void onInit() {
    super.onInit();
    fetchPlans();
  }
}
