import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:mighty_fitness/controllers/apply_coupon_controller/apply_coupon_contrller.dart';

class CouponDialog extends StatelessWidget {
  CouponDialog({super.key});

  final TextEditingController ctrl = TextEditingController();
  final CouponController couponCtrl = Get.put(CouponController());

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black.withOpacity(0.65)
                  : Colors.white.withOpacity(0.88),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Colors.white.withOpacity(0.15),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                /// 🍎 LOTTIE (CYBER SECURITY)
                SizedBox(
                  height: 90,
                  width: 90,
                  child: Lottie.asset(
                    'assets/Cyber Security.json',
                    repeat: true,
                    fit: BoxFit.contain,
                  ),
                ),

                const SizedBox(height: 12),

                /// 🍎 TITLE
                Text(
  "SECURE ACCESS MODE",
  textAlign: TextAlign.center,
  style: GoogleFonts.orbitron(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.4,
    color: Colors.white,
    shadows: [
      Shadow(
        color: cs.primary.withOpacity(0.6),
        blurRadius: 10,
      ),
    ],
  ),
),


                const SizedBox(height: 8),

                /// 🍎 MESSAGE (API CONTENT)
                Text(
                  "Please subscribe or apply an active coupon to unlock and watch all workout videos.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    height: 1.5,
                    color: cs.onSurface.withOpacity(0.75),
                  ),
                ),

                const SizedBox(height: 18),

                /// 🍎 COUPON INPUT
                Container(
                  decoration: BoxDecoration(
                    color: cs.surface.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: cs.onSurface.withOpacity(0.12),
                    ),
                  ),
                  child: TextField(
  controller: ctrl,
  textCapitalization: TextCapitalization.characters,

  /// 🔥 USER INPUT TEXT COLOR (WHITE)
  style: GoogleFonts.inter(
    fontWeight: FontWeight.w600,
    letterSpacing: 1.2,
    color: Colors.white,
  ),

  decoration: InputDecoration(
    hintText: "ENTER COUPON CODE",
    hintStyle: GoogleFonts.inter(
      fontSize: 12,
      letterSpacing: 1,
      color: Colors.white.withOpacity(0.45),
    ),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 14,
    ),
    border: InputBorder.none,
  ),
),

                ),

                const SizedBox(height: 20),

                /// 🍎 APPLY BUTTON
                Obx(() {
                  return SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cs.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                     onPressed: couponCtrl.isApplying.value
    ? null
    : () {
        final code = ctrl.text.trim();
        if (code.isEmpty) return;
        couponCtrl.applyCoupon(code: code);
      },


                      child: couponCtrl.isApplying.value
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              "Apply Coupon",
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  );
                }),

                const SizedBox(height: 10),

                /// 🍎 SKIP
                GestureDetector(
                  onTap: () => Get.back(),
                  child: Text(
                    "Maybe later",
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurface.withOpacity(0.6),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
