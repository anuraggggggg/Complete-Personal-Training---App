import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:mighty_fitness/Chat/model/subscription_diet_plan_model.dart'
    as plan_model;
import 'package:mighty_fitness/controllers/apply_coupon_controller/access_gate_controller.dart';
import 'package:mighty_fitness/extensions/extension_util/context_extensions.dart';
import 'package:mighty_fitness/extensions/extension_util/int_extensions.dart';
import 'package:mighty_fitness/extensions/extension_util/widget_extensions.dart';
import 'package:mighty_fitness/extensions/LiveStream.dart';
import 'package:mighty_fitness/extensions/shared_pref.dart';
import 'package:mighty_fitness/extensions/text_styles.dart';
import 'package:mighty_fitness/features/shop/data/shop_repository.dart';
import 'package:mighty_fitness/features/shop/viewmodels/shop_view_model.dart';
import 'package:mighty_fitness/main.dart';
import 'package:mighty_fitness/models/user_response.dart' as user_model;
import 'package:mighty_fitness/screens/dashboard_screen.dart';
import 'package:mighty_fitness/screens/sign_in_screen.dart';
import 'package:mighty_fitness/security/screen_security_service.dart';
import 'package:mighty_fitness/service/ios_iap_service.dart';
import 'package:mighty_fitness/utils/app_colors.dart';
import 'package:mighty_fitness/utils/app_common.dart';
import 'package:mighty_fitness/utils/app_constants.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

enum TrialPaymentMethod {
  razorpay,
  inAppPurchase,
}

enum TrialSubscriptionState {
  pendingAuthorization,
  trialActive,
  paidActive,
  paymentFailed,
  cancelled,
}

class FreeTrialAutoPaySubscriptionScreen extends StatefulWidget {
  const FreeTrialAutoPaySubscriptionScreen({super.key});

  @override
  State<FreeTrialAutoPaySubscriptionScreen> createState() =>
      _FreeTrialAutoPaySubscriptionScreenState();
}

