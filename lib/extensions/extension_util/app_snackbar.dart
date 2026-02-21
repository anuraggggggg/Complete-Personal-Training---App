import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class AppSnackBar {
  static void success(String title, String message) {
    _show(
      title: title,
      message: message,
      bgGradient: const LinearGradient(
        colors: [Color(0xFF00C853), Color(0xFF2E7D32)],
      ),
      icon: Icons.check_circle_rounded,
      haptic: HapticFeedback.mediumImpact,
    );
  }

  static void error(String title, String message) {
    _show(
      title: title,
      message: message,
      bgGradient: const LinearGradient(
        colors: [Color(0xFFD32F2F), Color(0xFFB71C1C)],
      ),
      icon: Icons.error_rounded,
      haptic: HapticFeedback.heavyImpact,
    );
  }

  static void warning(String title, String message) {
    _show(
      title: title,
      message: message,
      bgGradient: const LinearGradient(
        colors: [Color(0xFFFFA000), Color(0xFFF57C00)],
      ),
      icon: Icons.warning_amber_rounded,
      haptic: HapticFeedback.lightImpact,
    );
  }

  // ================= CORE =================

  static void _show({
    required String title,
    required String message,
    required LinearGradient bgGradient,
    required IconData icon,
    required VoidCallback haptic,
  }) {
    haptic();

    Get.snackbar(
      '',
      '',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.transparent,
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      duration: const Duration(seconds: 3),
      animationDuration: const Duration(milliseconds: 550),
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
      forwardAnimationCurve: Curves.easeOutBack,
      reverseAnimationCurve: Curves.easeIn,
      messageText: _SnackContent(
        title: title,
        message: message,
        gradient: bgGradient,
        icon: icon,
      ),
    );
  }
}

// ================= UI WIDGET =================

class _SnackContent extends StatelessWidget {
  final String title;
  final String message;
  final LinearGradient gradient;
  final IconData icon;

  const _SnackContent({
    required this.title,
    required this.message,
    required this.gradient,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
