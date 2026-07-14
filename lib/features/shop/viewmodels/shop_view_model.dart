import 'dart:io';
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:mighty_fitness/Chat/model/subscription_diet_plan_model.dart'
    as plan_model;
import 'package:mighty_fitness/controllers/apply_coupon_controller/access_gate_controller.dart';
import 'package:mighty_fitness/controllers/home_page_controller/home_page_workout_list_controller.dart';
import 'package:mighty_fitness/core/mvvm/base_view_model.dart';
import 'package:mighty_fitness/features/shop/data/shop_repository.dart';
import 'package:mighty_fitness/models/get_coupons.dart';
import 'package:mighty_fitness/models/send_refrals.dart';
import 'package:mighty_fitness/models/subscription_id_model.dart'
    as subscription_model;
import 'package:mighty_fitness/service/ios_iap_service.dart';
import 'package:mighty_fitness/utils/app_constants.dart';

class ShopViewModel extends BaseViewModel {
  ShopViewModel({ShopRepository? repository})
      : _repository = repository ?? ShopRepository();

  final ShopRepository _repository;
  final IOSIapService _iosIapService = IOSIapService();

  final RxBool isLoadingPlans = false.obs;
  final RxBool isCouponsLoading = false.obs;
  final RxBool isReferralLoading = false.obs;
  final RxBool isApplyingCoupon = false.obs;
  final RxBool isSubscribing = false.obs;
  final RxBool isPaymentSubmitting = false.obs;

  final RxString plansErrorMessage = "".obs;
  final RxString couponsErrorMessage = "".obs;
  final RxString referralErrorMessage = "".obs;

  final RxList<plan_model.Data> planList = <plan_model.Data>[].obs;
  final RxList<CouponData> coupons = <CouponData>[].obs;
  final RxInt subscriptionId = 0.obs;
  final Rx<SendReferrals?> referralResponse = Rx<SendReferrals?>(null);
  final Rx<plan_model.Data?> selectedPlan = Rx<plan_model.Data?>(null);

  List<plan_model.Data> get plans => planList;
  int get selectedPackageId => selectedPlan.value?.id ?? 0;
  bool get _supportsExternalDiscounts => !Platform.isIOS;

  ReferralData? get referralData => referralResponse.value?.data;
  String get referralCode => referralData?.referralCode ?? "";
  int get referralCredit => referralData?.referralCreditBalance ?? 0;
  bool get hasReferralCredit => referralCredit > 0;
  bool get isReferralActive => referralData?.isActive ?? false;

  List<CouponData> get activeCoupons => coupons
      .where(
        (c) =>
            (c.status ?? "").toLowerCase() == "active" &&
            (c.remainingRedemptions ?? 0) > 0,
      )
      .toList();

  bool get canShowCoupons =>
      _supportsExternalDiscounts && subscriptionId.value > 0;

  int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  @override
  void onInit() {
    super.onInit();
    unawaited(getSubscriptionPlans());
    unawaited(_restoreIosPurchaseContext());
    if (_supportsExternalDiscounts) {
      unawaited(fetchCoupons());
      unawaited(fetchReferral());
    }
  }

  Future<void> _restoreIosPurchaseContext() async {
    await restoreSelectedPlan();
    if (Platform.isIOS) {
      await syncIosSubscriptionStatus();
    }
  }

  Future<void> getSubscriptionPlans() async {
    try {
      isLoadingPlans.value = true;
      plansErrorMessage.value = "";
      planList.clear();
      setLoading();

      final token = await _repository.getToken();
      if (token == null || token.isEmpty) {
        plansErrorMessage.value = "User not logged in";
        return;
      }

      var page = 1;
      var totalPages = 1;
      final bool loadAllAtOnce = Platform.isIOS;
      do {
        final res = await _repository.fetchPackagePage(
          token: token,
          page: page,
          perPage: loadAllAtOnce ? -1 : null,
        );
        if (res.statusCode != 200) {
          plansErrorMessage.value = "Failed to load plans (${res.statusCode})";
          break;
        }

        final data = _repository.toMap(res.body);
        totalPages = data["pagination"]?["totalPages"] ?? 1;
        final pagePlans = plan_model.SubscriptionDietPlan.fromJson(data).data ??
            <plan_model.Data>[];
        planList.addAll(pagePlans);
        if (loadAllAtOnce) break;
        page++;
      } while (page <= totalPages);

      setSuccess();
    } catch (e) {
      plansErrorMessage.value = "Unable to load plans";
      setError("Unable to load plans");
      debugPrint("getSubscriptionPlans error: $e");
    } finally {
      isLoadingPlans.value = false;
    }
  }

