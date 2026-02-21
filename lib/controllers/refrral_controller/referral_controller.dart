import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:mighty_fitness/models/send_refrals.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReferralController extends GetxController {
  // =====================================================
  // API
  // =====================================================
  static const String _referralUrl =
      "https://fitness.completepersonaltraining.com/api/referral-info";

  // =====================================================
  // STATE
  // =====================================================
  final RxBool isLoading = false.obs;
  final RxBool isError = false.obs;
  final RxString errorMessage = "".obs;

  final Rx<SendReferrals?> referralResponse = Rx<SendReferrals?>(null);

  // =====================================================
  // SHORTCUT GETTERS (UI FRIENDLY)
  // =====================================================
  ReferralData? get referralData => referralResponse.value?.data;

  String get referralCode => referralData?.referralCode ?? "";

  int get referralCredit => referralData?.referralCreditBalance ?? 0;

  int get totalReferrals => referralData?.totalReferrals ?? 0;

  bool get isReferralActive => referralData?.isActive ?? false;

  bool get hasReferralCredit => referralCredit > 0;

  // =====================================================
  // LIFECYCLE
  // =====================================================
  @override
  void onInit() {
    super.onInit();
    fetchReferralInfo();
  }

  // =====================================================
  // 🚀 FETCH REFERRAL INFO
  // =====================================================
  Future<void> fetchReferralInfo() async {
    try {
      isLoading.value = true;
      isError.value = false;
      errorMessage.value = "";

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("TOKEN");

      if (token == null || token.isEmpty) {
        referralResponse.value = null;
        throw Exception("Authorization token not found");
      }

      final response = await http.get(
        Uri.parse(_referralUrl),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      ).timeout(const Duration(seconds: 20));

      debugPrint("📡 Referral API Status => ${response.statusCode}");

      if (response.statusCode != 200) {
        referralResponse.value = null;
        throw Exception("Failed to fetch referral info");
      }

      if (response.body.trim().isEmpty) {
        referralResponse.value = null;
        throw Exception("Empty referral response");
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        referralResponse.value = null;
        throw Exception("Invalid referral response format");
      }

      final model = SendReferrals.fromJson(decoded);
      if (!model.status || model.data == null) {
        referralResponse.value = null;
        throw Exception("Referral is not active");
      }

      referralResponse.value = model;

      debugPrint(
        "✅ Referral Loaded => Code: $referralCode | Credit: ₹$referralCredit",
      );
    } on TimeoutException {
      referralResponse.value = null;
      isError.value = true;
      errorMessage.value = "Referral request timed out";
    } catch (e) {
      debugPrint("❌ Referral API Error: $e");
      referralResponse.value = null;
      isError.value = true;
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  // =====================================================
  // 🔁 MANUAL REFRESH (PULL TO REFRESH / AFTER PAYMENT)
  // =====================================================
  Future<void> refreshReferral() async {
    await fetchReferralInfo();
  }
}
