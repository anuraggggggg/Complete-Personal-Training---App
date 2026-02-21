import 'package:flutter/material.dart';

class LanguageSelectorUI extends StatelessWidget {
  const LanguageSelectorUI({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // 🔴 CHANGE THIS MANUALLY FOR UI PREVIEW
    const selectedLanguage = "English";

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /// ── Drag Handle ──
            Container(
              height: 4,
              width: 42,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            const SizedBox(height: 16),

            /// ── Title ──
            Text(
              "Select Language",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              "Choose your preferred language",
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 20),

            _langTile(
              context,
              title: "English",
              selected: selectedLanguage,
              icon: Icons.language,
            ),
            _langTile(
              context,
              title: "Hindi",
              selected: selectedLanguage,
              icon: Icons.translate,
            ),
            _langTile(
              context,
              title: "Spanish",
              selected: selectedLanguage,
              icon: Icons.public,
            ),

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _langTile(
    BuildContext context, {
    required String title,
    required String selected,
    required IconData icon,
  }) {
    final isSelected = selected == title;

    return GestureDetector(
      onTap: () {
        // ❌ NO LOGIC — UI ONLY
        Navigator.pop(context);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.red.withOpacity(0.08)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.red : Colors.grey.shade300,
            width: 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            /// Icon circle
            Container(
              height: 38,
              width: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? Colors.red.withOpacity(0.15)
                    : Colors.grey.shade100,
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.red : Colors.grey.shade700,
                size: 20,
              ),
            ),

            const SizedBox(width: 14),

            /// Language name
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? Colors.red : Colors.black87,
                ),
              ),
            ),

            /// Check icon
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: isSelected
                  ? const Icon(
                      Icons.check_circle,
                      key: ValueKey(true),
                      color: Colors.red,
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
  }
}