  Future<void> selectPlan(plan_model.Data plan) async {
    selectedPlan.value = plan;
    await _repository.saveSelectedPlanRaw(
      jsonEncode({
        "id": plan.id,
        "name": plan.name,
        "price": plan.price,
        "duration": plan.duration,
        "duration_unit": plan.durationUnit,
        "package_type": plan.packageType,
        "description": plan.description,
        "status": plan.status,
        "ios_product_ids": plan.iosProductIds,
        "razorpay_plan_id": plan.razorpayPlanId,
      }),
    );
  }

  Future<void> restoreSelectedPlan() async {
    final raw = await _repository.getSavedSelectedPlanRaw();
    if (raw == null || raw.isEmpty) return;
    final decoded = _repository.toMap(raw);
    List<String>? savedIosProductIds;
    if (decoded["ios_product_ids"] is List) {
      savedIosProductIds = (decoded["ios_product_ids"] as List)
          .map((e) => e?.toString().trim() ?? '')
          .where((e) => e.isNotEmpty)
          .toList();
    } else if (decoded["ios_product_ids"] is String) {
      savedIosProductIds = (decoded["ios_product_ids"] as String)
          .split(RegExp(r'[,;\n|]'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    selectedPlan.value = plan_model.Data(
      id: _asInt(decoded["id"]),
      name: decoded["name"]?.toString(),
      price: _asInt(decoded["price"]),
      duration: _asInt(decoded["duration"]),
      durationUnit: decoded["duration_unit"]?.toString(),
      packageType: decoded["package_type"]?.toString(),
      description: decoded["description"]?.toString(),
      status: decoded["status"]?.toString(),
      iosProductIds: savedIosProductIds,
      razorpayPlanId: decoded["razorpay_plan_id"]?.toString(),
    );
  }

  Future<void> fetchReferral() async {
    if (!_supportsExternalDiscounts) {
      referralResponse.value = null;
      referralErrorMessage.value = "";
      isReferralLoading.value = false;
      return;
    }

    try {
      isReferralLoading.value = true;
      referralErrorMessage.value = "";

      final token = await _repository.getToken();
      if (token == null || token.isEmpty) {
        referralResponse.value = null;
        referralErrorMessage.value = "User not logged in";
        return;
      }

      final res = await _repository.fetchReferralInfo(token: token);
      if (res.statusCode != 200) {
        referralResponse.value = null;
        referralErrorMessage.value = "Failed to fetch referral";
        return;
      }

      final decoded = _repository.toMap(res.body);
      final model = SendReferrals.fromJson(decoded);
      if (!model.status || model.data == null) {
        referralResponse.value = null;
        referralErrorMessage.value = "Referral is not active";
        return;
      }

      referralResponse.value = model;
    } on TimeoutException {
      referralResponse.value = null;
      referralErrorMessage.value = "Referral request timed out";
    } catch (e) {
      referralResponse.value = null;
      referralErrorMessage.value = e.toString();
    } finally {
      isReferralLoading.value = false;
    }
  }

  Future<void> refreshReferral() => fetchReferral();

  Future<void> fetchCoupons() async {
    if (!_supportsExternalDiscounts) {
      coupons.clear();
      subscriptionId.value = 0;
      couponsErrorMessage.value = "";
      isCouponsLoading.value = false;
      return;
    }

    try {
      isCouponsLoading.value = true;
      couponsErrorMessage.value = "";

      final token = await _repository.getToken();
      if (token == null || token.isEmpty) {
        coupons.clear();
        subscriptionId.value = 0;
        couponsErrorMessage.value = "User not logged in";
        return;
      }

      final res = await _repository.fetchCoupons(token: token);
      final decoded = res.body.trim().isNotEmpty
          ? _repository.toMap(res.body)
          : const <String, dynamic>{};

      if (res.statusCode != 200) {
        couponsErrorMessage.value =
            decoded["message"]?.toString() ?? "Failed to load coupons";
        return;
      }

      final model = GetCoupons.fromJson(decoded);
      subscriptionId.value = model.subscriptionId ?? 0;
      if (model.status != true) {
        coupons.clear();
        couponsErrorMessage.value =
            decoded["message"]?.toString() ?? "Unable to fetch coupons";
        return;
      }

      coupons.assignAll(model.data ?? <CouponData>[]);
    } on TimeoutException {
      coupons.clear();
      subscriptionId.value = 0;
      couponsErrorMessage.value = "Request timed out";
    } catch (e) {
      coupons.clear();
      subscriptionId.value = 0;
      couponsErrorMessage.value = "Something went wrong";
      debugPrint("fetchCoupons error: $e");
    } finally {
      isCouponsLoading.value = false;
    }
  }

  Future<void> applyCoupon({required String code}) async {
    if (!_supportsExternalDiscounts) {
      Get.snackbar(
        "Unavailable",
        "Offer codes and promo unlocks are not available on iOS.",
      );
      return;
    }

    if (isApplyingCoupon.value) return;

    final trimmedCode = code.trim();
    if (trimmedCode.isEmpty) {
      Get.snackbar("Invalid Coupon", "Please enter a coupon code");
      return;
    }

    try {
      isApplyingCoupon.value = true;

      final token = await _repository.getToken();
      if (token == null || token.isEmpty) {
        Get.snackbar("Error", "User not logged in");
        return;
      }

      final res =
          await _repository.applyCoupon(token: token, code: trimmedCode);
      final decoded = res.body.trim().isNotEmpty
          ? _repository.toMap(res.body)
          : const <String, dynamic>{};
      final message =
          (decoded["message"]?.toString().trim().isNotEmpty ?? false)
              ? decoded["message"].toString()
              : "Coupon not valid";

      if (res.statusCode == 200 && decoded["status"] == true) {
        final appliedCode = decoded["data"]?["coupon_code"]?.toString() ?? "";
        await _repository.saveCouponAccess(code: appliedCode);

        if (Get.isRegistered<AccessGateController>()) {
          Get.find<AccessGateController>().grantAccess();
        }
        if (Get.isRegistered<HomePageController>()) {
          Get.find<HomePageController>().onCouponApplied();
        }

        Get.snackbar("Success", decoded["message"] ?? "Coupon applied");
        await fetchCoupons();
        await refreshReferral();

        if (Get.isDialogOpen == true) {
          Future.delayed(const Duration(milliseconds: 250), () {
            if (Get.isDialogOpen == true) {
              Get.back();
            }
          });
        }
      } else {
        Get.snackbar("Invalid Coupon", message);
      }
    } on TimeoutException {
      Get.snackbar("Network Error", "Request timed out. Please try again.");
    } catch (e) {
      debugPrint("applyCoupon error: $e");
      Get.snackbar("Error", "Something went wrong. Please try again.");
    } finally {
      isApplyingCoupon.value = false;
    }
  }

  Future<subscription_model.Data?> subscribePackage({
    required int packageId,
    String? referralCode,
    String? paymentType,
    bool? trialAutopay,
    bool showErrors = true,
  }) async {
    try {
      isSubscribing.value = true;
      subscriptionId.value = 0;

      final token = await _repository.getToken();
      if (token == null || token.isEmpty) {
        if (showErrors) {
          Get.snackbar("Error", "User not logged in");
        }
        return null;
      }

      final res = await _repository.subscribePackage(
        token: token,
        packageId: packageId,
        referralCode: referralCode,
        paymentType: paymentType,
        trialAutopay: trialAutopay,
        sendJson: Platform.isIOS || trialAutopay == true,
      );

      if (res.statusCode != 200) {
        if (showErrors) {
          Get.snackbar("Error", "Subscribe failed");
        }
        return null;
      }

      final model = subscription_model.SubscriptionIDModel.fromJson(
          _repository.toMap(res.body));
      subscriptionId.value = model.data?.id ?? 0;
      await _repository.saveSubscriptionId(subscriptionId.value);
      final currentPlan = selectedPlan.value;
      final returnedPackage = model.data?.packageData;
      final returnedIosProductIds =
          model.data?.iosProductIds ?? returnedPackage?.iosProductIds;
      final returnedRazorpayPlanId = returnedPackage?.razorpayPlanId;
      if (currentPlan != null &&
          (returnedIosProductIds != null ||
              (returnedRazorpayPlanId?.trim().isNotEmpty == true &&
                  returnedRazorpayPlanId != currentPlan.razorpayPlanId))) {
        final updatedPlan = plan_model.Data(
          id: currentPlan.id,
          name: currentPlan.name,
          price: currentPlan.price,
          duration: currentPlan.duration,
          durationUnit: currentPlan.durationUnit,
          packageType: currentPlan.packageType,
          description: currentPlan.description,
          status: currentPlan.status,
          createdAt: currentPlan.createdAt,
          updatedAt: currentPlan.updatedAt,
          iosProductIds: returnedIosProductIds ?? currentPlan.iosProductIds,
          razorpayPlanId: returnedRazorpayPlanId?.trim().isNotEmpty == true
              ? returnedRazorpayPlanId
              : currentPlan.razorpayPlanId,
        );
        await selectPlan(updatedPlan);
      }
      return model.data;
    } on TimeoutException {
      if (showErrors) {
        Get.snackbar("Error", "Request timed out. Please try again.");
      }
      return null;
    } catch (e) {
      if (showErrors) {
        Get.snackbar("Error", e.toString());
      }
      return null;
    } finally {
      isSubscribing.value = false;
    }
  }

  Map<String, dynamic> _decodeMapSafely(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const <String, dynamic>{};
    try {
      return _repository.toMap(raw);
    } catch (_) {
      return const <String, dynamic>{};
    }
  }

  String _messageFromResponse(
    Map<String, dynamic> decoded, {
    required String fallback,
  }) {
    final raw = decoded["message"]?.toString().trim() ?? "";
    return raw.isNotEmpty ? raw : fallback;
  }

  bool _responseSuccess({
    required int statusCode,
    required Map<String, dynamic> decoded,
  }) {
    var success = statusCode >= 200 && statusCode < 300;
    if (decoded.containsKey("status")) {
      final status = decoded["status"];
      if (status is bool) {
        success = success && status;
      } else if (status is num) {
        success = success && status != 0;
      } else if (status is String) {
        final normalized = status.toLowerCase().trim();
        success = success &&
            (normalized == "true" ||
                normalized == "1" ||
                normalized == "success");
      }
    }
    return success;
  }

  String _normalizeString(dynamic value) => value?.toString().trim() ?? "";

  bool _readBoolFlag(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.toLowerCase().trim();
      return normalized == "true" ||
          normalized == "1" ||
          normalized == "yes" ||
          normalized == "active";
    }
    return false;
  }

  String _resolveSavedIosProductId() {
    final ids = selectedPlan.value?.iosProductIds;
    if (ids == null || ids.isEmpty) return "";
    return ids.firstWhere(
      (id) => id.trim().isNotEmpty,
      orElse: () => "",
    );
  }

  Future<bool> syncIosSubscriptionStatus({
    bool restorePurchases = false,
    bool showSuccessMessage = false,
    bool showFailureMessage = false,
  }) async {
    if (!Platform.isIOS) return false;

    try {
      final token = await _repository.getToken();
      if (token == null || token.isEmpty) {
        return false;
      }

      final int savedSubscriptionId =
          await _repository.getSavedSubscriptionId();
      if (savedSubscriptionId == 0) {
        if (showFailureMessage) {
          Get.snackbar(
            "Restore Purchases",
            "No saved iOS subscription was found to sync.",
          );
        }
        return false;
      }

      final String productId =
          (await _repository.getSavedIosProductId())?.trim() ??
              _resolveSavedIosProductId();
      if (productId.isEmpty) {
        if (showFailureMessage) {
          Get.snackbar(
            "Restore Purchases",
            "Missing App Store product information for this subscription.",
          );
        }
        return false;
      }

      if (restorePurchases) {
        await _iosIapService.restorePurchases();
      }

      final String receiptData =
          (await _iosIapService.fetchCurrentAppStoreReceipt())?.trim() ?? "";
      if (receiptData.isEmpty) {
        if (showFailureMessage) {
          Get.snackbar(
            "Restore Purchases",
            "App Store receipt is unavailable on this device.",
          );
        }
        return false;
      }

      final payload = <String, dynamic>{
        "subscription_id": savedSubscriptionId,
        "product_id": productId,
        "receipt_data": receiptData,
      };

      final statusRes = await _repository.fetchIosSubscriptionStatus(
        token: token,
        body: payload,
      );
      final statusDecoded = _decodeMapSafely(statusRes.body);
      if (!_responseSuccess(
        statusCode: statusRes.statusCode,
        decoded: statusDecoded,
      )) {
        if (showFailureMessage) {
          Get.snackbar(
            "Restore Purchases",
            _messageFromResponse(
              statusDecoded,
              fallback: "Unable to confirm iOS subscription status.",
            ),
          );
        }
        return false;
      }

      final bool isActive = _readBoolFlag(statusDecoded["is_active"]);
      if (!isActive) {
        if (showFailureMessage) {
          Get.snackbar(
            "Restore Purchases",
            "No active App Store subscription was found for this account.",
          );
        }
        return false;
      }

      await _repository.saveActiveIosPurchaseSyncState(
        subscriptionId: savedSubscriptionId,
        productId: productId,
      );
      subscriptionId.value = savedSubscriptionId;

      if (showSuccessMessage) {
        Get.snackbar(
          "Restore Purchases",
          _messageFromResponse(
            statusDecoded,
            fallback: "Subscription restored successfully.",
          ),
        );
      }
      return true;
    } catch (_) {
      if (showFailureMessage) {
        Get.snackbar(
          "Restore Purchases",
          "Unable to restore your App Store subscription right now.",
        );
      }
      return false;
    }
  }

  Future<bool> completePayment({
    required String razorpayPaymentId,
    int? subscriptionIdValue,
    String? paymentType,
    String? txnId,
    String? transactionDetail,
  }) async {
    if (isPaymentSubmitting.value) return false;

    try {
      isPaymentSubmitting.value = true;

      final paymentId = (txnId ?? razorpayPaymentId).trim();
      if (paymentId.isEmpty) {
        Get.snackbar("Payment Error", "Payment ID missing");
        return false;
      }

      final token = await _repository.getToken();
      if (token == null || token.isEmpty) {
        Get.snackbar("Payment Error", "User not logged in");
        return false;
      }

      final effectiveId =
          subscriptionIdValue ?? await _repository.getSavedSubscriptionId();
      if (effectiveId == 0) {
        Get.snackbar("Payment Error", "Subscription ID missing");
        return false;
      }

      final normalizedPaymentType = paymentType?.trim() ?? "";
      if (Platform.isIOS && normalizedPaymentType == PAYMENT_TYPE_IAP) {
        final decodedTransactionDetail = _decodeMapSafely(transactionDetail);
        final productId = _normalizeString(
          decodedTransactionDetail["product_id"],
        );
        final purchaseId = _normalizeString(
          decodedTransactionDetail["purchase_id"],
        );
        final originalTransactionId = _normalizeString(
          decodedTransactionDetail["original_transaction_id"],
        );
        final purchaseStatus = _normalizeString(
          decodedTransactionDetail["status"],
        );
        final transactionDate = _normalizeString(
          decodedTransactionDetail["transaction_date"],
        );
        final appStoreReceipt = _normalizeString(
          decodedTransactionDetail["app_store_receipt"],
        );
        final explicitReceiptData = _normalizeString(
          decodedTransactionDetail["receipt_data"],
        );
        final storeKitServerVerificationData = _normalizeString(
          decodedTransactionDetail["server_verification_data"],
        );
        final localReceiptData = _normalizeString(
          decodedTransactionDetail["local_verification_data"],
        );
        final receiptData = appStoreReceipt.isNotEmpty
            ? appStoreReceipt
            : explicitReceiptData.isNotEmpty
                ? explicitReceiptData
                : storeKitServerVerificationData;

        final payload = <String, dynamic>{
          "subscription_id": effectiveId.toString(),
          "payment_type": PAYMENT_TYPE_IAP,
          "txn_id": paymentId,
          "transaction_id": paymentId,
          "razorpay_payment_id": paymentId,
          "transaction_detail": transactionDetail?.trim() ?? "",
          "source": "app_store_iap",
          "platform": "ios",
          if (selectedPackageId > 0) "package_id": selectedPackageId.toString(),
          if (productId.isNotEmpty) "product_id": productId,
          if (purchaseId.isNotEmpty) "purchase_id": purchaseId,
          if (originalTransactionId.isNotEmpty)
            "original_transaction_id": originalTransactionId,
          if (purchaseStatus.isNotEmpty) "purchase_status": purchaseStatus,
          if (transactionDate.isNotEmpty) "transaction_date": transactionDate,
          if (receiptData.isNotEmpty) "receipt_data": receiptData,
          if (appStoreReceipt.isNotEmpty) "app_store_receipt": appStoreReceipt,
          if (receiptData.isNotEmpty) "server_verification_data": receiptData,
          if (localReceiptData.isNotEmpty)
            "local_verification_data": localReceiptData,
          if (storeKitServerVerificationData.isNotEmpty)
            "storekit_server_verification_data": storeKitServerVerificationData,
        };

        final verifyRes = await _repository.verifyIosPurchase(
          token: token,
          body: payload,
        );
        final verifyDecoded = _decodeMapSafely(verifyRes.body);
        if (!_responseSuccess(
          statusCode: verifyRes.statusCode,
          decoded: verifyDecoded,
        )) {
          Get.snackbar(
            "Payment Error",
            _messageFromResponse(
              verifyDecoded,
              fallback: "iOS purchase verification failed.",
            ),
          );
          return false;
        }

        final iosCompleteRes = await _repository.completeIosPayment(
          token: token,
          body: payload,
        );
        final iosCompleteDecoded = _decodeMapSafely(iosCompleteRes.body);
        if (!_responseSuccess(
          statusCode: iosCompleteRes.statusCode,
          decoded: iosCompleteDecoded,
        )) {
          Get.snackbar(
            "Payment Error",
            _messageFromResponse(
              iosCompleteDecoded,
              fallback: "iOS payment completion failed.",
            ),
          );
          return false;
        }

        final statusRes = await _repository.fetchIosSubscriptionStatus(
          token: token,
          body: payload,
        );
        final statusDecoded = _decodeMapSafely(statusRes.body);
        if (!_responseSuccess(
          statusCode: statusRes.statusCode,
          decoded: statusDecoded,
        )) {
          Get.snackbar(
            "Payment Error",
            _messageFromResponse(
              statusDecoded,
              fallback: "Unable to confirm iOS subscription status.",
            ),
          );
          return false;
        }

        final bool isActive = _readBoolFlag(statusDecoded["is_active"]);
        if (!isActive) {
          Get.snackbar(
            "Payment Error",
            "App Store subscription is not active yet. Please try again.",
          );
          return false;
        }

        final String syncProductId =
            productId.isNotEmpty ? productId : _resolveSavedIosProductId();
        if (syncProductId.isNotEmpty) {
          await _repository.saveActiveIosPurchaseSyncState(
            subscriptionId: effectiveId,
            productId: syncProductId,
          );
        }
        Get.snackbar(
          "Success",
          _messageFromResponse(
            iosCompleteDecoded,
            fallback: "Payment successful",
          ),
        );
        return true;
      }

      final res = await _repository.completePayment(
        token: token,
        subscriptionId: effectiveId,
        razorpayPaymentId: paymentId,
        paymentType: paymentType,
        txnId: txnId ?? paymentId,
        transactionDetail: transactionDetail,
      );

      final decoded = res.body.trim().isNotEmpty
          ? _repository.toMap(res.body)
          : const <String, dynamic>{};
      final hasStatusFlag = decoded.containsKey("status");
      final apiSuccess =
          hasStatusFlag ? decoded["status"] == true : res.statusCode == 200;

      if (!apiSuccess) {
        final msg = decoded["message"]?.toString() ?? "Payment failed";
        Get.snackbar("Payment Error", msg);
        return false;
      }

      await _repository.clearSavedSubscriptionId();
      Get.snackbar(
        "Success",
        decoded["message"]?.toString() ?? "Payment successful",
      );
      return true;
    } on TimeoutException {
      Get.snackbar("Payment Error", "Request timed out. Please try again.");
      return false;
    } catch (e) {
      debugPrint("completePayment error: $e");
      Get.snackbar("Payment Error", "Payment verification failed.");
      return false;
    } finally {
      isPaymentSubmitting.value = false;
    }
  }
}