class _FreeTrialAutoPaySubscriptionScreenState
    extends State<FreeTrialAutoPaySubscriptionScreen> {
  static const String _razorpayKeyId = "rzp_live_RsCjRLal1MjiQT";
  static const int _razorpayAutopayTotalCount = 50;

  late final Razorpay _razorpay;
  final ShopRepository _shopRepository = ShopRepository();
  final IOSIapService _iosIapService = IOSIapService();
  final ShopViewModel _shopVm = Get.isRegistered<ShopViewModel>()
      ? Get.find<ShopViewModel>()
      : Get.put(ShopViewModel(), permanent: Platform.isIOS);
  final TrialPaymentMethod _paymentMethod = Platform.isIOS
      ? TrialPaymentMethod.inAppPurchase
      : TrialPaymentMethod.razorpay;
  TrialSubscriptionState _subscriptionState =
      TrialSubscriptionState.pendingAuthorization;
  Map<String, dynamic> _pendingAutopayCreateData = const <String, dynamic>{};
  bool _isStartingAutopay = false;
  bool _didApplyDefaultPlan = false;

  bool get _isRazorpay => _paymentMethod == TrialPaymentMethod.razorpay;

  String get _platformLabel {
    if (Platform.isIOS) return 'iOS';
    if (Platform.isAndroid) return 'Android';
    return 'Current platform';
  }

  DateTime get _trialEndsAt => DateTime.now().add(const Duration(days: 3));

  Future<void> _setScreenshotProtection({required bool enabled}) async {
    if (!Platform.isAndroid && !Platform.isIOS) return;

    try {
      final screenSecurity = ScreenSecurityService.instance;
      if (enabled) {
        await screenSecurity.enableProtection();
      } else {
        await screenSecurity.disableProtection();
      }
    } catch (error) {
      debugPrint('Free trial screenshot protection failed: $error');
    }
  }

  Future<void> _goBackToLogin() async {
    await removeKey(IS_LOGIN);
    await removeKey(TOKEN);
    await removeKey(USER_ID);
    await setValue("HAS_SUBSCRIPTION", false);
    await userStore.clearUserData();
    await userStore.setLogin(false);
    Get.offAll(() => const SignInScreen());
  }

  @override
  void initState() {
    super.initState();
    _setScreenshotProtection(enabled: true);
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleAutopaySuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handleAutopayError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleAutopayWallet);
    if (_shopVm.plans.isEmpty && !_shopVm.isLoadingPlans.value) {
      _shopVm.getSubscriptionPlans();
    }
  }

  @override
  void dispose() {
    _razorpay.clear();
    _setScreenshotProtection(enabled: false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: context.scaffoldBackgroundColor,
        appBar: AppBar(
          elevation: 0,
          centerTitle: false,
          backgroundColor: context.scaffoldBackgroundColor,
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          leading: IconButton(
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: _goBackToLogin,
          ),
          title: Text('Unlock free trial', style: boldTextStyle(size: 20)),
        ),
        body: SafeArea(
          child: Obx(() => _buildContent(context)),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: Obx(() => _buildFloatingActionButton(context)),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final selectedPlan = _shopVm.selectedPlan.value;
    final displayPlans = _sortedPlans(_shopVm.plans);
    if (!_didApplyDefaultPlan && _shopVm.plans.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_didApplyDefaultPlan && _shopVm.plans.isNotEmpty) {
          _didApplyDefaultPlan = true;
          _shopVm.selectPlan(_defaultTrialPlan(_shopVm.plans));
        }
      });
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 112),
      children: [
        _SubscriptionStatusCard(
          state: _subscriptionState,
          paymentMethod: _paymentMethod,
          trialEndsAt: _trialEndsAt,
        ),
        12.height,
        _TrialHeroCard(
          paymentMethod: _paymentMethod,
          platformLabel: _platformLabel,
          isUnlocked:
              _subscriptionState != TrialSubscriptionState.pendingAuthorization,
        ),
        12.height,
        _AccessRuleCard(
          state: _subscriptionState,
          paymentMethod: _paymentMethod,
        ),
        16.height,
        const _SectionTitle(
          title: 'Choose plan',
          trailing: '3 days free',
        ),
        10.height,
        if (_shopVm.isLoadingPlans.value)
          const _PlansLoadingCard()
        else if (_shopVm.plansErrorMessage.value.isNotEmpty)
          _PlansErrorCard(
            message: _shopVm.plansErrorMessage.value,
            onRetry: _shopVm.getSubscriptionPlans,
          )
        else if (_shopVm.plans.isEmpty)
          _PlansErrorCard(
            message: 'No subscription plans are available right now.',
            onRetry: _shopVm.getSubscriptionPlans,
          )
        else
          ...displayPlans.map(
            (plan) => _PlanCard(
              plan: plan,
              selected: selectedPlan?.id == plan.id,
              onTap: () => _shopVm.selectPlan(plan),
            ),
          ),
        8.height,
        _DisclosureCard(
          paymentMethod: _paymentMethod,
          price: _priceLabelForPlan(selectedPlan),
          interval: _intervalLabelForPlan(selectedPlan),
          trialEndsAt: _trialEndsAt,
        ),
        16.height,
        _SetupFlowCard(paymentMethod: _paymentMethod),
      ],
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    final selectedPlan = _shopVm.selectedPlan.value;
    final width = MediaQuery.sizeOf(context).width - 32;

    return SafeArea(
      top: false,
      child: SizedBox(
        width: width > 0 ? width : double.infinity,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: _PrimaryActionButton(
            paymentMethod: _paymentMethod,
            state: _subscriptionState,
            hasSelectedPlan: selectedPlan != null,
            isProcessing: _isStartingAutopay ||
                _shopVm.isSubscribing.value ||
                _shopVm.isPaymentSubmitting.value,
            onPressed: _startTrialSetup,
          ),
        ),
      ),
    );
  }

  List<plan_model.Data> _sortedPlans(List<plan_model.Data> plans) {
    final sorted = [...plans];
    sorted.sort((a, b) {
      final aPreferred = _isPreferredTrialPlan(a);
      final bPreferred = _isPreferredTrialPlan(b);
      if (aPreferred != bPreferred) return aPreferred ? -1 : 1;
      final aDefaultPrice = a.price == 2799;
      final bDefaultPrice = b.price == 2799;
      if (aDefaultPrice != bDefaultPrice) return aDefaultPrice ? -1 : 1;
      return (a.price ?? 0).compareTo(b.price ?? 0);
    });
    return sorted;
  }

  plan_model.Data _defaultTrialPlan(List<plan_model.Data> plans) {
    for (final plan in plans) {
      if (_isPreferredTrialPlan(plan)) return plan;
    }

    for (final plan in plans) {
      if (plan.price == 2799) return plan;
    }

    return _sortedPlans(plans).first;
  }

  bool _isPreferredTrialPlan(plan_model.Data plan) {
    if (plan.price != 2799) return false;
    final duration = plan.duration ?? 0;
    final durationUnit = (plan.durationUnit ?? '').trim().toLowerCase();
    final isSixMonthPlan = duration == 6 &&
        (durationUnit.contains('month') || durationUnit.contains('mon'));
    if (!isSixMonthPlan) return false;

    final planText = [
      plan.name,
      plan.packageType,
      _plainText(plan.description),
    ].whereType<String>().join(' ').toLowerCase();
    final hasDiet = planText.contains('diet') || planText.contains('deit');
    final hasWorkout = planText.contains('workout') ||
        planText.contains('work out') ||
        planText.contains('work-out');
    return hasDiet && hasWorkout;
  }

  Future<void> _startTrialSetup() async {
    if (_shopVm.selectedPlan.value == null) {
      toast('Please select a subscription plan to continue.');
      return;
    }

    if (_subscriptionState == TrialSubscriptionState.trialActive ||
        _subscriptionState == TrialSubscriptionState.paidActive) {
      Get.offAll(() => DashboardScreen());
      return;
    }

    if (_isRazorpay) {
      await _createRazorpayTrialMandate();
      return;
    }

    await _startInAppPurchaseTrial();
  }

  Future<void> _createRazorpayTrialMandate() async {
    if (!Platform.isAndroid) {
      await _activateStaticTrialSubscription(paymentType: 'razorpay_autopay');
      toast('Trial unlocked.');
      setState(() {
        _subscriptionState = TrialSubscriptionState.trialActive;
      });
      return;
    }

    if (_isStartingAutopay) return;

    final plan = _shopVm.selectedPlan.value;
    final packageId = plan?.id ?? 0;
    if (plan == null || packageId == 0) {
      toast('Please select a subscription plan to continue.');
      return;
    }

    try {
      setState(() => _isStartingAutopay = true);

      final token = await _shopRepository.getToken();
      if (token == null || token.trim().isEmpty) {
        throw Exception('User not logged in');
      }

      final subscriptionData = await _shopVm.subscribePackage(
        packageId: packageId,
        paymentType: 'razorpay_autopay',
        trialAutopay: true,
        showErrors: false,
      );
      final subscriptionId =
          subscriptionData?.id ?? _shopVm.subscriptionId.value;
      if (subscriptionId == 0) {
        throw Exception('Subscription ID missing. Please try again.');
      }
      final razorpayPlanId =
          subscriptionData?.packageData?.razorpayPlanId?.trim().isNotEmpty ==
                  true
              ? subscriptionData!.packageData!.razorpayPlanId
              : plan.razorpayPlanId;

      var response = await _shopRepository.createAndroidAutopay(
        token: token,
        subscriptionId: subscriptionId,
        packageId: packageId,
        razorpayPlanId: razorpayPlanId,
        totalCount: _razorpayAutopayTotalCount,
      );
      var decoded = _decodeMapSafely(response.body);

      debugPrint(
        'Android AutoPay create response => ${response.statusCode} ${response.body}',
      );

      if (!_responseSuccess(response.statusCode, decoded)) {
        response = await _shopRepository.createAndroidAutopay(
          token: token,
          subscriptionId: subscriptionId,
          packageId: packageId,
          razorpayPlanId: razorpayPlanId,
          totalCount: _razorpayAutopayTotalCount,
          sendJson: false,
        );
        decoded = _decodeMapSafely(response.body);
        debugPrint(
          'Android AutoPay create form retry => ${response.statusCode} ${response.body}',
        );
      }

      if (!_responseSuccess(response.statusCode, decoded)) {
        final message = _messageFromResponse(
          decoded,
          fallback:
              'Unable to create AutoPay. Check Android package Product ID is a valid Razorpay Plan ID.',
        );
        throw Exception(
          message == 'Unable to create Razorpay autopay subscription.'
              ? 'Unable to create Razorpay autopay subscription. Check Android package Product ID is a valid Razorpay Plan ID and Razorpay subscriptions are enabled.'
              : message,
        );
      }

      final data = _payloadData(decoded);
      _pendingAutopayCreateData = {
        ...data,
        'local_subscription_id': subscriptionId,
      };

      final options = _buildRazorpayAutopayOptions(plan: plan, data: data);
      debugPrint('Opening Android AutoPay => $options');
      _razorpay.open(options);
    } catch (error) {
      debugPrint('Android AutoPay create failed: $error');
      Get.snackbar(
        'AutoPay Error',
        error.toString().replaceFirst('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (mounted) {
        setState(() => _isStartingAutopay = false);
      }
    }
  }

  Map<String, dynamic> _buildRazorpayAutopayOptions({
    required plan_model.Data plan,
    required Map<String, dynamic> data,
  }) {
    final key = _findString(data, const [
      'key',
      'key_id',
      'razorpay_key',
      'razorpay_key_id',
    ]).trim();
    final amount = _findInt(data, const ['amount', 'total_amount']);
    final currency = _findString(data, const ['currency']).trim();
    final orderId = _findString(data, const [
      'order_id',
      'razorpay_order_id',
    ]).trim();
    final subscriptionId = _findString(data, const [
      'subscription_id',
      'razorpay_subscription_id',
    ]).trim();
    final customerId = _findString(data, const [
      'customer_id',
      'razorpay_customer_id',
    ]).trim();

    return <String, dynamic>{
      'key': key.isNotEmpty ? key : _razorpayKeyId,
      if (amount != null && amount > 0) 'amount': amount,
      'currency': currency.isNotEmpty ? currency : 'INR',
      'name': 'CPT Fitness',
      'description': plan.name ?? 'AutoPay Subscription',
      if (orderId.isNotEmpty) 'order_id': orderId,
      if (subscriptionId.isNotEmpty) 'subscription_id': subscriptionId,
      if (customerId.isNotEmpty) 'customer_id': customerId,
      'recurring': true,
      'method': const {
        'upi': true,
        'card': true,
      },
      'config': const {
        'display': {
          'blocks': {
            'upi': {
              'name': 'UPI AutoPay',
              'instruments': [
                {'method': 'upi'},
              ],
            },
            'card': {
              'name': 'Card AutoPay',
              'instruments': [
                {'method': 'card'},
              ],
            },
          },
          'sequence': ['block.upi', 'block.card'],
          'preferences': {'show_default_blocks': true},
        },
      },
      'prefill': {
        'contact': userStore.phoneNo.trim().isNotEmpty
            ? userStore.phoneNo.trim()
            : '9999999999',
        'email': userStore.email.trim().isNotEmpty
            ? userStore.email.trim()
            : 'test@cptfitness.com',
      },
      'theme': {'color': '#E10600'},
    };
  }

  Future<void> _handleAutopaySuccess(PaymentSuccessResponse response) async {
    try {
      final plan = _shopVm.selectedPlan.value;
      final packageId = plan?.id ?? 0;
      if (plan == null || packageId == 0) {
        throw Exception('Selected plan missing.');
      }

      final token = await _shopRepository.getToken();
      if (token == null || token.trim().isEmpty) {
        throw Exception('User not logged in');
      }

      final backendSubscriptionId =
          _findString(_pendingAutopayCreateData, const [
        'local_subscription_id',
        'subscription_id',
      ]).trim();

      final razorpaySubscriptionId =
          _findString(_pendingAutopayCreateData, const [
        'razorpay_subscription_id',
        'subscription_id',
      ]).trim();
      final createdOrderId = _findString(_pendingAutopayCreateData, const [
        'order_id',
        'razorpay_order_id',
      ]).trim();
      final createdAutopayId = _findString(_pendingAutopayCreateData, const [
        'autopay_id',
        'id',
      ]).trim();

      final completeBody = <String, dynamic>{
        'package_id': packageId,
        'platform': 'android',
        'payment_type': 'razorpay_autopay',
        if (backendSubscriptionId.isNotEmpty)
          'subscription_id': backendSubscriptionId,
        if (response.paymentId?.trim().isNotEmpty == true)
          'razorpay_payment_id': response.paymentId!.trim(),
        if (response.orderId?.trim().isNotEmpty == true)
          'razorpay_order_id': response.orderId!.trim(),
        if (response.orderId?.trim().isNotEmpty != true &&
            createdOrderId.isNotEmpty)
          'razorpay_order_id': createdOrderId,
        if (response.signature?.trim().isNotEmpty == true)
          'razorpay_signature': response.signature!.trim(),
        if (razorpaySubscriptionId.isNotEmpty)
          'razorpay_subscription_id': razorpaySubscriptionId,
        if (createdAutopayId.isNotEmpty) 'autopay_id': createdAutopayId,
      };

      final completeResponse = await _shopRepository.completeAndroidAutopay(
        token: token,
        body: completeBody,
      );
      final decoded = _decodeMapSafely(completeResponse.body);

      if (!_responseSuccess(completeResponse.statusCode, decoded)) {
        throw Exception(
          _messageFromResponse(
            decoded,
            fallback: 'Unable to verify AutoPay payment.',
          ),
        );
      }

      await _activateStaticTrialSubscription(paymentType: 'razorpay_autopay');
      if (mounted && userStore.userId > 0) {
        try {
          await getUSerDetail(context, userStore.userId);
          LiveStream().emit(PAYMENT);
        } catch (e) {
          debugPrint('Subscription refresh after AutoPay failed: $e');
        }
      }
      if (!mounted) return;

      setState(() {
        _subscriptionState = TrialSubscriptionState.trialActive;
      });
      toast(_messageFromResponse(decoded, fallback: 'AutoPay activated.'));
      Get.offAll(() => DashboardScreen());
    } catch (error) {
      debugPrint('Android AutoPay complete failed: $error');
      if (mounted) {
        setState(() {
          _subscriptionState = TrialSubscriptionState.paymentFailed;
        });
      }
      Get.snackbar(
        'AutoPay Error',
        error.toString().replaceFirst('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _handleAutopayError(PaymentFailureResponse response) {
    debugPrint('Android AutoPay failed: ${response.code} ${response.message}');
    if (mounted) {
      setState(() {
        _subscriptionState = TrialSubscriptionState.paymentFailed;
      });
    }
    Get.snackbar(
      'AutoPay Failed',
      response.message ?? 'Payment was not completed.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _handleAutopayWallet(ExternalWalletResponse response) {
    debugPrint('Android AutoPay wallet selected: ${response.walletName}');
  }

  Map<String, dynamic> _decodeMapSafely(String raw) {
    if (raw.trim().isEmpty) return const <String, dynamic>{};
    try {
      return _shopRepository.toMap(raw);
    } catch (_) {
      return const <String, dynamic>{};
    }
  }

  Map<String, dynamic> _payloadData(Map<String, dynamic> decoded) {
    final data = decoded['data'];
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return data.cast<String, dynamic>();
    return decoded;
  }

  bool _responseSuccess(int statusCode, Map<String, dynamic> decoded) {
    var success = statusCode >= 200 && statusCode < 300;
    if (!decoded.containsKey('status')) return success;

    final status = decoded['status'];
    if (status is bool) return success && status;
    if (status is num) return success && status != 0;
    if (status is String) {
      final normalized = status.trim().toLowerCase();
      return success &&
          (normalized == 'true' ||
              normalized == '1' ||
              normalized == 'success');
    }
    return success;
  }

  String _messageFromResponse(
    Map<String, dynamic> decoded, {
    required String fallback,
  }) {
    final errors = decoded['errors'];
    if (errors is Map && errors.isNotEmpty) {
      final messages = <String>[];
      for (final entry in errors.entries) {
        final value = entry.value;
        if (value is List && value.isNotEmpty) {
          messages.add(value.first.toString());
        } else if (value != null) {
          messages.add(value.toString());
        }
      }
      if (messages.isNotEmpty) return messages.join('\n');
    }

    final nestedError = _findString(decoded, const [
      'description',
      'reason',
      'error_description',
      'error_message',
    ]).trim();
    if (nestedError.isNotEmpty) return nestedError;

    final raw = decoded['message']?.toString().trim() ?? '';
    return raw.isNotEmpty ? raw : fallback;
  }

  String _findString(Map<String, dynamic> source, List<String> keys) {
    final found = _findValue(source, keys);
    return found?.toString() ?? '';
  }

  int? _findInt(Map<String, dynamic> source, List<String> keys) {
    final found = _findValue(source, keys);
    if (found == null) return null;
    if (found is int) return found;
    if (found is num) return found.toInt();
    return int.tryParse(found.toString());
  }

  dynamic _findValue(dynamic source, List<String> keys) {
    if (source is! Map) return null;

    for (final key in keys) {
      if (source.containsKey(key) && source[key] != null) {
        return source[key];
      }
    }

    for (final value in source.values) {
      if (value is Map) {
        final nested = _findValue(value, keys);
        if (nested != null) return nested;
      }
    }

    return null;
  }

  Future<void> _startInAppPurchaseTrial() async {
    if (!Platform.isIOS || _isStartingAutopay) return;

    final plan = _shopVm.selectedPlan.value;
    final packageId = plan?.id ?? 0;
    if (plan == null || packageId == 0) {
      toast('Please select a subscription plan to continue.');
      return;
    }

    try {
      setState(() => _isStartingAutopay = true);

      final token = await _shopRepository.getToken();
      if (token == null || token.trim().isEmpty) {
        throw Exception('User not logged in');
      }

      final subscriptionData = await _shopVm.subscribePackage(
        packageId: packageId,
        paymentType: 'ios_iap',
        trialAutopay: true,
        showErrors: false,
      );
      final subscriptionId =
          subscriptionData?.id ?? _shopVm.subscriptionId.value;
      if (subscriptionId == 0) {
        throw Exception('Subscription ID missing. Please try again.');
      }

      final purchasePlan = _shopVm.selectedPlan.value ?? plan;
      final purchase = await _iosIapService.buySubscription(
        backendPrice: (purchasePlan.price ?? 0).toDouble(),
        packageType: purchasePlan.packageType,
        planName: purchasePlan.name,
        planDescription: purchasePlan.description,
        duration: purchasePlan.duration,
        durationUnit: purchasePlan.durationUnit,
        productIdsOverride: purchasePlan.iosProductIds,
        requireNativeStoreKit2: true,
      );

      final transactionDetail = _decodeMapSafely(purchase.transactionDetail);
      final productId = purchase.productId.trim().isNotEmpty
          ? purchase.productId.trim()
          : _findString(transactionDetail, const ['product_id']).trim();
      final transactionId = purchase.transactionId.trim().isNotEmpty
          ? purchase.transactionId.trim()
          : _findString(transactionDetail, const ['transaction_id']).trim();
      final originalTransactionId = _findString(
        transactionDetail,
        const ['original_transaction_id', 'originalTransactionId'],
      ).trim();
      final signedTransaction = _findString(
        transactionDetail,
        const [
          'signed_transaction',
          'signedTransaction',
          'jws_representation',
          'storekit_server_verification_data',
        ],
      ).trim();
      final receiptData = _findString(
        transactionDetail,
        const [
          'receipt_data',
          'app_store_receipt',
          'server_verification_data',
        ],
      ).trim();

      if (productId.isEmpty || transactionId.isEmpty) {
        throw Exception('App Store transaction details missing.');
      }
      if (signedTransaction.isEmpty && receiptData.isEmpty) {
        throw Exception('App Store verification data missing.');
      }

      final completeResponse = await _shopRepository.completeIosPayment(
        token: token,
        body: <String, dynamic>{
          'subscription_id': subscriptionId,
          'product_id': productId,
          'transaction_id': transactionId,
          'original_transaction_id': originalTransactionId.isNotEmpty
              ? originalTransactionId
              : transactionId,
          if (signedTransaction.isNotEmpty)
            'signed_transaction': signedTransaction
          else
            'receipt_data': receiptData,
        },
      );
      final decoded = _decodeMapSafely(completeResponse.body);
      if (!_responseSuccess(completeResponse.statusCode, decoded)) {
        throw Exception(
          _messageFromResponse(
            decoded,
            fallback: 'Unable to activate App Store subscription.',
          ),
        );
      }

      await _shopRepository.saveActiveIosPurchaseSyncState(
        subscriptionId: subscriptionId,
        productId: productId,
      );

      if (!mounted) return;
      await getUSerDetail(context, userStore.userId);
      LiveStream().emit(PAYMENT);

      if (!hasPremiumSubscriptionAccess(includeCachedAccess: false)) {
        throw Exception(
          'Subscription completed, but access is not active yet. Please try again.',
        );
      }

      setState(() {
        _subscriptionState = TrialSubscriptionState.trialActive;
      });
      toast(_messageFromResponse(
        decoded,
        fallback: 'Trial unlocked with App Store subscription.',
      ));
      Get.offAll(() => DashboardScreen());
    } catch (error) {
      debugPrint('iOS IAP trial failed: $error');
      if (_iosIapService.isUserCancelledError(error)) return;

      Get.snackbar(
        'App Store Error',
        _iosIapService.readableErrorMessage(
          error,
          fallback: error.toString().replaceFirst('Exception: ', ''),
        ),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (mounted) {
        setState(() => _isStartingAutopay = false);
      }
    }
  }

  Future<void> _activateStaticTrialSubscription({
    required String paymentType,
  }) async {
    final plan = _shopVm.selectedPlan.value;
    if (plan == null) return;

    final now = DateTime.now();
    final endDate = now.add(const Duration(days: 3));

    await userStore.setSubscribe(1);
    await setValue("HAS_SUBSCRIPTION", true);
    await userStore.setSubscriptionDetail(
      user_model.SubscriptionDetail(
        isSubscribe: 1,
        isTrialActive: 1,
        hasAccess: 1,
        subscriptionPlan: user_model.SubscriptionPlan(
          id: 999999,
          userId: userStore.userId,
          userName: userStore.displayName,
          packageId: plan.id,
          packageName: plan.name,
          totalAmount: plan.price,
          paymentType: paymentType,
          txnId: 'static_trial_${now.millisecondsSinceEpoch}',
          paymentStatus: 'trial',
          status: 'active',
          subscriptionStartDate: now.toIso8601String(),
          subscriptionEndDate: endDate.toIso8601String(),
          createdAt: now.toIso8601String(),
          updatedAt: now.toIso8601String(),
          packageData: user_model.PackageData(
            id: plan.id,
            name: plan.name,
            price: plan.price,
            status: plan.status,
            duration: plan.duration,
            packageType: plan.packageType,
            description: plan.description,
            durationUnit: plan.durationUnit,
          ),
        ),
      ),
    );

    LiveStream().emit(PAYMENT);

    if (Get.isRegistered<AccessGateController>()) {
      Get.find<AccessGateController>().grantAccess();
    }
  }
}

class _TrialHeroCard extends StatelessWidget {
  final TrialPaymentMethod paymentMethod;
  final String platformLabel;
  final bool isUnlocked;

  const _TrialHeroCard({
    required this.paymentMethod,
    required this.platformLabel,
    required this.isUnlocked,
  });

  @override
  Widget build(BuildContext context) {
    final setupLabel = paymentMethod == TrialPaymentMethod.razorpay
        ? 'Set up Razorpay AutoPay with UPI or card mandate. You will not be charged today.'
        : 'Start the App Store subscription trial. You will not be charged today.';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isUnlocked ? Icons.lock_open : Icons.lock_outline,
              color: primaryColor,
            ),
          ),
          12.width,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isUnlocked ? 'Trial Unlocked' : 'Unlock 3 Days Free',
                  style: boldTextStyle(size: 18),
                ),
                4.height,
                Text(
                  isUnlocked
                      ? 'AutoPay is set up. Dashboard, home, and premium videos can now be visible on $platformLabel.'
                      : setupLabel,
                  style: secondaryTextStyle(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AccessRuleCard extends StatelessWidget {
  final TrialSubscriptionState state;
  final TrialPaymentMethod paymentMethod;

  const _AccessRuleCard({
    required this.state,
    required this.paymentMethod,
  });

  @override
  Widget build(BuildContext context) {
    final isUnlocked = state == TrialSubscriptionState.trialActive ||
        state == TrialSubscriptionState.paidActive;
    final color = isUnlocked ? GreenColor : YellowColor;
    final paymentLabel = _paymentLabel(paymentMethod);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isUnlocked ? Icons.visibility : Icons.visibility_off,
            color: color,
            size: 22,
          ),
          10.width,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isUnlocked
                      ? 'Dashboard and videos unlocked'
                      : 'Dashboard and videos locked',
                  style: boldTextStyle(color: color, size: 14),
                ),
                4.height,
                Text(
                  isUnlocked
                      ? 'The 3-day trial is active because $paymentLabel setup has been verified.'
                      : 'Complete $paymentLabel setup to unlock the 3-day trial and enter the app.',
                  style: primaryTextStyle(size: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? trailing;

  const _SectionTitle({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: boldTextStyle(size: 16)).expand(),
        if (trailing != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: GreenColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              trailing!,
              style: boldTextStyle(color: GreenColor, size: 12),
            ),
          ),
      ],
    );
  }
}

class _PlansLoadingCard extends StatelessWidget {
  const _PlansLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          const SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          12.width,
          Expanded(
            child: Text(
              'Loading subscription plans...',
              style: primaryTextStyle(),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlansErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _PlansErrorCard({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message, style: primaryTextStyle()),
          12.height,
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final plan_model.Data plan;
  final bool selected;
  final VoidCallback onTap;

  const _PlanCard({
    required this.plan,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final description = _plainText(plan.description);
    final benefits = _benefitsForPlan(plan);

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? primaryColor : Theme.of(context).dividerColor,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: primaryColor,
                  size: 22,
                ),
                10.width,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan.name ?? 'Subscription Plan',
                        style: boldTextStyle(size: 17),
                      ),
                      if (description.isNotEmpty) ...[
                        4.height,
                        Text(
                          description,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: secondaryTextStyle(),
                        ),
                      ],
                    ],
                  ),
                ),
                10.width,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _priceLabelForPlan(plan),
                      style: boldTextStyle(color: primaryColor, size: 18),
                    ),
                    Text(
                      '/ ${_intervalLabelForPlan(plan)}',
                      style: secondaryTextStyle(),
                    ),
                  ],
                ),
              ],
            ),
            if (benefits.isNotEmpty) ...[
              12.height,
              ...benefits.map(
                (benefit) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle,
                          color: GreenColor, size: 17),
                      8.width,
                      Expanded(child: Text(benefit, style: primaryTextStyle())),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DisclosureCard extends StatelessWidget {
  final TrialPaymentMethod paymentMethod;
  final String price;
  final String interval;
  final DateTime trialEndsAt;

  const _DisclosureCard({
    required this.paymentMethod,
    required this.price,
    required this.interval,
    required this.trialEndsAt,
  });

  @override
  Widget build(BuildContext context) {
    final setupLabel = paymentMethod == TrialPaymentMethod.razorpay
        ? 'Razorpay AutoPay mandate'
        : 'App Store subscription';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: primaryColor.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: primaryColor, size: 22),
          10.width,
          Expanded(
            child: Text(
              'No charge today. Your 3-day free trial starts only after $setupLabel setup is verified. First billing is $price / $interval on ${_formatDate(trialEndsAt)} unless cancelled.',
              style: primaryTextStyle(size: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _SetupFlowCard extends StatelessWidget {
  final TrialPaymentMethod paymentMethod;

  const _SetupFlowCard({required this.paymentMethod});

  @override
  Widget build(BuildContext context) {
    final steps = paymentMethod == TrialPaymentMethod.razorpay
        ? const [
            'Create local trial subscription',
            'Create Razorpay subscription mandate',
            'User authorizes AutoPay mandate',
            'Verify mandate, unlock trial, then show dashboard',
          ]
        : const [
            'Load store subscription product',
            'User confirms subscription in store sheet',
            'Verify receipt with backend',
            'Unlock trial, then show dashboard',
          ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Setup flow', style: boldTextStyle(size: 16)),
          12.height,
          ...List.generate(
            steps.length,
            (index) => _FlowStep(
              number: index + 1,
              title: steps[index],
              isLast: index == steps.length - 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _FlowStep extends StatelessWidget {
  final int number;
  final String title;
  final bool isLast;

  const _FlowStep({
    required this.number,
    required this.title,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              height: 24,
              width: 24,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: primaryColor,
              ),
              child: Text(
                '$number',
                style: boldTextStyle(color: Colors.white, size: 12),
              ),
            ),
            if (!isLast)
              Container(
                height: 22,
                width: 1,
                color: Theme.of(context).dividerColor,
              ),
          ],
        ),
        10.width,
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 2, bottom: isLast ? 0 : 14),
            child: Text(title, style: primaryTextStyle()),
          ),
        ),
      ],
    );
  }
}

class _SubscriptionStatusCard extends StatelessWidget {
  final TrialSubscriptionState state;
  final TrialPaymentMethod paymentMethod;
  final DateTime trialEndsAt;

  const _SubscriptionStatusCard({
    required this.state,
    required this.paymentMethod,
    required this.trialEndsAt,
  });

  @override
  Widget build(BuildContext context) {
    final status = _statusData(state);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(status.icon, color: status.color, size: 24),
              10.width,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(status.title, style: boldTextStyle(size: 16)),
                    4.height,
                    Text(status.description, style: secondaryTextStyle()),
                  ],
                ),
              ),
            ],
          ),
          14.height,
          _StatusRow(
              label: 'Payment source', value: _paymentLabel(paymentMethod)),
          _StatusRow(label: 'Trial ends', value: _formatDate(trialEndsAt)),
          _StatusRow(label: 'Next billing', value: _formatDate(trialEndsAt)),
          12.height,
          Align(
            alignment: Alignment.centerLeft,
            child: _ReadOnlyStatusPill(
              label: status.title,
              color: status.color,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatusRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: secondaryTextStyle())),
          12.width,
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: boldTextStyle(size: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadOnlyStatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _ReadOnlyStatusPill({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Text(
        label,
        style: boldTextStyle(color: color, size: 12),
      ),
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  final TrialPaymentMethod paymentMethod;
  final TrialSubscriptionState state;
  final bool hasSelectedPlan;
  final bool isProcessing;
  final VoidCallback onPressed;

  const _PrimaryActionButton({
    required this.paymentMethod,
    required this.state,
    required this.hasSelectedPlan,
    required this.isProcessing,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isRazorpay = paymentMethod == TrialPaymentMethod.razorpay;
    final isUnlocked = state == TrialSubscriptionState.trialActive ||
        state == TrialSubscriptionState.paidActive;
    final label = isUnlocked
        ? 'Continue to Dashboard'
        : isProcessing
            ? 'Please wait...'
            : isRazorpay
                ? 'Set Up AutoPay & Start Trial'
                : Platform.isIOS
                    ? 'Start Free Trial with App Store'
                    : 'Start Free Trial';

    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 52),
        backgroundColor:
            hasSelectedPlan && !isProcessing ? primaryColor : Colors.grey,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      icon: isProcessing
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Icon(
              isUnlocked
                  ? Icons.arrow_forward
                  : isRazorpay
                      ? Icons.autorenew
                      : Icons.shopping_bag_outlined,
            ),
      label: Text(
        label,
        style: boldTextStyle(color: Colors.white),
      ),
      onPressed: hasSelectedPlan && !isProcessing ? onPressed : null,
    );
  }
}

class _StatusData {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const _StatusData({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}

_StatusData _statusData(TrialSubscriptionState state) {
  switch (state) {
    case TrialSubscriptionState.pendingAuthorization:
      return const _StatusData(
        title: 'Subscription setup required',
        description:
            'Free trial access is locked until subscription setup is verified.',
        icon: Icons.pending_actions,
        color: YellowColor,
      );
    case TrialSubscriptionState.trialActive:
      return const _StatusData(
        title: 'Trial active',
        description:
            'User has access until trial end. Payment is not paid yet.',
        icon: Icons.verified,
        color: GreenColor,
      );
    case TrialSubscriptionState.paidActive:
      return const _StatusData(
        title: 'Paid subscription active',
        description: 'First charge or renewal has been confirmed.',
        icon: Icons.check_circle,
        color: GreenColor,
      );
    case TrialSubscriptionState.paymentFailed:
      return const _StatusData(
        title: 'Payment failed',
        description:
            'Show retry or billing recovery after backend confirms it.',
        icon: Icons.error,
        color: RedColor,
      );
    case TrialSubscriptionState.cancelled:
      return const _StatusData(
        title: 'AutoPay cancelled',
        description: 'Access remains until trial or paid cycle end.',
        icon: Icons.cancel,
        color: RedColor,
      );
  }
}

String _paymentLabel(TrialPaymentMethod method) {
  switch (method) {
    case TrialPaymentMethod.razorpay:
      return 'Razorpay AutoPay';
    case TrialPaymentMethod.inAppPurchase:
      return 'App Store Subscription';
  }
}

String _priceLabelForPlan(plan_model.Data? plan) {
  if (plan == null) return 'selected plan';
  return '₹${plan.price ?? 0}';
}

String _intervalLabelForPlan(plan_model.Data? plan) {
  if (plan == null) return 'billing cycle';

  final duration = plan.duration ?? 0;
  final unit = (plan.durationUnit ?? '').trim().toLowerCase();
  if (duration <= 0 && unit.isEmpty) return 'billing cycle';

  final normalizedUnit = unit.isEmpty
      ? 'cycle'
      : unit.endsWith('ly')
          ? unit.substring(0, unit.length - 2)
          : unit;

  if (duration <= 1) return normalizedUnit;
  return '$duration ${normalizedUnit}s';
}

String _plainText(String? value) {
  final raw = value?.trim() ?? '';
  if (raw.isEmpty) return '';

  final parsed = html_parser.parse(raw).documentElement?.text ?? raw;
  return parsed
      .replaceAll('\u00A0', ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

List<String> _benefitsForPlan(plan_model.Data plan) {
  final benefits = <String>[];

  final packageType = (plan.packageType ?? '').trim();
  if (packageType.isNotEmpty) {
    benefits.add('${packageType.capitalizeFirst ?? packageType} plan access');
  }

  final durationLabel = _intervalLabelForPlan(plan);
  if (durationLabel != 'billing cycle') {
    benefits.add('Valid for $durationLabel after trial billing starts');
  }

  if ((plan.iosProductIds ?? const <String>[]).isNotEmpty && Platform.isIOS) {
    benefits.add('Linked with App Store subscription product');
  }

  return benefits;
}

String _formatDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  return '${date.day} ${months[date.month - 1]} ${date.year}';
}
