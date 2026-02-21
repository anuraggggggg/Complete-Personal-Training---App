import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:mighty_fitness/controllers/category_diet_controller/category_diet_controller.dart';
import 'package:mighty_fitness/controllers/diet_controllers/diet_controllers.dart';
import 'package:mighty_fitness/controllers/language_controller/language_controller.dart';
import 'package:mighty_fitness/controllers/translator_controller/translator_controller.dart';
import 'package:mighty_fitness/extensions/loader_widget.dart';
import 'package:mighty_fitness/screens/diet_detail_list_screen.dart';
import 'package:mighty_fitness/screens/shop_screen.dart';
import 'package:mighty_fitness/screens/t_text.dart';
import '../models/category_diet_model.dart';

class DietFilterScreen extends StatefulWidget {
  const DietFilterScreen({Key? key}) : super(key: key);

  @override
  State<DietFilterScreen> createState() => _DietFilterScreenState();
}

class _DietFilterScreenState extends State<DietFilterScreen>
    with SingleTickerProviderStateMixin {
  final LanguageController langC = Get.put(LanguageController());
  final DietListController controller = Get.put(DietListController());
  final CategoryDietController categoryC =
    Get.put(CategoryDietController());

  final TranslatorController trC = Get.find<TranslatorController>();

  // ================= USER SELECTION =================
  String selectedVariety = '';
  Data? selectedCategory; // CategoryDietModel ka Data

  String selectedGender = '';
  int selectedLanguageId = 1;
  OverlayEntry? _langTooltip;
final GlobalKey _langBtnKey = GlobalKey();


  // ================= OPTIONS =================
  final varieties = ['veg', 'nonveg'];
  final categories = ['Muscle Building', 'Fat Loss'];


  late Worker _dietWorker;

  late PageController _pageController;
  late AnimationController _anim;

  Color get accent => const Color(0xFFAF001C);

  bool get isDark => Theme.of(context).brightness == Brightness.dark;

Color get bgColor =>
    Theme.of(context).colorScheme.surface;

Color get surface =>
    Theme.of(context).colorScheme.surface;

Color get onSurface =>
    Theme.of(context).colorScheme.onSurface;

Color get onSurfaceSoft =>
    Theme.of(context).colorScheme.onSurface.withOpacity(0.7);




  // ================= HELPERS =================
  int _mapCategoryToId(String c) {
    switch (c) {
      case "Muscle Building":
        return 5;
      case "Fat Loss":
        return 4;
      default:
        return 0;
    }
  }

  void _showLanguageTooltip() {
  if (_langTooltip != null) return;

  final renderBox =
      _langBtnKey.currentContext?.findRenderObject() as RenderBox?;
  if (renderBox == null) return;

  final offset = renderBox.localToGlobal(Offset.zero);
  final size = renderBox.size;

  _langTooltip = OverlayEntry(
  builder: (context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Tooltip width (approx)
    const tooltipWidth = 260.0;

    // Button center X
    double left =
        offset.dx + (size.width / 2) - (tooltipWidth / 2);

    // 🛑 Clamp so it never goes out of screen
    left = left.clamp(12.0, screenWidth - tooltipWidth - 12.0);

    return Positioned(
      top: offset.dy + size.height + 10,
      left: left,
      child: Material(
        color: Colors.transparent,
        child: AnimatedOpacity(
          opacity: 1,
          duration: const Duration(milliseconds: 250),
          child: Container(
            width: tooltipWidth,
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.88),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Text(
              "🌍 Change the screen language from here",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  },
);


  Overlay.of(context).insert(_langTooltip!);

  /// ⏱️ AUTO HIDE AFTER 10 SECONDS
  Future.delayed(const Duration(seconds: 10), () {
    _langTooltip?.remove();
    _langTooltip = null;
  });
}


@override
void initState() {
  super.initState();

  // ✅ REQUIRED INITIALIZATIONS
  _pageController = PageController();
  _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );

  // ❗ Worker optional hai, but agar variable rakha hai
  _dietWorker = ever<List>(
    controller.dietList,
    (_) => _safeAnimate(),
  );

  // ✅ language default (OLD behaviour)
  selectedLanguageId = langC.selectedLangId.value;
}




 void _safeAnimate() {
  if (!mounted) return;
  if (_anim.isAnimating) return;

  _anim.forward(from: 0);
}


@override
void dispose() {
  _dietWorker.dispose();
  _pageController.dispose();
  _anim.dispose();
  super.dispose();
}



  // ================= API =================
void _fetchDiet() {
  if (selectedCategory == null) return;

  debugPrint("🥗 CATEGORY SELECTED");
  debugPrint("Title : ${selectedCategory!.title}");
  debugPrint("ID    : ${selectedCategory!.id}");

  controller.fetchDietList(
    variety: selectedVariety,
    categoryId: selectedCategory!.id!, // 🔥 DIRECT FROM MODEL
    languageId: selectedLanguageId,
    gender: selectedGender,
  );
}




  // ================= UI CORE =================
  Widget _glassCard({required Widget child}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 22),
    padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(26),
      color: surface.withOpacity(isDark ? 0.35 : 0.9),
      border: Border.all(
        color: onSurface.withOpacity(isDark ? 0.08 : 0.12),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(isDark ? 0.45 : 0.12),
          blurRadius: 24,
          offset: const Offset(0, 14),
        ),
      ],
    ),
    child: child,
  );
}


 Widget _sectionHeader(String title, String subtitle) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      TText(
        title,
        style: GoogleFonts.montserrat(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: onSurface,
        ),
      ),
      const SizedBox(height: 4),
      TText(
        subtitle,
        style: GoogleFonts.montserrat(
          fontSize: 13,
          color: onSurfaceSoft,
        ),
      ),
    ],
  );
}


 Widget _pill({
  required String label,
  required bool active,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: () {
      HapticFeedback.selectionClick();
      onTap();
    },
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      height: 46,
      width: double.infinity,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: active
            ? accent
            : surface.withOpacity(isDark ? 0.45 : 1),
        border: Border.all(
          color: active
              ? accent
              : onSurface.withOpacity(0.12),
        ),
      ),
      child: TText(
        label,
        style: GoogleFonts.montserrat(
          color: active ? Colors.white : onSurfaceSoft,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
    ),
  );
}


  // ================= STEP 1 =================
  Widget _stepVariety() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _glassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionHeader(
                "Choose Diet Type",
                "Select your food preference",
              ),
              const SizedBox(height: 16),
              Row(
                children: varieties.map((v) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: _pill(
                        label: v,
                        active: selectedVariety == v,
                        onTap: () => setState(() => selectedVariety = v),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        _nextButton(
          enabled: selectedVariety.isNotEmpty,
          label: "Continue",
          onTap: () => _pageController.nextPage(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOut,
          ),
        ),
      ],
    );
  }

  // ================= STEP 2 =================
  Widget _stepGoal() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _glassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionHeader(
                  "Fitness Goal",
                  "Choose your transformation plan",
                ),
                const SizedBox(height: 14),
               Obx(() {
  if (categoryC.isLoading.value) {
    return const Center(child: CircularProgressIndicator());
  }

  return Column(
    children: categoryC.categoryDietList.map((cat) {
      final isActive = selectedCategory?.id == cat.id;

      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _pill(
          label: cat.title ?? "",
          active: isActive,
          onTap: () {
            setState(() {
              selectedCategory = cat;
            });
          },
        ),
      );
    }).toList(),
  );
})

              ],
            ),
          ),

          _glassCard(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _sectionHeader(
        trC.tr("Gender"),
        trC.tr("Personalized diet plans"),
      ),
      const SizedBox(height: 14),
      Row(
        children: [
          Expanded(
            child: _pill(
              label: trC.tr("Male"),
              active: selectedGender == "male",
              onTap: () => setState(() => selectedGender = "male"),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _pill(
              label: trC.tr("Female"),
              active: selectedGender == "female",
              onTap: () => setState(() => selectedGender = "female"),
            ),
          ),
        ],
      ),
    ],
  ),
),


       _glassCard(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _sectionHeader(
        trC.tr("Language"),
        trC.tr("Choose a language to read your diet plan"),
      ),
      const SizedBox(height: 14),

      Obx(() {
        if (langC.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: langC.activeLanguages.map((lang) {
            final isActive =
                selectedLanguageId == lang.id;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _pill(
                label: lang.languageName ?? "",
                active: isActive,
                onTap: () {
                  // ✅ ONLY local selection
                  setState(() {
                    selectedLanguageId = lang.id ?? 0;
                  });
                },
              ),
            );
          }).toList(),
        );
      }),
    ],
  ),
),




         _nextButton(
  enabled: selectedCategory != null &&
    selectedGender.isNotEmpty &&
    selectedLanguageId != 0,

  label: "View Diet Plans",
  onTap: () {
    _fetchDiet(); // 🔥 yahin API hit
    _pageController.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
    );
  },
),

          SizedBox(height: 20,),
        ],
      ),
    );
  }

  // ================= STEP 3 =================
  Widget _stepDietList() {
  return Obx(() {

    /// 🔄 LOADING
   if (controller.isSubscriptionRequired.value) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 140,
            height: 140,
            child: Lottie.asset(
              'assets/Payment Failed.json', 
              repeat: true,
              animate: true,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            controller.subscriptionMessage.value,
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: onSurface.withOpacity(0.8),
            ),
          ),

          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: () {
              Get.to(() => ShopScreen());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: accent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              "Subscribe Now",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    ),
  );
}

    /// ❌ SERVER ERROR
    if (controller.isError.value) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 60,
              color: accent,
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Text(
                controller.errorMessage.value,
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: onSurfaceSoft,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _fetchDiet,
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text("Retry"),
            ),
          ],
        ),
      );
    }

    /// 📭 EMPTY STATE
    if (controller.dietList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_menu_rounded,
              size: 60,
              color: onSurfaceSoft,
            ),
            const SizedBox(height: 12),
            Text(
              "No Diets Available",
              style: GoogleFonts.montserrat(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: onSurfaceSoft,
              ),
            ),
          ],
        ),
      );
    }

    /// ✅ SUCCESS LIST
    return FadeTransition(
      opacity: _anim,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: controller.dietList.length,
        itemBuilder: (_, i) {
          final diet = controller.dietList[i];

          return GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Get.to(() => DietDetailsListScreen(diet: diet));
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(
                        isDark ? 0.35 : 0.1),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  TText(
                    diet.title ?? '',
                    style: GoogleFonts.montserrat(
                      color: onSurface,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TText(
                    diet.categorydietTitle ?? '',
                    style: GoogleFonts.montserrat(
                      color: onSurfaceSoft,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  });
}


Widget _nextButton({
  required bool enabled,
  required String label,
  required VoidCallback onTap,
}) {
  return SizedBox(
    width: double.infinity,
    height: 52,
    child: ElevatedButton(
      onPressed: enabled ? onTap : null,
      style: ElevatedButton.styleFrom(
        elevation: enabled ? 2 : 0,
        backgroundColor: accent,
        disabledBackgroundColor: accent.withOpacity(0.35),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10), // 🔥 square + rounded
        ),
      ),
      child: TText(
        label,
        style: GoogleFonts.montserrat(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
    ),
  );
}


  // ================= BUILD =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
       appBar: AppBar(
  elevation: 0,
  backgroundColor: Colors.transparent,
  centerTitle: false,
  titleSpacing: 16,

  /// 🍽️ TITLE
  title: Row(
    children: [
      const Text(
        "🥗",
        style: TextStyle(fontSize: 22),
      ),
      const SizedBox(width: 8),
      TText(
        "Diet Plans",
        style: GoogleFonts.montserrat(
          color: Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.w800,
          fontSize: 18,
        ),
      ),
    ],
  ),

  /// 🌍 LANGUAGE SWITCH BUTTON
  actions: [
    GestureDetector(
        // key: _langBtnKey,
      onTap: _openLanguageSelector,
      child: Container(
        margin: const EdgeInsets.only(right: 14),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withOpacity(0.12),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(
                Theme.of(context).brightness == Brightness.dark
                    ? 0.35
                    : 0.08,
              ),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.translate_rounded,
              size: 16,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            const SizedBox(width: 6),

            /// LANGUAGE CODE (EN / HI / AR)
            Obx(() {
              final lang =
                  Get.find<TranslatorController>().currentLang.value;
              return Text(
                lang.toUpperCase(),
                style: GoogleFonts.montserrat(
                  color:
                      Theme.of(context).colorScheme.onSurface,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              );
            }),
          ],
        ),
      ),
    ),
  ],
),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _stepVariety(),
            _stepGoal(),
            _stepDietList(),
          ],
        ),
      ),
    );
  }

  void _openLanguageSelector() {
  final t = Get.find<TranslatorController>();
  final theme = Theme.of(Get.context!);
  final isDark = theme.brightness == Brightness.dark;

  // 🔁 THEME FLIP
  final sheetBg = isDark ? Colors.white : const Color(0xFF121212);
  final textColor = isDark ? Colors.black87 : Colors.white;
  final subTextColor = isDark ? Colors.black54 : Colors.white70;
  final tileBg =
      isDark ? Colors.grey.shade100 : const Color(0xFF1E1E1E);
  final borderColor =
      isDark ? Colors.grey.shade300 : Colors.white12;

  Get.bottomSheet(
    SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
        decoration: BoxDecoration(
          color: sheetBg,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(28),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 18,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /// ── Drag Handle ──
            Container(
              height: 4,
              width: 42,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.grey.shade400
                    : Colors.grey.shade700,
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            /// ── Title ──
            Text(
              "Select Language",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              "Choose your preferred language",
              style: theme.textTheme.bodySmall?.copyWith(
                color: subTextColor,
              ),
            ),

            const SizedBox(height: 18),

            /// ── Language List ──
            ...t.languages.map((lang) {
              final bool isSelected =
                  t.currentLang.value == lang.code;

              return GestureDetector(
                onTap: () {
                  t.changeLanguage(lang.code);
                  Get.back();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.red.withOpacity(
                            isDark ? 0.12 : 0.18,
                          )
                        : tileBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color:
                          isSelected ? Colors.redAccent : borderColor,
                      width: 1.2,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color:
                                  Colors.red.withOpacity(0.2),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ]
                        : [],
                  ),
                  child: Row(
                    children: [
                      /// 🌍 ICON
                      Container(
                        height: 38,
                        width: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? Colors.red.withOpacity(0.2)
                              : isDark
                                  ? Colors.grey.shade200
                                  : Colors.grey.shade800,
                        ),
                        child: Icon(
                          Icons.translate_rounded,
                          size: 20,
                          color: isSelected
                              ? Colors.redAccent
                              : textColor.withOpacity(0.7),
                        ),
                      ),

                      const SizedBox(width: 14),

                      /// 🌐 LANGUAGE NAME
                      Expanded(
                        child: Text(
                          lang.name,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w600,
                            color: isSelected
                                ? Colors.redAccent
                                : textColor,
                          ),
                        ),
                      ),

                      /// ✅ CHECK
                      AnimatedSwitcher(
                        duration:
                            const Duration(milliseconds: 180),
                        child: isSelected
                            ? const Icon(
                                Icons.check_circle,
                                key: ValueKey(true),
                                color: Colors.redAccent,
                                size: 22,
                              )
                            : const SizedBox(
                                key: ValueKey(false),
                                width: 22,
                              ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    ),
    isScrollControlled: true,
  );
}
}
