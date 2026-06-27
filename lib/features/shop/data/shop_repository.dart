import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:mighty_fitness/network/api_urls.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ShopRepository {
  static const String kSelectedPlan = "selected_plan";
  static const String kActiveSubscriptionId = "ACTIVE_SUBSCRIPTION_ID";
  static const String kActiveIosProductId = "ACTIVE_IOS_PRODUCT_ID";

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  Future<String?> getToken() async {
    final prefs = await _prefs;
    return prefs.getString("TOKEN");
  }

  Future<int?> getUserId() async {
    final prefs = await _prefs;
    return prefs.getInt("USER_ID");
  }

  Future<String?> getSavedSelectedPlanRaw() async {
    final prefs = await _prefs;
    return prefs.getString(kSelectedPlan);
  }

  Future<void> saveSelectedPlanRaw(String value) async {
    final prefs = await _prefs;
    await prefs.setString(kSelectedPlan, value);
  }

  Future<void> saveSubscriptionId(int id) async {
    final prefs = await _prefs;
    await prefs.setInt(kActiveSubscriptionId, id);
  }

  Future<int> getSavedSubscriptionId() async {
    final prefs = await _prefs;
    return prefs.getInt(kActiveSubscriptionId) ?? 0;
  }

  Future<void> clearSavedSubscriptionId() async {
    final prefs = await _prefs;
    await prefs.remove(kActiveSubscriptionId);
  }

  Future<void> saveActiveIosPurchaseSyncState({
    required int subscriptionId,
    required String productId,
  }) async {
    final prefs = await _prefs;
    await prefs.setInt(kActiveSubscriptionId, subscriptionId);
    await prefs.setString(kActiveIosProductId, productId);
  }

  Future<String?> getSavedIosProductId() async {
    final prefs = await _prefs;
    return prefs.getString(kActiveIosProductId);
  }

  Future<void> clearSavedIosPurchaseSyncState() async {
    final prefs = await _prefs;
    await prefs.remove(kActiveSubscriptionId);
    await prefs.remove(kActiveIosProductId);
  }

  Future<void> saveCouponAccess({required String code}) async {
    final prefs = await _prefs;
    await prefs.setBool("HAS_COUPON_ACCESS", true);
    await prefs.setString("APPLIED_COUPON", code);
  }

  Map<String, String> _normalizeBody(Map<String, dynamic> body) {
    final normalized = <String, String>{};
    body.forEach((key, value) {
      if (value == null) return;
      final stringValue = value.toString().trim();
      if (stringValue.isEmpty) return;
      normalized[key] = stringValue;
    });
    return normalized;
  }

  Future<http.Response> _postAuthorized({
    required String token,
    required String endpointPath,
    required Map<String, dynamic> body,
    bool sendJson = false,
  }) {
    final headers = <String, String>{
      "Authorization": "Bearer $token",
      "Accept": "application/json",
    };

    if (sendJson) {
      headers["Content-Type"] = "application/json";
    }

    return http
        .post(
          Uri.parse(ApiEndpoints.endpoint(endpointPath)),
          headers: headers,
          body: sendJson ? jsonEncode(body) : _normalizeBody(body),
        )
        .timeout(const Duration(seconds: 20));
  }

  Future<http.Response> fetchPackagePage({
    required String token,
    required int page,
    int? perPage,
  }) {
    final url = Uri.parse(
      ApiEndpoints.packageList(page: page, perPage: perPage),
    );
    return http.get(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Accept": "application/json",
      },
    );
  }

  Future<http.Response> fetchReferralInfo({required String token}) {
    return http.get(
      Uri.parse(ApiEndpoints.endpoint("referral-info")),
      headers: {
        "Authorization": "Bearer $token",
        "Accept": "application/json",
      },
    ).timeout(const Duration(seconds: 20));
  }

  Future<http.Response> fetchCoupons({required String token}) {
    return http.get(
      Uri.parse(ApiEndpoints.endpoint("offer-coupons")),
      headers: {
        "Authorization": "Bearer $token",
        "Accept": "application/json",
      },
    ).timeout(const Duration(seconds: 20));
  }

  Future<http.Response> applyCoupon({
    required String token,
    required String code,
  }) {
    final uri = Uri.parse(ApiEndpoints.endpoint("apply-coupon")).replace(
      queryParameters: <String, String>{"code": code},
    );

    return http.post(
      uri,
      headers: {
        "Authorization": "Bearer $token",
        "Accept": "application/json",
      },
    ).timeout(const Duration(seconds: 20));
  }

  Future<http.Response> subscribePackage({
    required String token,
    required int packageId,
    String? referralCode,
    String? paymentType,
    bool? trialAutopay,
    bool sendJson = false,
  }) {
    final body = <String, dynamic>{"package_id": packageId};
    final normalizedReferral = referralCode?.trim() ?? "";
    final normalizedPaymentType = paymentType?.trim() ?? "";
    if (normalizedReferral.isNotEmpty) {
      body["referral_code"] = normalizedReferral;
    }
    if (normalizedPaymentType.isNotEmpty) {
      body["payment_type"] = normalizedPaymentType;
    }
    if (trialAutopay != null) {
      body["trial_autopay"] = trialAutopay;
    }

    final headers = <String, String>{
      "Authorization": "Bearer $token",
      "Accept": "application/json",
    };
    if (sendJson) {
      headers["Content-Type"] = "application/json";
    }

    return http
        .post(
          Uri.parse(ApiEndpoints.endpoint("subscribe-package")),
          headers: headers,
          body: sendJson ? jsonEncode(body) : _normalizeBody(body),
        )
        .timeout(const Duration(seconds: 20));
  }

  Future<http.Response> completePayment({
    required String token,
    required int subscriptionId,
    required String razorpayPaymentId,
    String? paymentType,
    String? txnId,
    String? transactionDetail,
  }) {
    final body = <String, String>{
      "subscription_id": subscriptionId.toString(),
      "razorpay_payment_id": razorpayPaymentId,
    };

    final normalizedPaymentType = paymentType?.trim() ?? "";
    final normalizedTxnId = txnId?.trim() ?? "";
    final normalizedTransactionDetail = transactionDetail?.trim() ?? "";

    if (normalizedPaymentType.isNotEmpty) {
      body["payment_type"] = normalizedPaymentType;
    }
    if (normalizedTxnId.isNotEmpty) {
      body["txn_id"] = normalizedTxnId;
    }
    if (normalizedTransactionDetail.isNotEmpty) {
      body["transaction_detail"] = normalizedTransactionDetail;
    }

    return http
        .post(
          Uri.parse(ApiEndpoints.endpoint("payment-complete")),
          headers: {
            "Authorization": "Bearer $token",
            "Accept": "application/json",
          },
          body: body,
        )
        .timeout(const Duration(seconds: 20));
  }

  Future<http.Response> createAndroidAutopay({
    required String token,
    required int subscriptionId,
    int? packageId,
    String? razorpayPlanId,
    bool sendJson = true,
  }) {
    final normalizedPlanId = razorpayPlanId?.trim() ?? "";
    final shouldSendPlanId = normalizedPlanId.startsWith("plan_");

    return _postAuthorized(
      token: token,
      endpointPath: "android/autopay/create",
      body: {
        "subscription_id": subscriptionId,
        if (packageId != null && packageId > 0) "package_id": packageId,
        if (shouldSendPlanId) "plan_id": normalizedPlanId,
        if (shouldSendPlanId) "razorpay_plan_id": normalizedPlanId,
        "payment_type": "razorpay_autopay",
        "platform": "android",
      },
      sendJson: sendJson,
    );
  }

  Future<http.Response> completeAndroidAutopay({
    required String token,
    required Map<String, dynamic> body,
  }) {
    return _postAuthorized(
      token: token,
      endpointPath: "android/autopay/complete",
      body: body,
      sendJson: true,
    );
  }

  Future<http.Response> verifyIosPurchase({
    required String token,
    required Map<String, dynamic> body,
  }) {
    return _postAuthorized(
      token: token,
      endpointPath: "iap/verify-purchase",
      body: body,
      sendJson: true,
    );
  }

  Future<http.Response> completeIosPayment({
    required String token,
    required Map<String, dynamic> body,
  }) {
    return _postAuthorized(
      token: token,
      endpointPath: "ios/payment-complete",
      body: body,
      sendJson: true,
    );
  }

  Future<http.Response> fetchIosSubscriptionStatus({
    required String token,
    required Map<String, dynamic> body,
  }) {
    return _postAuthorized(
      token: token,
      endpointPath: "ios/subscription-status",
      body: body,
      sendJson: true,
    );
  }

  Map<String, dynamic> toMap(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) return decoded;
    return const {};
  }
}
