import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:razorpay_flutter/razorpay_flutter.dart';

class RazorpayPaymentController extends GetxController {
  late Razorpay _razorpay;

  /// Razorpay publishable key (key_id)
  static const String liveKey = "rzp_live_RsCjRLal1MjiQT";

  /// Backend API
  static const String paymentApi =
      "https://fitness.completepersonaltraining.com/api/payment-complete";

  int? _subscriptionId;

  @override
  void onInit() {
    super.onInit();

    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onWallet);
  }

  @override
  void onClose() {
    _razorpay.clear();
    super.onClose();
  }

  // --------------------------------------------------
  // START PAYMENT
  // --------------------------------------------------
  void startPayment({
    required int subscriptionId,
    required int amount,
    required String planName,
  }) {
    _subscriptionId = subscriptionId;

    final options = {
      'key': liveKey,
      'amount': amount * 100,
      'currency': 'INR',
      'name': 'Aimbeat Fitness',
      'description': planName,
      'theme': {'color': '#FF0000'},
    };

    debugPrint("💳 Razorpay Open => $options");
    _razorpay.open(options);
  }

  // --------------------------------------------------
  // PAYMENT SUCCESS
  // --------------------------------------------------
  Future<void> _onSuccess(PaymentSuccessResponse response) async {
    debugPrint("✅ PAYMENT SUCCESS => ${response.paymentId}");

    try {
      final res = await http.post(
        Uri.parse(paymentApi),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "subscription_id": _subscriptionId,
          "razorpay_payment_id": response.paymentId,
        }),
      );

      debugPrint("📡 BACKEND STATUS => ${res.statusCode}");
      debugPrint("📨 BACKEND BODY => ${res.body}");

      if (res.statusCode == 200) {
        Get.snackbar(
          "Payment Successful",
          "Subscription activated 🎉",
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        throw Exception("Backend failed to save payment");
      }
    } catch (e) {
      Get.snackbar(
        "Payment Error",
        e.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // --------------------------------------------------
  // PAYMENT FAILED
  // --------------------------------------------------
  void _onError(PaymentFailureResponse response) {
    Get.snackbar(
      "Payment Failed",
      response.message ?? "Something went wrong",
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }

  // --------------------------------------------------
  // EXTERNAL WALLET
  // --------------------------------------------------
  void _onWallet(ExternalWalletResponse response) {
    Get.snackbar(
      "Wallet Selected",
      response.walletName ?? "",
      backgroundColor: Colors.orange,
      colorText: Colors.white,
    );
  }
}
