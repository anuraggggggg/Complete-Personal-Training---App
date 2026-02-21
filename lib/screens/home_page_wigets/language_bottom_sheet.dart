import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mighty_fitness/controllers/home_page_controller/home_page_workout_list_controller.dart';

class LanguageBottomSheet extends StatelessWidget {
  LanguageBottomSheet({super.key});

  final HomePageController controller =
      Get.find<HomePageController>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final sheetBg = isDark ? Colors.white : const Color(0xFF121212);
    final textColor = isDark ? Colors.black87 : Colors.white;
    final subTextColor =
        isDark ? Colors.black54 : Colors.white70;
    final tileBg =
        isDark ? Colors.grey.shade100 : const Color(0xFF1E1E1E);
    final borderColor =
        isDark ? Colors.grey.shade300 : Colors.white12;

    return SafeArea(
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
        child: Obx(() {
          final languages = controller.filteredLanguages;
          final selectedCode = controller.selectedLangCode.value;

          if (languages.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            );
          }

          return Column(
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

              /// 🌐 DYNAMIC LANGUAGE LIST
              ...languages.map((lang) {
                final isSelected =
                    selectedCode == lang.languageCode;

                IconData icon = Icons.language;
                if (lang.languageName == "Hindi") {
                  icon = Icons.translate;
                } else if (lang.languageName == "Spanish") {
                  icon = Icons.public;
                }

                return GestureDetector(
                  onTap: () {
                    controller.updateLanguage(
                      lang.languageCode ?? "hi",
                      lang.id ?? 1,
                    );
                    Get.back();
                  },
                  child: AnimatedContainer(
                    duration:
                        const Duration(milliseconds: 220),
                    margin:
                        const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.red.withOpacity(
                              isDark ? 0.12 : 0.18)
                          : tileBg,
                      borderRadius:
                          BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? Colors.redAccent
                            : borderColor,
                        width: 1.2,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Colors.red
                                    .withOpacity(0.2),
                                blurRadius: 14,
                                offset:
                                    const Offset(0, 6),
                              ),
                            ]
                          : [],
                    ),
                    child: Row(
                      children: [
                        /// ICON
                        Container(
                          height: 38,
                          width: 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? Colors.red
                                    .withOpacity(0.2)
                                : isDark
                                    ? Colors.grey.shade200
                                    : Colors.grey.shade800,
                          ),
                          child: Icon(
                            icon,
                            color: isSelected
                                ? Colors.redAccent
                                : textColor.withOpacity(0.7),
                            size: 20,
                          ),
                        ),

                        const SizedBox(width: 14),

                        /// TITLE
                        Expanded(
                          child: Text(
                            lang.languageName ?? "",
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

                        /// CHECK
                        AnimatedSwitcher(
                          duration: const Duration(
                              milliseconds: 180),
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
          );
        }),
      ),
    );
  }
}
