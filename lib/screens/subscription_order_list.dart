import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:lottie/lottie.dart';
import 'package:mighty_fitness/features/subscription_orders/viewmodels/subscription_orders_view_model.dart';
import '../models/subscription_List_model.dart';


const Color kAccentGreen = Color(0xFF4ADE80);
const Color kAccentBlue = Color(0xFF60A5FA);
const Color kAccentAmber = Color(0xFFFBBF24);


Color bg(BuildContext c) =>
    Theme.of(c).brightness == Brightness.dark
        ? const Color(0xFF0B0B0D)
        : Theme.of(c).colorScheme.surface;

Color cardBg(BuildContext c) =>
    Theme.of(c).brightness == Brightness.dark
        ? const Color(0xFF16161A)
        : Theme.of(c).colorScheme.surface;

Color textPrimary(BuildContext c) =>
    Theme.of(c).colorScheme.onSurface;

Color textSecondary(BuildContext c) =>
    Theme.of(c).colorScheme.onSurface.withOpacity(0.6);

Color borderColor(BuildContext c) =>
    Theme.of(c).brightness == Brightness.dark
        ? Colors.white.withOpacity(0.08)
        : Colors.black.withOpacity(0.08);

class SubscriptionOrderListScreen extends StatelessWidget {
  final SubscriptionOrdersViewModel vm =
      Get.put(SubscriptionOrdersViewModel());

  SubscriptionOrderListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(


      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: textPrimary(context)),
          onPressed: Get.back,
        ),
        title: Text(
          "My Subscriptions",
          style: GoogleFonts.montserrat(
            color: textPrimary(context),
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
      ),


      body: Obx(() {
        if (vm.isLoading.value) {
          return Center(
            child: CircularProgressIndicator(color: cs.primary),
          );
        }

    if (vm.orders.isEmpty) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      SizedBox(height: 190,),
      Center(
        child: Lottie.asset(
          'assets/Payment Failed.json',
          width: 220,
          height: 220,
          repeat: true,
        ),
      ),
      const SizedBox(height: 20),
      Text(
        "No Subscription Found",
        style: GoogleFonts.montserrat(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary(context),
        ),
      ),
      const SizedBox(height: 6),
      Text(
        "You haven't subscribed to any plan yet",
        style: GoogleFonts.poppins(
          fontSize: 13,
          color: textSecondary(context),
        ),
      ),
    ],
  );
}


        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: vm.orders.length,
          itemBuilder: (_, i) {
            final item = vm.orders[i];
            return FadeInUp(
              duration: Duration(milliseconds: 250 + (i * 90)),
              child: _SubscriptionCard(item: item),
            );
          },
        );
      }),
    );
  }
}


class _SubscriptionCard extends StatelessWidget {
  final Data item;

  const _SubscriptionCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: cardBg(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor(context)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// HEADER
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.packageName ?? "Subscription Plan",
                    style: GoogleFonts.montserrat(
                      color: textPrimary(context),
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _StatusBadge(status: item.paymentStatus ?? "pending"),
              ],
            ),

            const SizedBox(height: 12),

            /// DURATION
            _InfoChip(
              icon: Icons.calendar_month_rounded,
              text:
                  "${item.packageData?.duration ?? "-"} ${item.packageData?.durationUnit ?? ""}",
              color: kAccentBlue,
            ),

            const SizedBox(height: 16),

            /// PRICE
            Text(
              "₹ ${item.totalAmount ?? "0"}",
              style: GoogleFonts.montserrat(
                color: kAccentGreen,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            /// DATE RANGE
            _DateRow(label: "From", value: item.subscriptionStartDate ?? "-"),
            const SizedBox(height: 4),
            _DateRow(label: "To", value: item.subscriptionEndDate ?? "-"),
          ],
        ),
      ),
    );
  }
}

/// ===================================================================
/// 🔹 STATUS BADGE
/// ===================================================================
class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color c;
    switch (status) {
      case "paid":
        c = kAccentGreen;
        break;
      case "failed":
        c = Colors.redAccent;
        break;
      default:
        c = kAccentAmber;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: c.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.withOpacity(0.6)),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.montserrat(
          color: c,
          fontWeight: FontWeight.w700,
          fontSize: 12,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}


class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.montserrat(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}


class _DateRow extends StatelessWidget {
  final String label;
  final String value;

  const _DateRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          "$label:",
          style: GoogleFonts.poppins(
            color: textSecondary(context),
            fontSize: 12,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          value,
          style: GoogleFonts.poppins(
            color: textPrimary(context),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

