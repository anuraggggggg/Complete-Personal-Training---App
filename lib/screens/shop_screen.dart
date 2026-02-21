import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:lottie/lottie.dart';
import 'package:mighty_fitness/controllers/apply_coupon_controller/apply_coupon_contrller.dart';
import 'package:mighty_fitness/controllers/get_coupons_controller/get_coupons_controller.dart';
import 'package:mighty_fitness/controllers/payment_complete_controller/payment_complete_controller.dart';
import 'package:mighty_fitness/controllers/payment_complete_controller/subscription_subscribe_controller.dart';
import 'package:mighty_fitness/controllers/refrral_controller/referral_controller.dart';
import 'package:mighty_fitness/controllers/subscription_diet_plan_controller/subscription_diet_plan_controller.dart';
import 'package:mighty_fitness/extensions/loader_widget.dart';
import 'package:mighty_fitness/Chat/model/subscription_diet_plan_model.dart';
import 'package:mighty_fitness/models/get_coupons.dart';
import 'package:mighty_fitness/utils/app_colors.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:share_plus/share_plus.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});
  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  static const String _razorpayKeyId = "rzp_live_RsCjRLal1MjiQT";

  final SubscriptionPlanController subCtrl =
      Get.put(SubscriptionPlanController());
  final CouponController couponCtrl = Get.put(CouponController());
  final GetCouponsController getCouponsCtrl = Get.put(GetCouponsController());
  final ReferralController referralCtrl = Get.put(ReferralController());

  final TextEditingController _couponTextCtrl = TextEditingController();

  final SubscriptionSubscribeController subscribeCtrl =
      Get.put(SubscriptionSubscribeController());

  final PaymentCompleteController paymentCtrl =
      Get.put(PaymentCompleteController());
  late Razorpay _razorpay;
  Function(PaymentSuccessResponse response)? _successCallback;

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

  @override
  void initState() {
    super.initState();

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

    // Load latest referral/coupon state when Shop opens.
    unawaited(referralCtrl.refreshReferral());
    unawaited(getCouponsCtrl.fetchCoupons());
  }

  @override
  void dispose() {
    _couponTextCtrl.dispose();
    _razorpay.clear(); // 🔥 VERY IMPORTANT
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          // 🔥 iOS BACK ICON
          title: Text(
            "Subscription Plans",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: cs.onSurface,
            ),
          ),
        ),
        body: Obx(() {
          if (subCtrl.isLoading.value) {
            return Center(child: Loader());
          }

          final plans = subCtrl.plans;
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

              _referralSection(), 

              _myCouponsSection(), 
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
              _applyCouponSection(), 
            ],
          );
        }));
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
      final hasCode = referralCtrl.referralCode.trim().isNotEmpty;

      if (referralCtrl.isLoading.value && !hasCode) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Center(
            child: CircularProgressIndicator(
              color: cs.primary,
            ),
          ),
        );
      }

      if (!referralCtrl.isReferralActive && !hasCode) {
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
                    onPressed: referralCtrl.isLoading.value
                        ? null
                        : () async {
                            await referralCtrl.refreshReferral();
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
                        referralCtrl.referralCode,
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
                            text: referralCtrl.referralCode,
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
                          "Use my referral code: ${referralCtrl.referralCode}\n"
                          "Get exclusive rewards 💪✨",
                        );
                      },
                    ),
                  ],
                ),
              ),

              /// 💰 CREDIT INFO
              if (referralCtrl.hasReferralCredit) ...[
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
                      "Available Credit: ₹${referralCtrl.referralCredit}",
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
      /// ❌ If coupons should not be visible
      if (!getCouponsCtrl.canShowCoupons) {
        return const SizedBox.shrink();
      }

      /// ⏳ Loading
      if (getCouponsCtrl.isLoading.value) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Center(
            child: CircularProgressIndicator(color: cs.primary),
          ),
        );
      }

      final coupons = getCouponsCtrl.activeCoupons;

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
                  final isLoading = couponCtrl.isApplying.value;

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

                            couponCtrl.applyCoupon(code: code);
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

    return FadeInUp(
      duration: const Duration(milliseconds: 350),
      child: GestureDetector(
        onTap: isFree ? null : () => _openPaymentSheet(planData),
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
                      isFree ? "FREE" : "₹${price ?? 0}",
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
  void _openPaymentSheet(Data planData) {
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
                title: "Pay with Razorpay",
                subtitle: "Secure online payment",
                icon: Icons.credit_card,
                onTap: () async {
                  if (subscribeCtrl.isLoading.value ||
                      paymentCtrl.isSubmitting.value) {
                    return;
                  }

                  Navigator.pop(context);

                  /// 🔥 1️⃣ PLAN ALREADY SELECTED
                  final selectedPackageId = subCtrl.selectedPackageId;

                  if (selectedPackageId == 0) {
                    Get.snackbar(
                      "Error",
                      "No plan selected",
                      snackPosition: SnackPosition.BOTTOM,
                    );
                    return;
                  }

                  /// 🔥 2️⃣ CALL SUBSCRIBE PACKAGE API
                  await subscribeCtrl.subscribePackage(
                    packageId: selectedPackageId,
                  );

                  final subscriptionId = subscribeCtrl.subscriptionId.value;

                  if (subscriptionId == 0) {
                    Get.snackbar(
                      "Error",
                      "Subscription creation failed",
                      snackPosition: SnackPosition.BOTTOM,
                    );
                    return;
                  }

                  /// 🔥 3️⃣ OPEN RAZORPAY
                  _openRazorpay(
                    amount: planData.price ?? 0,
                    onSuccess: (razorpayResponse) async {
                      /// 🔥 4️⃣ PAYMENT COMPLETE API
                      final isPaymentDone = await paymentCtrl.completePayment(
                        razorpayPaymentId: razorpayResponse.paymentId ?? "",
                        subscriptionId: subscriptionId,
                      );

                      if (isPaymentDone) {
                        // Update sections immediately after successful payment.
                        getCouponsCtrl.subscriptionId.value = subscriptionId;
                        await Future.wait([
                          getCouponsCtrl.fetchCoupons(),
                          referralCtrl.refreshReferral(),
                        ]);
                      }
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _openRazorpay({
    required int amount,
    required Function(PaymentSuccessResponse response) onSuccess,
  }) {
    _successCallback = onSuccess;
    if (_razorpayKeyId.startsWith('rzp_test_')) {
      debugPrint("Razorpay is running in TEST mode. Real bank debit will not happen.");
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
      'prefill': {
        'contact': '9999999999',
        'email': 'test@cptfitness.com',
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
                          "₹${plan.price ?? 0}",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: cs.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => _openPaymentSheet(plan),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: cs.primary,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            "Choose",
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
              final isFree = (plan.price ?? 0) == 0;
              final offerDescription = _toPlainText(plan.description);

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
                            isFree ? "FREE" : "₹${plan.price}",
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
                      onPressed: isFree
                          ? null
                          : () {
                              subCtrl.selectPlan(plan); // 🔥 ADDED
                              _openPaymentSheet(plan);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isFree ? Colors.green : cs.primary,
                        disabledBackgroundColor: Colors.green.withOpacity(0.6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        isFree ? "FREE" : "PAY",
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
                        "₹${planData.price ?? 0}",
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
                  onPressed: () {
                    subCtrl.selectPlan(planData); // 🔥 ADDED
                    _openPaymentSheet(planData);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 6,
                  ),
                  child: Text(
                    "PAY",
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
