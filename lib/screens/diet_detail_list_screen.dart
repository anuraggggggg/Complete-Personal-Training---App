import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mighty_fitness/models/diet_models.dart';


class DietDetailsListScreen extends StatelessWidget {
  final Data diet;
  const DietDetailsListScreen({super.key, required this.diet});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
   

      // ================= APP BAR =================
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: cs.onSurface, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Diet Details",
          style: GoogleFonts.montserrat(
            color: cs.onSurface,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),

      // ================= BODY =================
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // =====================================================
            // 🟢 HEADER CARD
            // =====================================================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: isDark
                      ? [
                          cs.primary.withOpacity(0.20),
                          cs.surface,
                        ]
                      : [
                          cs.primary.withOpacity(0.08),
                          cs.surface,
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: cs.primary.withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    diet.title ?? "",
                    style: GoogleFonts.montserrat(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Category badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: cs.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.local_fire_department,
                            size: 16, color: cs.primary),
                        const SizedBox(width: 6),
                        Text(
                          diet.categorydietTitle ?? "Diet",
                          style: GoogleFonts.montserrat(
                            color: cs.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(duration: 400.ms)
                .slideY(begin: 0.2),

            const SizedBox(height: 22),

            // =====================================================
            // 🧂 INGREDIENTS CARD
            // =====================================================
            _SectionCard(
              title: "Ingredients",
              icon: Icons.shopping_basket_outlined,
              child: Html(
                data: diet.ingredients ?? "No ingredients available",
                style: {
                  "body": Style(
                    fontFamily: GoogleFonts.outfit().fontFamily,
                    color: cs.onSurface.withOpacity(0.8),
                    fontSize: FontSize(15),
                    lineHeight: LineHeight(1.6),
                    margin: EdgeInsets.zero,
                    padding: EdgeInsets.zero,
                  ),
                  "li": Style(
                    padding: const EdgeInsets.only(bottom: 8),
                  ),
                },
              ),
            ),
            const SizedBox(height: 18),
            // =====================================================
            // 📋 DESCRIPTION CARD
            // =====================================================
            _SectionCard(
              title: "Description",
              icon: Icons.menu_book_outlined,
              child: Html(
                data: diet.description ?? "No description available",
                style: {
                  "body": Style(
                    fontFamily: GoogleFonts.outfit().fontFamily,
                    color: cs.onSurface.withOpacity(0.8),
                    fontSize: FontSize(15),
                    lineHeight: LineHeight(1.7),
                    margin: EdgeInsets.zero,
                    padding: EdgeInsets.zero,
                  ),
                  "li": Style(
                    padding: const EdgeInsets.only(bottom: 8),
                  ),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================
// 🔥 REUSABLE SECTION CARD (DRIBBBLE STYLE)
// =====================================================
class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: cs.onSurface.withOpacity(0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                height: 36,
                width: 36,
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: cs.primary, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: GoogleFonts.montserrat(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          child,
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms)
        .slideY(begin: 0.15);
  }
}
