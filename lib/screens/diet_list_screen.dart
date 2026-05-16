import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:mighty_fitness/controllers/translator_controller/translator_controller.dart';
import 'package:mighty_fitness/features/diet_filter/viewmodels/diet_filter_view_model.dart';
import 'package:mighty_fitness/screens/diet_detail_list_screen.dart';
import 'package:mighty_fitness/screens/shop_screen.dart';
import 'package:mighty_fitness/screens/t_text.dart';
import 'package:mighty_fitness/utils/app_common.dart';
import 'package:mighty_fitness/utils/medical_references.dart';
import '../models/category_diet_model.dart' as category_model;

class DietFilterScreen extends StatefulWidget {
  const DietFilterScreen({Key? key}) : super(key: key);

  @override
  State<DietFilterScreen> createState() => _DietFilterScreenState();
}

class _DietFilterScreenState extends State<DietFilterScreen>
    with SingleTickerProviderStateMixin {
  final DietFilterViewModel vm = Get.put(DietFilterViewModel());

  final TranslatorController trC = Get.find<TranslatorController>();

  // ================= USER SELECTION =================
  String selectedVariety = '';
  category_model.Data? selectedCategory; // CategoryDietModel ka Data

  String selectedGender = '';
  int selectedLanguageId = 1;

  // ================= OPTIONS =================
  final varieties = ['veg', 'nonveg'];
  final categories = ['Muscle Building', 'Fat Loss'];

  late Worker _dietWorker;

  late PageController _pageController;
  late AnimationController _anim;

  Color get accent => const Color(0xFFAF001C);

  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  Color get bgColor => Theme.of(context).colorScheme.surface;

  Color get surface => Theme.of(context).colorScheme.surface;

  Color get onSurface => Theme.of(context).colorScheme.onSurface;

  Color get onSurfaceSoft =>
      Theme.of(context).colorScheme.onSurface.withOpacity(0.7);

  // ================= HELPERS =================
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
      vm.dietList,
      (_) => _safeAnimate(),
    );

    // ✅ language default (OLD behaviour)
    selectedLanguageId = vm.selectedLanguageId.value;
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

    vm.fetchDietList(
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

  Widget _dietMedicalSourcesCard() {
    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            "Medical disclaimer & sources",
            "Review the evidence links used for diet and supplement guidance",
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: accent.withOpacity(isDark ? 0.16 : 0.08),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: accent.withOpacity(0.20),
              ),
            ),
            child: Text(
              dietMedicalDisclaimer,
              style: GoogleFonts.montserrat(
                fontSize: 12.5,
                height: 1.5,
                color: onSurfaceSoft,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 14),
          ...dietMedicalReferenceLinks.map(
            (link) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () async {
                  await launchUrls(link.url);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: surface.withOpacity(isDark ? 0.45 : 1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: onSurface.withOpacity(0.10),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        height: 38,
                        width: 38,
                        decoration: BoxDecoration(
                          color: accent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.open_in_new_rounded,
                          size: 18,
                          color: accent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              link.title,
                              style: GoogleFonts.montserrat(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              link.subtitle,
                              style: GoogleFonts.montserrat(
                                fontSize: 11.5,
                                height: 1.4,
                                color: onSurfaceSoft,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openMedicalSourcesSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: _dietMedicalSourcesCard(),
          ),
        );
      },
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
          color: active ? accent : surface.withOpacity(isDark ? 0.45 : 1),
          border: Border.all(
            color: active ? accent : onSurface.withOpacity(0.12),
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
                  if (vm.isCategoryLoading.value) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return Column(
                    children: vm.categoryDietList.map((cat) {
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
                  if (vm.isLanguageLoading.value) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return Column(
                    children: vm.activeLanguages.map((lang) {
                      final isActive = selectedLanguageId == lang.id;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _pill(
                          label: (lang.languageName ?? "").split(' ').first,
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
          _dietMedicalSourcesCard(),
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
          SizedBox(
            height: 20,
          ),
        ],
      ),
    );
  }

  // ================= STEP 3 =================
  Widget _stepDietList() {
    return Obx(() {
      /// 🔄 LOADING
      if (vm.isSubscriptionRequired.value) {
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
                  vm.subscriptionMessage.value,
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
      if (vm.isError.value) {
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
                  vm.errorMessage.value,
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
      if (vm.dietList.isEmpty) {
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
          itemCount: vm.dietList.length,
          itemBuilder: (_, i) {
            final diet = vm.dietList[i];

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
                      color: Colors.black.withOpacity(isDark ? 0.35 : 0.1),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
          IconButton(
            tooltip: "Medical sources",
            onPressed: _openMedicalSourcesSheet,
            icon: Icon(
              Icons.verified_outlined,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
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
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.12),
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
                        color: Theme.of(context).colorScheme.onSurface,
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
    final tileBg = isDark ? Colors.grey.shade100 : const Color(0xFF1E1E1E);
    final borderColor = isDark ? Colors.grey.shade300 : Colors.white12;

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
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
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
                final bool isSelected = t.currentLang.value == lang.code;

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
                        color: isSelected ? Colors.redAccent : borderColor,
                        width: 1.2,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.2),
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
                              color: isSelected ? Colors.redAccent : textColor,
                            ),
                          ),
                        ),

                        /// ✅ CHECK
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
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
