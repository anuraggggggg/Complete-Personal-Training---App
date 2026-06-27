import 'dart:async';
import 'dart:io';

import 'package:animate_do/animate_do.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:lottie/lottie.dart';
import 'package:mighty_fitness/extensions/loader_widget.dart';
import 'package:mighty_fitness/extensions/LiveStream.dart';
import 'package:mighty_fitness/features/shop/viewmodels/shop_view_model.dart';
import 'package:mighty_fitness/Chat/model/subscription_diet_plan_model.dart';
import 'package:mighty_fitness/models/get_coupons.dart';
import 'package:mighty_fitness/screens/privacy_policy_screen.dart';
import 'package:mighty_fitness/screens/terms_and_conditions_screen.dart';
import 'package:mighty_fitness/service/ios_iap_service.dart';
import 'package:mighty_fitness/utils/app_colors.dart';
import 'package:mighty_fitness/utils/app_common.dart';
import 'package:mighty_fitness/utils/app_constants.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../main.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});
  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  static const String _razorpayKeyId = "rzp_live_RsCjRLal1MjiQT";

  final ShopViewModel vm = Get.isRegistered<ShopViewModel>()
      ? Get.find<ShopViewModel>()
      : Get.put(ShopViewModel(), permanent: Platform.isIOS);
  final IOSIapService _iosIapService = IOSIapService();

  final TextEditingController _couponTextCtrl = TextEditingController();
  bool _isProcessingIosPurchase = false;
  String _iosPurchaseOverlayTitle = "Connecting to App Store...";
  String _iosPurchaseOverlaySubtitle =
      "Please wait while we prepare your subscription purchase.";
  bool _isLoadingIosProducts = Platform.isIOS;
  Set<String> _availableIosProductIds = <String>{};
  Map<String, ProductDetails> _availableIosProductsById =
      <String, ProductDetails>{};
  List<String> _lastQueriedIosProductIds = const <String>[];
  late Razorpay _razorpay;
  Worker? _planAvailabilityWorker;
  Worker? _selectedPlanAvailabilityWorker;
  Function(PaymentSuccessResponse response)? _successCallback;

  Future<void> _refreshSubscriptionAfterPayment() async {
    if (!mounted || userStore.userId <= 0) return;

    try {
      await getUSerDetail(context, userStore.userId);
      LiveStream().emit(PAYMENT);
    } catch (e) {
      debugPrint('Subscription refresh after payment failed: $e');
    }
  }

  List<String>? _mergeIosProductIds(
    List<String>? primary,
    List<String>? fallback,
  ) {
    final ids = <String>{};
    if (primary != null) {
      ids.addAll(
          primary.where((e) => e.trim().isNotEmpty).map((e) => e.trim()));
    }
    if (fallback != null) {
      ids.addAll(
        fallback.where((e) => e.trim().isNotEmpty).map((e) => e.trim()),
      );
    }
    if (ids.isEmpty) return null;
    return ids.toList();
  }

  List<String> _collectIosProductIdsForAvailability() {
    final ids = <String>{};

    for (final plan in vm.plans) {
      final productIds = plan.iosProductIds;
      if (productIds == null) continue;

      for (final productId in productIds) {
        final normalized = productId.trim();
        if (normalized.isNotEmpty) {
          ids.add(normalized);
        }
      }
    }

    final selectedIds = vm.selectedPlan.value?.iosProductIds;
    if (selectedIds != null) {
      for (final productId in selectedIds) {
        final normalized = productId.trim();
        if (normalized.isNotEmpty) {
          ids.add(normalized);
        }
      }
    }

    final sortedIds = ids.toList()..sort();
    return sortedIds;
  }

  List<Data> _sortByDuration(List<Data> list) {
    final sorted = [...list];
    sorted.sort((a, b) => (a.duration ?? 0).compareTo(b.duration ?? 0));
    return sorted;
  }

  List<Data> filterDietExcept(List<Data> all, Data? exclude) {
    if (exclude == null) return all;
    return all.where((e) => e.id != exclude.id).toList();
  }

  // -------- DESCRIPTION PARSER --------
  String _toPlainText(String? value) {
    if (value == null || value.trim().isEmpty) return '';
    final parsed = html_parser.parse(value).documentElement?.text ?? value;
    return parsed
        .replaceAll('\u00A0', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  List<String> parseDescription(String? desc) {
    if (desc == null || desc.trim().isEmpty) return [];
    return _toPlainText(desc)
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  bool _isOfferPlan(Data planData) {
    return (planData.description != null && planData.description!.isNotEmpty) ||
        (planData.duration != null && planData.duration! >= 12);
  }

  /// 🔥 SORT: HIGH PRICE → LOW PRICE
  List<Data> _sortedPlans(List<Data> list) {
    final sorted = [...list];
    sorted.sort(
      (a, b) => (b.price ?? 0).compareTo(a.price ?? 0),
    );
    return sorted;
  }

  int _planPrice(Data planData) {
    if (!Platform.isIOS) return planData.price ?? 0;

    return _iosIapService.resolvePrice(
      fallbackPrice: planData.price ?? 0,
      packageType: planData.packageType,
      planName: planData.name,
      planDescription: planData.description,
      duration: planData.duration,
      durationUnit: planData.durationUnit,
    );
  }

  String _priceLabelForPlan(Data planData, {int? fallbackPrice}) {
    final int resolvedFallbackPrice = fallbackPrice ?? _planPrice(planData);
    if (!Platform.isIOS) return "₹$resolvedFallbackPrice";

    final mergedIds = _resolvedIosProductIdsForPlan(planData);

    for (final productId in mergedIds) {
      final ProductDetails? product = _availableIosProductsById[productId];
      final String localizedPrice = product?.price.trim() ?? '';
      if (localizedPrice.isNotEmpty) {
        return localizedPrice;
      }
    }

    return "₹$resolvedFallbackPrice";
  }

  bool get _supportsAndroidCheckout => Platform.isAndroid;

  bool get _supportsExternalDiscounts => _supportsAndroidCheckout;

  List<String> _resolvedIosProductIdsForPlan(Data planData) {
    return _mergeIosProductIds(
          planData.iosProductIds,
          vm.selectedPlan.value?.id == planData.id
              ? vm.selectedPlan.value?.iosProductIds
              : null,
        ) ??
        const <String>[];
  }

  bool get _hasFinishedIosCatalogLookup =>
      Platform.isIOS &&
      !_isLoadingIosProducts &&
      _lastQueriedIosProductIds.isNotEmpty;

  bool _canPurchasePlan(Data planData) {
    if (_supportsAndroidCheckout) return true;
    if (!Platform.isIOS) return false;

    // iOS purchases do a definitive StoreKit lookup on tap.
    // Warm-up catalog fetches should not hard-block the CTA.
    return true;
  }

  bool _isPlanMissingFromLoadedIosCatalog(Data planData) {
    if (!Platform.isIOS) return false;
    if (_isLoadingIosProducts) return false;

    final List<String> mergedIds = _resolvedIosProductIdsForPlan(planData);
    if (!_hasFinishedIosCatalogLookup) return false;
    if (_availableIosProductIds.isEmpty) return true;
    if (mergedIds.isEmpty) return false;

    return !_iosIapService.isSubscriptionAvailable(
      availableProductIds: _availableIosProductIds,
      packageType: planData.packageType,
      planName: planData.name,
      planDescription: planData.description,
      duration: planData.duration,
      durationUnit: planData.durationUnit,
      productIdsOverride: mergedIds,
    );
  }

  Future<void> _loadIosProductAvailability({
    bool force = false,
  }) async {
    if (!Platform.isIOS) return;

    final extraProductIds = _collectIosProductIdsForAvailability();
    if (!force &&
        !_isLoadingIosProducts &&
        listEquals(_lastQueriedIosProductIds, extraProductIds)) {
      return;
    }

    if (mounted) {
      setState(() {
        _isLoadingIosProducts = true;
      });
    }

    try {
      final availableProducts = await _iosIapService.fetchAvailableProductsById(
        extraProductIds: extraProductIds,
      );
      if (!mounted) return;

      setState(() {
        _availableIosProductsById = availableProducts;
        _availableIosProductIds = availableProducts.keys.toSet();
        _lastQueriedIosProductIds = extraProductIds;
        _isLoadingIosProducts = false;
      });
    } catch (e) {
      debugPrint('[IOS-IAP] failed to fetch available product IDs: $e');
      if (!mounted) return;

      setState(() {
        _availableIosProductsById = <String, ProductDetails>{};
        _availableIosProductIds = <String>{};
        _lastQueriedIosProductIds = extraProductIds;
        _isLoadingIosProducts = false;
      });
    }
  }

  String _purchaseLabelForPlan(Data planData, {String androidLabel = "PAY"}) {
    if (_supportsAndroidCheckout) return androidLabel;
    if (Platform.isIOS) return "SUBSCRIBE";
    return "UNAVAILABLE";
  }

  String? _iosPlanAvailabilityMessage(Data planData) {
    return null;
  }

  Widget _iosCatalogStatusBanner() {
    return const SizedBox.shrink();
  }

  @override
  void initState() {
    super.initState();

    if (vm.plans.isEmpty && !vm.isLoadingPlans.value) {
      unawaited(vm.getSubscriptionPlans());
    }

    if (_supportsAndroidCheckout) {
      _razorpay = Razorpay();

      _razorpay.on(
        Razorpay.EVENT_PAYMENT_SUCCESS,
        _handlePaymentSuccess,
      );
      _razorpay.on(
        Razorpay.EVENT_PAYMENT_ERROR,
        _handlePaymentError,
      );
      _razorpay.on(
        Razorpay.EVENT_EXTERNAL_WALLET,
        _handleExternalWallet,
      );
    }

    if (_supportsExternalDiscounts) {
      unawaited(vm.refreshReferral());
      unawaited(vm.fetchCoupons());
    }
    if (Platform.isIOS) {
      _planAvailabilityWorker = ever<List<Data>>(vm.planList, (_) {
        unawaited(_loadIosProductAvailability());
      });
      _selectedPlanAvailabilityWorker = ever<Data?>(vm.selectedPlan, (_) {
        unawaited(_loadIosProductAvailability());
      });
      unawaited(_loadIosProductAvailability());
    }
  }

  @override
  void dispose() {
    _couponTextCtrl.dispose();
    _planAvailabilityWorker?.dispose();
    _selectedPlanAvailabilityWorker?.dispose();
    if (_supportsAndroidCheckout) {
      _razorpay.clear(); // 🔥 VERY IMPORTANT
    }
    super.dispose();
  }

  Future<({int subscriptionId, List<String>? iosProductIds})?>
      _prepareSubscriptionForPayment({
    bool showErrors = true,
  }) async {
    final selectedPackageId = vm.selectedPackageId;

    if (selectedPackageId == 0) {
      if (showErrors) {
        Get.snackbar(
          "Error",
          "No plan selected",
          snackPosition: SnackPosition.BOTTOM,
        );
      }
      return null;
    }

    final subscriptionData = await vm.subscribePackage(
      packageId: selectedPackageId,
      showErrors: showErrors,
    );

    final subscriptionId = vm.subscriptionId.value;
    if (subscriptionId == 0) {
      if (showErrors) {
        Get.snackbar(
          "Error",
          "Subscription creation failed",
          snackPosition: SnackPosition.BOTTOM,
        );
      }
      return null;
    }

    final iosProductIds = _mergeIosProductIds(
      subscriptionData?.iosProductIds,
      subscriptionData?.packageData?.iosProductIds,
    );

    return (subscriptionId: subscriptionId, iosProductIds: iosProductIds);
  }

  bool _shouldRetryIosPurchaseLookup(Object error) {
    final String message = error.toString().toLowerCase();
    return message.contains('no matching app store in-app purchase') ||
        message.contains('app_store_products_not_found') ||
        message.contains(
          'app store did not return any products for this app',
        ) ||
        message.contains('verify the ios bundle identifier') ||
        message
            .contains('could not load this app store subscription right now') ||
        message.contains('could not find this product') ||
        message.contains(
          'unable to match this ios subscription to an app store product',
        ) ||
        message.contains('no app store product is configured') ||
        message.contains('unable to determine the subscription duration') ||
        message.contains('timed out') ||
        message.contains('in-app purchase timed out');
  }

  Future<void> _handleIosIapPayment(Data planData) async {
    if (_isLoadingIosProducts || _isPlanMissingFromLoadedIosCatalog(planData)) {
      unawaited(_loadIosProductAvailability(force: true));
    }

    if (_isProcessingIosPurchase) return;

    if (mounted) {
      setState(() {
        _isProcessingIosPurchase = true;
        _iosPurchaseOverlayTitle = "Opening App Store...";
        _iosPurchaseOverlaySubtitle =
            "Please wait while we open the subscription purchase window.";
      });
    }

    try {
      final existingProductIds = _mergeIosProductIds(
        planData.iosProductIds,
        vm.selectedPlan.value?.iosProductIds,
      );
      List<String>? resolvedProductIds = existingProductIds;
      ({int subscriptionId, List<String>? iosProductIds})? preparedSubscription;

      IOSIapPurchaseResult? purchase;
      Object? lastPurchaseError;

      for (int attempt = 0; attempt < 2; attempt++) {
        try {
          purchase = await _iosIapService.buySubscription(
            backendPrice: _planPrice(planData).toDouble(),
            packageType: planData.packageType,
            planName: planData.name,
            planDescription: planData.description,
            duration: planData.duration,
            durationUnit: planData.durationUnit,
            productIdsOverride:
                (resolvedProductIds != null && resolvedProductIds.isNotEmpty)
                    ? resolvedProductIds
                    : null,
          );
          break;
        } catch (e) {
          lastPurchaseError = e;
          if (attempt == 1 || !_shouldRetryIosPurchaseLookup(e)) {
            rethrow;
          }

          preparedSubscription ??= await _prepareSubscriptionForPayment(
            showErrors: false,
          );
          if (preparedSubscription != null) {
            resolvedProductIds = _mergeIosProductIds(
              resolvedProductIds,
              preparedSubscription.iosProductIds,
            );
          }

          debugPrint(
            '[IOS-IAP] Retrying first-time purchase lookup for '
            '${planData.name} after warm-up failure: $e',
          );
          unawaited(_loadIosProductAvailability(force: true));
          await Future.delayed(const Duration(milliseconds: 400));
        }
      }

      if (purchase == null) {
        throw lastPurchaseError ??
            Exception('Unable to complete the App Store purchase.');
      }

      if (mounted) {
        setState(() {
          _iosPurchaseOverlayTitle = "Finalizing Subscription...";
          _iosPurchaseOverlaySubtitle =
              "Please wait while we confirm your App Store purchase.";
        });
      }

      preparedSubscription ??= await _prepareSubscriptionForPayment(
        showErrors: false,
      );
      if (preparedSubscription == null ||
          preparedSubscription.subscriptionId == 0) {
        Get.snackbar(
          "Payment Error",
          "Purchase succeeded, but subscription activation could not be prepared.",
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      final bool isPaymentDone = await vm.completePayment(
        razorpayPaymentId: purchase.transactionId,
        subscriptionIdValue: preparedSubscription.subscriptionId,
        paymentType: PAYMENT_TYPE_IAP,
        txnId: purchase.transactionId,
        transactionDetail: purchase.transactionDetail,
      );

      if (isPaymentDone) {
        vm.subscriptionId.value = preparedSubscription.subscriptionId;
        await _refreshSubscriptionAfterPayment();
      }
    } catch (e) {
      if (_iosIapService.isUserCancelledError(e)) {
        debugPrint('[IOS-IAP] Purchase cancelled by user.');
        return;
      }

      Get.snackbar(
        "Payment Error",
        _iosIapService.readableErrorMessage(e),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingIosPurchase = false;
        });
      }
    }
  }

  Future<void> _handleRestorePurchases() async {
    if (!Platform.isIOS || _isProcessingIosPurchase) return;

    if (mounted) {
      setState(() {
        _isProcessingIosPurchase = true;
      });
    }

    try {
      await vm.syncIosSubscriptionStatus(
        restorePurchases: true,
        showSuccessMessage: true,
        showFailureMessage: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingIosPurchase = false;
        });
      }
    }
  }

  Future<void> _handleSubscribeTap(Data planData) async {
    await vm.selectPlan(planData);

    if (Platform.isIOS) {
      await _handleIosIapPayment(planData);
      return;
    }
    if (!_supportsAndroidCheckout) {
      Get.snackbar(
        "Unavailable",
        "Subscription checkout is available on Android only.",
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    await _openPaymentSheet(planData);
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    final paymentId = response.paymentId;

    debugPrint("✅ Razorpay Success => $paymentId");

    if (paymentId == null || paymentId.trim().isEmpty) {
      Get.snackbar(
        "Payment Error",
        "Razorpay payment id missing.",
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (_successCallback != null) {
      _successCallback!(response);
      _successCallback = null;
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    debugPrint(
      "❌ Razorpay Failed => ${response.code} | ${response.message}",
    );

    Get.snackbar(
      "Payment Failed",
      response.message ?? "Something went wrong",
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint("👛 External Wallet => ${response.walletName}");
  }

  Future<void> _openTermsOfUse() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const TermsAndConditionScreen(),
      ),
    );
  }

  Future<void> _openPrivacyPolicy() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const PrivacyPolicyScreen(),
      ),
    );
  }

  Widget _legalLinkButton({
    required String label,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;

    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: cs.primary,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        textStyle: GoogleFonts.poppins(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          decoration: TextDecoration.underline,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: cs.primary.withValues(alpha: 0.22)),
        ),
      ),
      child: Text(label),
    );
  }

  Widget _subscriptionLegalNotice({bool compact = false}) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.only(bottom: compact ? 0 : 20),
      padding: EdgeInsets.all(compact ? 16 : 18),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(compact ? 18 : 22),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.45)
                : Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Auto-renewable subscription",
            style: GoogleFonts.poppins(
              fontSize: compact ? 14 : 15,
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Review the Terms of Use and Privacy Policy before purchasing. Subscriptions renew automatically until canceled in App Store account settings.",
            style: GoogleFonts.lato(
              fontSize: compact ? 12 : 12.5,
              height: 1.45,
              color: cs.onSurface.withValues(alpha: 0.72),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _legalLinkButton(
                label: "Terms of Use",
                onTap: () {
                  unawaited(_openTermsOfUse());
                },
              ),
              _legalLinkButton(
                label: "Privacy Policy",
                onTap: () {
                  unawaited(_openPrivacyPolicy());
                },
              ),
              _legalLinkButton(
                label: "Restore Purchases",
                onTap: () {
                  unawaited(_handleRestorePurchases());
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appBarColor = isDark ? const Color(0xFF121212) : Colors.white;
    final titleColor = isDark ? Colors.white : Colors.black;

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            backgroundColor: appBarColor,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            centerTitle: false,
            iconTheme: const IconThemeData(color: Colors.red),
            systemOverlayStyle: SystemUiOverlayStyle(
              statusBarColor: appBarColor,
              statusBarIconBrightness:
                  isDark ? Brightness.light : Brightness.dark,
              statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
            ),
            title: Text(
              "Subscription Plans",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: titleColor,
              ),
            ),
          ),
          body: Obx(() {
            if (vm.isLoadingPlans.value) {
              return Center(child: Loader());
            }

            final plans = vm.plans;
            if (plans.isEmpty) {
              return Center(
                child: Text(
                  "No plans available",
                  style: TextStyle(color: cs.onSurface.withOpacity(0.7)),
                ),
              );
            }

            // 🔥 SORTED BY PRICE (HIGH → LOW)

            final allDietPlans = plans
                .where((e) => e.packageType?.toLowerCase() == "diet")
                .toList();

            final onlyDietOneMonth = allDietPlans.firstWhereOrNull((e) {
              final unit = e.durationUnit?.toLowerCase().trim();
              return e.duration == 1 &&
                  (unit == "monthly" || unit == "month" || unit == "months");
            });
            debugPrint("OnlyDietOneMonth => ${onlyDietOneMonth?.name}");

            final otherDietPlans =
                filterDietExcept(allDietPlans, onlyDietOneMonth);

            final workoutPlans = _sortedPlans(
                plans.where((e) => e.packageType == "workout").toList());
            final comboPlans = _sortedPlans(
              plans
                  .where(
                    (e) =>
                        e.packageType == "both" &&
                        !(e.name?.toLowerCase().startsWith("offer") ?? false),
                  )
                  .toList(),
            );

            final offerPlans = _sortedPlans(
              plans
                  .where(
                    (e) => e.name?.toLowerCase().startsWith("offer") ?? false,
                  )
                  .toList(),
            );

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
              children: [
                const SizedBox(height: 20),

                _offerSection(),
                SizedBox(
                  height: 10,
                ),
                if (Platform.isIOS) _subscriptionLegalNotice(),
                if (Platform.isIOS) _iosCatalogStatusBanner(),

                if (_supportsExternalDiscounts) _referralSection(),

                if (_supportsExternalDiscounts) _myCouponsSection(),
                if (_supportsExternalDiscounts)
                  SizedBox(
                    height: 10,
                  ),

                /// 🥗 DIET + WORKOUT
                _planGroupCard(
                  title: " Diet Plan + Workout",
                  subtitle: "",
                  plans: _sortByDuration(comboPlans),
                  showFreeInfo: true,
                ),

                /// 🍽 ONLY DIET (1 MONTH) — SEPARATE CATEGORY
                if (onlyDietOneMonth != null)
                  _planGroupCard(
                    title: " Only Diet Plan (1 Month)",
                    subtitle: "",
                    plans: [onlyDietOneMonth],
                  ),

                if (otherDietPlans.isNotEmpty)
                  _planGroupCard(
                    title: " Diet Plans",
                    subtitle: "",
                    plans: _sortByDuration(otherDietPlans),
                  ),

                /// 🏋️ ONLY WORKOUT
                _planGroupCard(
                  title: "🏋️ Only Workout Plan",
                  subtitle: "Workout videos access",
                  plans: _sortByDuration(workoutPlans),
                  showFreeInfo: true,
                ),

                /// 🎁 OFFERS
                if (offerPlans.isNotEmpty) _offersCard(offerPlans),

                if (_supportsExternalDiscounts) _applyCouponSection(),
              ],
            );
          }),
        ),
        if (_isProcessingIosPurchase)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.25),
              child: Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 14),
                      Text(
                        _iosPurchaseOverlayTitle,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _iosPurchaseOverlaySubtitle,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.lato(
                          fontSize: 12.5,
                          color: Colors.black.withOpacity(0.65),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ================= SECTION TITLE =================
  Widget _sectionTitle(String title) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 26, bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: cs.onSurface,
        ),
      ),
    );
  }

  Widget _referralSection() {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      final hasCode = vm.referralCode.trim().isNotEmpty;

      if (vm.isReferralLoading.value && !hasCode) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Center(
            child: CircularProgressIndicator(
              color: cs.primary,
            ),
          ),
        );
      }

      if (!vm.isReferralActive && !hasCode) {
        return const SizedBox.shrink();
      }

      return FadeInUp(
        duration: const Duration(milliseconds: 450),
        child: Container(
          margin: const EdgeInsets.only(bottom: 22),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),

            /// 🌈 GRADIENT BACKGROUND
            gradient: LinearGradient(
              colors: isDark
                  ? [
                      cs.surface,
                      cs.surface.withOpacity(0.9),
                    ]
                  : [
                      cs.primary.withOpacity(0.12),
                      cs.primary.withOpacity(0.04),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),

            border: Border.all(
              color: cs.primary.withOpacity(0.35),
            ),

            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.55)
                    : Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// 🔥 HEADER ROW
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 70,
                    width: 70,
                    child: Lottie.asset(
                      "assets/send mail.json",
                      repeat: true,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Invite & Earn",
                          style: GoogleFonts.poppins(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Share with friends & earn rewards",
                          style: GoogleFonts.lato(
                            fontSize: 13,
                            color: cs.onSurface.withOpacity(0.65),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: vm.isReferralLoading.value
                        ? null
                        : () async {
                            await vm.refreshReferral();
                          },
                    icon: const Icon(Icons.refresh_rounded),
                    color: cs.primary,
                    tooltip: "Refresh referral",
                  ),
                ],
              ),

              const SizedBox(height: 14),

              /// 🧾 REFERRAL CODE BOX
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: cs.surface.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: cs.primary.withOpacity(0.35),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        vm.referralCode,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: cs.primary,
                        ),
                      ),
                    ),

                    /// 📋 COPY
                    IconButton(
                      icon: const Icon(Icons.copy_rounded),
                      color: cs.primary,
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(
                            text: vm.referralCode,
                          ),
                        );
                        Get.snackbar(
                          "Copied",
                          "Referral code copied to clipboard",
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      },
                    ),

                    /// 📤 SHARE
                    IconButton(
                      icon: const Icon(Icons.share_rounded),
                      color: cs.primary,
                      onPressed: () {
                        Share.share(
                          "🔥 Join CPT Fitness\n\n"
                          "Use my referral code: ${vm.referralCode}\n"
                          "Get exclusive rewards 💪✨",
                        );
                      },
                    ),
                  ],
                ),
              ),

              /// 💰 CREDIT INFO
              if (vm.hasReferralCredit) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.account_balance_wallet_rounded,
                      size: 18,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "Available Credit: ₹${vm.referralCredit}",
                      style: GoogleFonts.lato(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 10),

              /// ℹ️ FOOTER TEXT
              Text(
                "Your friends get benefits. You earn rewards after successful referral.",
                style: GoogleFonts.lato(
                  fontSize: 11.5,
                  height: 1.4,
                  color: cs.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _myCouponsSection() {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      if (!_supportsExternalDiscounts) {
        return const SizedBox.shrink();
      }

      /// ❌ If coupons should not be visible
      if (!vm.canShowCoupons) {
        return const SizedBox.shrink();
      }

      /// ⏳ Loading
      if (vm.isCouponsLoading.value) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Center(
            child: CircularProgressIndicator(color: cs.primary),
          ),
        );
      }

      final coupons = vm.activeCoupons;

      /// 💤 EMPTY STATE — NO COUPONS
      if (coupons.isEmpty) {
        return FadeInUp(
          duration: const Duration(milliseconds: 400),
          child: Container(
            margin: const EdgeInsets.only(top: 24),
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 26,
            ),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: cs.onSurface.withOpacity(0.12),
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withOpacity(0.5)
                      : Colors.black.withOpacity(0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                /// 🎞️ LOTTIE EMPTY ANIMATION
                SizedBox(
                  height: 120,
                  width: 120,
                  child: Lottie.asset(
                    "assets/uploading.json",
                    repeat: true,
                    fit: BoxFit.contain,
                  ),
                ),

                const SizedBox(height: 14),

                /// 📝 TITLE
                Text(
                  "No Coupons Available",
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),

                const SizedBox(height: 6),

                /// 🧾 SUBTEXT
                Text(
                  "You don’t have any active coupons right now.\nNew offers will appear here.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lato(
                    fontSize: 12.5,
                    height: 1.4,
                    color: cs.onSurface.withOpacity(0.65),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      /// ✅ COUPONS AVAILABLE
      return FadeInUp(
        duration: const Duration(milliseconds: 450),
        child: Container(
          margin: const EdgeInsets.only(top: 24),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: cs.onSurface.withOpacity(0.12),
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.5)
                    : Colors.black.withOpacity(0.08),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// 🎟 HEADER
              Row(
                children: [
                  SizedBox(
                    height: 52,
                    width: 52,
                    child: Lottie.asset(
                      "assets/Discount Coupon.json",
                      repeat: true,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "My Coupons",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Tap to use or share",
                        style: GoogleFonts.lato(
                          fontSize: 12,
                          color: cs.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              /// 🎫 COUPON LIST
              ...coupons.map((coupon) => _couponCard(coupon)).toList(),
            ],
          ),
        ),
      );
    });
  }

  Widget _couponCard(CouponData coupon) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.primary.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          /// LEFT
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  coupon.code ?? "",
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: cs.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  coupon.description ?? "",
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    color: cs.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),

          /// SHARE
          IconButton(
            icon: const Icon(Icons.share),
            color: cs.primary,
            onPressed: () {
              _shareCoupon(coupon);
            },
          ),
        ],
      ),
    );
  }

  void _shareCoupon(CouponData coupon) {
    Share.share(
      "🔥 Fitness Coupon\n\n"
      "Coupon Code: ${coupon.code}\n"
      "${coupon.description ?? ""}\n\n"
      "Download the app & use this 💪",
    );
  }

  Widget _applyCouponSection() {
    if (!_supportsExternalDiscounts) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FadeInUp(
      duration: const Duration(milliseconds: 400),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: cs.surface,
          border: Border.all(
            color: cs.onSurface.withOpacity(0.12),
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.6)
                  : Colors.black.withOpacity(0.08),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🔥 TITLE ROW
            Row(
              children: [
                /// 🎉 LOTTIE (allowed, no color dependency)
                SizedBox(
                  height: 90,
                  width: 90,
                  child: Lottie.asset(
                    "assets/Sale.json",
                    repeat: true,
                    fit: BoxFit.contain,
                  ),
                ),

                const SizedBox(width: 6),

                /// 🏷 TEXT
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Have a Coupon Code?",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Apply coupon to get instant discount",
                      style: GoogleFonts.lato(
                        fontSize: 13,
                        color: cs.onSurface.withOpacity(0.65),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            /// 🎟 INPUT + APPLY
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _couponTextCtrl,
                    textCapitalization: TextCapitalization.characters,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                    cursorColor: cs.onSurface,
                    decoration: InputDecoration(
                      hintText: "ENTER COUPON CODE",
                      hintStyle: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: cs.onSurface.withOpacity(0.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: cs.onSurface.withOpacity(0.25),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: cs.onSurface.withOpacity(0.6),
                          width: 1.4,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                /// APPLY BUTTON
                Obx(() {
                  final isLoading = vm.isApplyingCoupon.value;

                  return ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : () {
                            final code = _couponTextCtrl.text.trim();

                            if (code.isEmpty) {
                              Get.snackbar(
                                "Invalid Coupon",
                                "Please enter a coupon code",
                                snackPosition: SnackPosition.BOTTOM,
                              );
                              return;
                            }

                            vm.applyCoupon(code: code);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? primaryColor : Colors.black,
                      disabledBackgroundColor:
                          (isDark ? primaryColor : Colors.black)
                              .withOpacity(0.5),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: isLoading
                        ? SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: isDark ? primaryColor : Colors.white,
                            ),
                          )
                        : Text(
                            "APPLY",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: isDark ? Colors.white : Colors.white,
                            ),
                          ),
                  );
                }),
              ],
            ),

            const SizedBox(height: 10),

            /// ℹ INFO
            Text(
              "Coupon will be applied on checkout",
              style: GoogleFonts.lato(
                fontSize: 11,
                color: cs.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= PRICE ROW =================
  Widget _priceRow(
    Data planData,
    String label,
    int? price,
  ) {
    final cs = Theme.of(context).colorScheme;
    final features = parseDescription(planData.description);
    final isFree = (price ?? 0) == 0;
    final canPurchase = isFree ? false : _canPurchasePlan(planData);
    final iosAvailabilityMessage = _iosPlanAvailabilityMessage(planData);
    final priceLabel = _priceLabelForPlan(
      planData,
      fallbackPrice: price ?? planData.price ?? 0,
    );

    return FadeInUp(
      duration: const Duration(milliseconds: 350),
      child: GestureDetector(
        onTap: canPurchase ? () => _handleSubscribeTap(planData) : null,
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: cs.onSurface.withOpacity(0.12),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// ---------------- PLAN NAME ----------------
              Text(
                planData.name ?? "",
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),

              const SizedBox(height: 6),

              /// ---------------- TOP ROW ----------------
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      "$label • ${planData.duration} ${planData.durationUnit}",
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: cs.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ),

                  /// 💰 PRICE / FREE
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isFree
                          ? Colors.green.withOpacity(0.15)
                          : cs.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      isFree ? "FREE" : priceLabel,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w800,
                        color: isFree ? Colors.green : cs.primary,
                      ),
                    ),
                  ),
                ],
              ),

              /// 🔥 OFFER BADGE
              if (_isOfferPlan(planData)) ...[
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF9800), Color(0xFFE53935)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "BEST VALUE",
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ],

              /// ---------------- DESCRIPTION ----------------
              if (features.isNotEmpty) ...[
                const SizedBox(height: 10),
                Divider(color: cs.onSurface.withOpacity(0.15)),
                const SizedBox(height: 8),
                ...features.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "• ",
                          style: TextStyle(
                            color: cs.onSurface.withOpacity(0.7),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            e,
                            style: GoogleFonts.lato(
                              color: cs.onSurface.withOpacity(0.7),
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              if (iosAvailabilityMessage != null) ...[
                const SizedBox(height: 10),
                Text(
                  iosAvailabilityMessage,
                  style: GoogleFonts.lato(
                    color: cs.primary,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _betterIcon() {
    return Container(
      child: Row(
        children: [
          Text('Hello Everyone'),
          Column(
            children: [
              // GridView.builder(gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3), itemBuilder: (BuildContext context, int index) {
              //   return Card();
              // })
            ],
          )
        ],
      ),
    );
  }

  // ================= INFO STRIP =================
  Widget _infoStrip(String text) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.onSurface.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF22C55E), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.lato(
                color: cs.onSurface.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= OFFER SECTION =================
  Widget _offerSection() {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return FadeInDown(
      duration: const Duration(milliseconds: 500),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),

          /// 🌗 THEME BASED BACKGROUND
          gradient: isDark
              ? null
              : const LinearGradient(
                  colors: [
                    Color(0xFF7C0A02),
                    Color(0xFFD32F2F),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),

          color: isDark ? cs.surface : null,

          border:
              isDark ? Border.all(color: Colors.white.withOpacity(0.12)) : null,

          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.4)
                  : Colors.redAccent.withOpacity(0.35),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🔥 MAIN ROW
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                /// 🔥 OFFER ICON
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark
                        ? Colors.white.withOpacity(0.08)
                        : Colors.white.withOpacity(0.15),
                  ),
                  child: const Icon(
                    Icons.local_fire_department,
                    color: Colors.orangeAccent,
                    size: 26,
                  ),
                ),

                const SizedBox(width: 14),

                /// 🏷️ OFFER TEXT
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "LIMITED TIME OFFER 🎉",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Smart plans. Better results. Limited-time gym offers.",
                        style: GoogleFonts.lato(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),

                /// ➡ CTA BADGE
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    "HOT",
                    style: GoogleFonts.poppins(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),

            /// ❤️ HAPPY CAPTION
            const SizedBox(height: 12),
            Text(
              "Start your fitness journey today — rewards are waiting for you 💪✨",
              style: GoogleFonts.lato(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? cs.onSurface.withOpacity(0.75)
                    : Colors.white.withOpacity(0.95),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= PAYMENT SHEET =================
  Future<void> _openPaymentSheet(Data planData) async {
    final cs = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _paymentTile(
                title: Platform.isIOS
                    ? "Continue with App Store"
                    : "Pay with Razorpay",
                subtitle: Platform.isIOS
                    ? "In-app purchase"
                    : "Secure online payment",
                icon: Platform.isIOS
                    ? Icons.subscriptions_rounded
                    : Icons.credit_card,
                onTap: () async {
                  if (vm.isSubscribing.value || vm.isPaymentSubmitting.value) {
                    return;
                  }

                  Navigator.pop(context);

                  if (Platform.isIOS) {
                    await _handleIosIapPayment(planData);
                    return;
                  }

                  final preparedSubscription =
                      await _prepareSubscriptionForPayment();
                  if (preparedSubscription == null ||
                      preparedSubscription.subscriptionId == 0) {
                    return;
                  }
                  final int subscriptionId =
                      preparedSubscription.subscriptionId;

                  _openRazorpay(
                    amount: planData.price ?? 0,
                    onSuccess: (razorpayResponse) async {
                      final isPaymentDone = await vm.completePayment(
                        razorpayPaymentId: razorpayResponse.paymentId ?? "",
                        subscriptionIdValue: subscriptionId,
                      );

                      if (isPaymentDone) {
                        vm.subscriptionId.value = subscriptionId;
                        await _refreshSubscriptionAfterPayment();
                        await Future.wait([
                          vm.fetchCoupons(),
                          vm.refreshReferral(),
                        ]);
                      }
                    },
                  );
                },
              ),
              if (Platform.isIOS) ...[
                const SizedBox(height: 16),
                _subscriptionLegalNotice(compact: true),
              ],
            ],
          ),
        );
      },
    );
  }

  void _openRazorpay({
    required int amount,
    String? preferredMethod,
    required Function(PaymentSuccessResponse response) onSuccess,
  }) {
    _successCallback = onSuccess;
    if (_razorpayKeyId.startsWith('rzp_test_')) {
      debugPrint(
          "Razorpay is running in TEST mode. Real bank debit will not happen.");
    }
    if (amount <= 0) {
      Get.snackbar(
        "Payment Error",
        "Invalid plan amount.",
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final options = {
      'key': _razorpayKeyId,
      'amount': amount * 100,
      'currency': 'INR',
      'name': 'CPT Fitness',
      'description': 'Subscription Payment',
      if (preferredMethod != null) 'method': preferredMethod,
      'prefill': {
        'contact': userStore.phoneNo.trim().isNotEmpty
            ? userStore.phoneNo.trim()
            : '9999999999',
        'email': userStore.email.trim().isNotEmpty
            ? userStore.email.trim()
            : 'test@cptfitness.com',
      },
      'theme': {
        'color': '#E10600',
      },
    };

    try {
      debugPrint("Opening Razorpay for Rs $amount");
      _razorpay.open(options);
    } catch (e) {
      debugPrint("Razorpay Open Error: $e");
      Get.snackbar("Payment Error", "Unable to open Razorpay");
    }
  }

  Widget _planGroupCard({
    required String title,
    required String subtitle,
    required List<Data> plans,
    bool showFreeInfo = false,
  }) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bool isDietPlan = title.toLowerCase().contains("diet");

    return FadeInUp(
      duration: const Duration(milliseconds: 400),
      child: Container(
        margin: const EdgeInsets.only(bottom: 26),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: cs.surface,
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.6)
                  : Colors.black.withOpacity(0.08),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
          border: Border.all(
            color: cs.onSurface.withOpacity(0.12),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// 🔥 HEADER WITH ICON
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  /// 🥗 LOTTIE ICON (ONLY FOR DIET)
                  if (isDietPlan)
                    SizedBox(
                      height: 80,
                      width: 82,
                      child: Lottie.asset(
                        "assets/Nutrition.json",
                        repeat: true,
                        fit: BoxFit.contain,
                      ),
                    ),

                  if (isDietPlan) const SizedBox(width: 10),

                  /// TITLE + SUBTITLE
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: cs.onSurface,
                          ),
                        ),
                        if (subtitle.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: GoogleFonts.lato(
                              fontSize: 12.5,
                              color: cs.onSurface.withOpacity(0.65),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              /// 🧩 PLAN ROWS
              ...plans.map(_planOptionRow),
            ],
          ),
        ),
      ),
    );
  }

  Widget _onlyDietFlatCard(List<Data> dietPlans) {
    final cs = Theme.of(context).colorScheme;

    if (dietPlans.isEmpty) return const SizedBox.shrink();

    return FadeInUp(
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            colors: [
              cs.primary.withOpacity(0.20),
              cs.primary.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: cs.primary.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// TITLE
            Text(
              " Only Diet Plan",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: cs.onSurface,
              ),
            ),

            const SizedBox(height: 14),

            /// DIET OPTIONS (dynamic)
            ...dietPlans.map((plan) {
              final descriptions = parseDescription(plan.description);
              final canPurchase = _canPurchasePlan(plan);
              final priceLabel = _priceLabelForPlan(plan);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cs.surface.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: cs.onSurface.withOpacity(0.1),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// LEFT
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plan.name ?? "Diet Plan",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: cs.onSurface,
                            ),
                          ),
                          if (descriptions.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            ...descriptions.map(
                              (d) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("• "),
                                    Expanded(
                                      child: Text(
                                        d,
                                        style: GoogleFonts.lato(
                                          fontSize: 12.5,
                                          height: 1.4,
                                          color: cs.onSurface.withOpacity(0.7),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(width: 10),

                    /// RIGHT (PRICE + BUTTON)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          priceLabel,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: cs.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: canPurchase
                              ? () => _handleSubscribeTap(plan)
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: cs.primary,
                            disabledBackgroundColor:
                                cs.onSurface.withOpacity(0.2),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            _purchaseLabelForPlan(
                              plan,
                              androidLabel: "PAY",
                            ),
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _offersCard(List<Data> offerPlans) {
    final cs = Theme.of(context).colorScheme;

    return FadeInUp(
      child: Container(
        margin: const EdgeInsets.only(bottom: 30),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cs.onSurface.withOpacity(0.12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// TITLE
            Text(
              "🎁 Offers & Family Plans",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 12),

            ...offerPlans.map((plan) {
              final resolvedPrice = _planPrice(plan);
              final isFree = resolvedPrice == 0;
              final offerDescription = _toPlainText(plan.description);
              final priceLabel = _priceLabelForPlan(
                plan,
                fallbackPrice: resolvedPrice,
              );

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: cs.onSurface.withOpacity(0.08),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// LEFT CONTENT
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plan.name ?? "",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            offerDescription,
                            style: GoogleFonts.lato(
                              fontSize: 12,
                              height: 1.4,
                              color: cs.onSurface.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            isFree ? "FREE" : priceLabel,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              color: isFree ? Colors.green : cs.primary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 10),

                    /// RIGHT BUTTON
                    ElevatedButton(
                      onPressed: isFree || !_canPurchasePlan(plan)
                          ? null
                          : () {
                              vm.selectPlan(plan); // 🔥 ADDED
                              _handleSubscribeTap(plan);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isFree ? Colors.green : cs.primary,
                        disabledBackgroundColor: isFree
                            ? Colors.green.withOpacity(0.6)
                            : cs.onSurface.withOpacity(0.2),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        isFree ? "FREE" : _purchaseLabelForPlan(plan),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _planOptionRow(Data planData) {
    final cs = Theme.of(context).colorScheme;
    final isBest = (planData.duration ?? 0) >= 12;

    final descriptions = parseDescription(planData.description);
    final priceLabel = _priceLabelForPlan(planData);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),

        /// 🌈 ROW GRADIENT
        gradient: LinearGradient(
          colors: isBest
              ? [
                  cs.primary.withOpacity(0.30),
                  cs.primary.withOpacity(0.10),
                ]
              : [
                  cs.primary.withOpacity(0.15),
                  cs.primary.withOpacity(0.04),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: isBest
              ? cs.primary.withOpacity(0.5)
              : cs.primary.withOpacity(0.25),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: cs.surface.withOpacity(0.95),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🔹 TOP ROW
            Row(
              children: [
                /// ⏳ DURATION + PRICE
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${planData.duration} ${planData.durationUnit}",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        priceLabel,
                        style: GoogleFonts.lato(
                          fontSize: 13,
                          color: cs.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),

                /// ⭐ BEST VALUE
                if (isBest)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.green, Color(0xFF22C55E)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      "BEST VALUE",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                /// 🟢 BUTTON
                ElevatedButton(
                  onPressed: _canPurchasePlan(planData)
                      ? () {
                          vm.selectPlan(planData); // 🔥 ADDED
                          _handleSubscribeTap(planData);
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary,
                    disabledBackgroundColor: cs.onSurface.withOpacity(0.2),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 6,
                  ),
                  child: Text(
                    _purchaseLabelForPlan(planData),
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),

            /// 🌟 DESCRIPTION (PREMIUM)
            if (descriptions.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      cs.primary.withOpacity(0.10),
                      cs.primary.withOpacity(0.04),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: descriptions.map((d) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            height: 18,
                            width: 18,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF22C55E),
                                  Color(0xFF16A34A),
                                ],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              d,
                              style: GoogleFonts.lato(
                                fontSize: 12.5,
                                height: 1.5,
                                fontWeight: FontWeight.w500,
                                color: cs.onSurface.withOpacity(0.85),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
            if (_iosPlanAvailabilityMessage(planData) != null) ...[
              const SizedBox(height: 10),
              Text(
                _iosPlanAvailabilityMessage(planData)!,
                style: GoogleFonts.lato(
                  fontSize: 12,
                  height: 1.4,
                  color: cs.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _paymentTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.onSurface.withOpacity(0.12)),
        ),
        child: Row(
          children: [
            Icon(icon, color: cs.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          color: cs.onSurface, fontWeight: FontWeight.w600)),
                  Text(subtitle,
                      style: TextStyle(color: cs.onSurface.withOpacity(0.6))),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: cs.onSurface.withOpacity(0.6)),
          ],
        ),
      ),
    );
  }
}
