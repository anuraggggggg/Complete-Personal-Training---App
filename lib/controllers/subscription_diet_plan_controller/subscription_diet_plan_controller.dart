import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:mighty_fitness/network/api_urls.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../Chat/model/subscription_diet_plan_model.dart';

/// 💳 PAYMENT TYPES
enum PaymentMethod { razorpay, free }

class SubscriptionPlanController extends GetxController {
  // =====================================================
  // CONSTANTS
  // =====================================================
  static String get _createOrderUrl =>
      ApiEndpoints.endpoint("create-razorpay-order");

  static String get _verifyPaymentUrl =>
      ApiEndpoints.endpoint("verify-razorpay-payment");

  static const String _kSelectedPlan = "selected_plan";

  /// 🔐 Razorpay KEY ID (SAFE)
  static const String _razorpayKeyId = "rzp_live_RsCjRLal1MjiQT";

  // =====================================================
  // STATE
  // =====================================================
  final RxBool isLoading = false.obs;

  /// 📦 ALL PLANS
  final RxList<Data> planList = <Data>[].obs;

  /// 🧾 SELECTED PLAN
  final Rx<Data?> _selectedPlan = Rx<Data?>(null);

  late Razorpay _razorpay;

  // =====================================================
  // GETTERS
  // =====================================================
  List<Data> get plans => planList;
  Data? get selectedPlan => _selectedPlan.value;
  int get selectedPackageId => _selectedPlan.value?.id ?? 0;

  // =====================================================
  // LIFECYCLE
  // =====================================================
  @override
  void onInit() {
    super.onInit();

    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);

    getSubscriptionPlans();
    restoreSelectedPlan();
  }

  @override
  void onClose() {
    _razorpay.clear();
    super.onClose();
  }

  // =====================================================
  // 🚀 FETCH SUBSCRIPTION PLANS
  // =====================================================
  Future<void> getSubscriptionPlans() async {
    try {
      isLoading.value = true;
      planList.clear();

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("TOKEN");

      if (token == null || token.isEmpty) return;

      int page = 1;
      int totalPages = 1;

      do {
        final response = await http.get(
          Uri.parse(ApiEndpoints.packageList(page: page)),
          headers: {
            "Authorization": "Bearer $token",
            "Accept": "application/json",
          },
        );

        if (response.statusCode != 200) break;

        final jsonData = jsonDecode(response.body);
        totalPages = jsonData["pagination"]?["totalPages"] ?? 1;

        final List<Data> pagePlans =
            SubscriptionDietPlan.fromJson(jsonData).data ?? [];

        planList.addAll(pagePlans);
        page++;
      } while (page <= totalPages);
    } catch (e) {
      debugPrint("🔥 getSubscriptionPlans error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // =====================================================
  // ✅ SELECT PLAN
  // =====================================================
  Future<void> selectPlan(Data plan) async {
    _selectedPlan.value = plan;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kSelectedPlan,
      jsonEncode({
        "id": plan.id,
        "name": plan.name,
        "price": plan.price,
        "duration": plan.duration,
        "duration_unit": plan.durationUnit,
        "package_type": plan.packageType,
      }),
    );
  }

  // =====================================================
  // 🔁 RESTORE PLAN
  // =====================================================
  Future<void> restoreSelectedPlan() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kSelectedPlan);
    if (raw == null) return;

    final decoded = jsonDecode(raw);
    _selectedPlan.value = Data(
      id: decoded["id"],
      name: decoded["name"],
      price: decoded["price"],
      duration: decoded["duration"],
      durationUnit: decoded["duration_unit"],
      packageType: decoded["package_type"],
    );
  }

  // =====================================================
  // 🔥 START SUBSCRIPTION
  // =====================================================
  void startSubscription({
    required Data planData,
    required PaymentMethod method,
  }) {
    _selectedPlan.value = planData;

    if (Platform.isIOS &&
        (method == PaymentMethod.free || (planData.price ?? 0) == 0)) {
      Get.snackbar(
        "Unavailable",
        "Free or promo subscription activation is not available on iOS.",
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (method == PaymentMethod.free || (planData.price ?? 0) == 0) {
      _activateFreePlan(planData);
    } else {
      _startRazorpay(planData);
    }
  }

  // =====================================================
  // 🆓 FREE PLAN
  // =====================================================
  void _activateFreePlan(Data planData) {
    Get.snackbar(
      "Plan Activated 🎉",
      planData.name ?? "Free plan activated",
      snackPosition: SnackPosition.BOTTOM,
    );
    // 👉 backend activate-free-plan API call yaha lagega
  }

  // =====================================================
  // 💳 RAZORPAY FLOW
  // =====================================================
  Future<void> _startRazorpay(Data planData) async {
    try {
      isLoading.value = true;

      final orderId = await _createOrder(planData);
      if (orderId == null) throw "Order creation failed";

      final options = {
        'key': _razorpayKeyId,
        'amount': (planData.price! * 100).toInt(),
        'currency': 'INR',
        'name': 'CPT Fitness',
        'description': planData.name ?? 'Subscription',
        'order_id': orderId,
        'theme': {'color': '#E10600'},
      };

      _razorpay.open(options);
    } catch (e) {
      Get.snackbar("Payment Error", e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  // =====================================================
  // 🔐 CREATE ORDER (BACKEND)
  // =====================================================
  Future<String?> _createOrder(Data planData) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("TOKEN");

    final response = await http.post(
      Uri.parse(_createOrderUrl),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "amount": planData.price,
        "currency": "INR",
        "package_id": planData.id,
      }),
    );

    if (response.statusCode != 200) return null;
    return jsonDecode(response.body)["order_id"];
  }

  // =====================================================
  // ✅ PAYMENT SUCCESS
  // =====================================================
  Future<void> _onPaymentSuccess(PaymentSuccessResponse res) async {
    final verified = await _verifyPayment(
      paymentId: res.paymentId!,
      orderId: res.orderId!,
      signature: res.signature!,
    );

    if (verified) {
      Get.snackbar("Success 🎉", "Subscription Activated");
    } else {
      Get.snackbar("Error", "Payment verification failed");
    }
  }

  void _onPaymentError(PaymentFailureResponse res) {
    Get.snackbar("Payment Failed", res.message ?? "Error");
  }

  void _onExternalWallet(ExternalWalletResponse res) {}

  // =====================================================
  // 🔎 VERIFY PAYMENT
  // =====================================================
  Future<bool> _verifyPayment({
    required String paymentId,
    required String orderId,
    required String signature,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("TOKEN");

    final response = await http.post(
      Uri.parse(_verifyPaymentUrl),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "razorpay_payment_id": paymentId,
        "razorpay_order_id": orderId,
        "razorpay_signature": signature,
        "package_id": selectedPackageId,
      }),
    );

    return response.statusCode == 200;
  }

  // =====================================================
  // HELPERS
  // =====================================================
  List<Data> get dietPlans =>
      planList.where((e) => e.packageType == "diet").toList();

  List<Data> get workoutPlans =>
      planList.where((e) => e.packageType == "workout").toList();

  List<Data> get comboPlans =>
      planList.where((e) => e.packageType == "both").toList();
}
