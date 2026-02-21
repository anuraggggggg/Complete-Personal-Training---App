import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';

class HealthService {
  /// ✅ Stable health instance (Google Fit)
  final Health _health = Health();

  /// Health data we need
  final List<HealthDataType> _types = [
    HealthDataType.HEART_RATE,
  ];

  /// Read-only access
  final List<HealthDataAccess> _permissions = [
    HealthDataAccess.READ,
  ];

  bool _permissionShownOnce = false;

  // ==========================================================
  // 🔐 REQUEST PERMISSION (PRODUCTION SAFE)
  // ==========================================================
  Future<bool> requestPermission() async {
    try {
      debugPrint("🩺 Requesting health permissions...");

      /// 1️⃣ Runtime permissions
      final runtimeGranted = await _requestRuntimePermissions();
      if (!runtimeGranted) {
        _showPermissionSnack(
          title: "Permission Required",
          message:
              "Please allow activity & sensor permissions to track heart rate.",
          showSettings: true,
        );
        return false;
      }

      /// 2️⃣ Already granted?
      final hasPermission =
          await _health.hasPermissions(_types, permissions: _permissions);

      if (hasPermission == true) {
        debugPrint("✅ Health permission already granted");
        return true;
      }

      /// 3️⃣ Request Google Fit / Health permission
      final granted = await _health.requestAuthorization(
        _types,
        permissions: _permissions,
      );

      if (!granted) {
        _showPermissionSnack(
          title: "Health Access Needed",
          message:
              "Please allow Google Fit / Health access to read heart rate data.",
          showSettings: true,
        );
        return false;
      }

      _showSuccessSnack(
        "Connected",
        "Heart health tracking enabled successfully ❤️",
      );
      return true;
    } catch (e) {
      debugPrint("❌ Health permission error: $e");
      _showErrorSnack("Something went wrong while requesting permissions.");
      return false;
    }
  }

  // ==========================================================
  // 📱 ANDROID RUNTIME PERMISSIONS
  // ==========================================================
  Future<bool> _requestRuntimePermissions() async {
    final activity = await Permission.activityRecognition.request();
    if (!activity.isGranted) return false;

    final sensors = await Permission.sensors.request();
    if (!sensors.isGranted) return false;

    return true;
  }

  // ==========================================================
  // ❤️ GET LATEST HEART RATE
  // ==========================================================
  Future<int?> getLatestHeartRate() async {
    try {
      final now = DateTime.now();
      final start = now.subtract(const Duration(hours: 24));

      final data = await _health.getHealthDataFromTypes(
        startTime: start,
        endTime: now,
        types: _types,
      );

      if (data.isEmpty) {
        _showInfoSnack(
          "No Data",
          "No heart rate data found. Please wear your fitness device.",
        );
        return null;
      }

      data.sort((a, b) => b.dateTo.compareTo(a.dateTo));
      final value = data.first.value;

      if (value is NumericHealthValue) {
        return value.numericValue.toInt();
      }

      return null;
    } catch (e) {
      debugPrint("❌ Error reading heart rate: $e");
      _showErrorSnack("Unable to read heart rate data.");
      return null;
    }
  }

  // ==========================================================
  // 🔄 HEART RATE STREAM
  // ==========================================================
  Stream<int> heartRateStream() async* {
    while (true) {
      final bpm = await getLatestHeartRate();
      if (bpm != null && bpm > 0) {
        yield bpm;
      }
      await Future.delayed(const Duration(seconds: 5));
    }
  }

  // ==========================================================
  // 🔔 SNACKBAR HELPERS (UX SAFE)
  // ==========================================================

  void _showPermissionSnack({
    required String title,
    required String message,
    bool showSettings = false,
  }) {
    if (_permissionShownOnce || Get.isSnackbarOpen) return;
    _permissionShownOnce = true;

    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(14),
      backgroundColor: const Color(0xFFFFE5E5),
      colorText: Colors.black87,
      icon: const Icon(Icons.favorite_border, color: Colors.redAccent),
      borderRadius: 16,
      mainButton: showSettings
          ? TextButton(
              onPressed: () {
                openAppSettings();
              },
              child: const Text(
                "OPEN SETTINGS",
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
      duration: const Duration(seconds: 4),
    );
  }

  void _showSuccessSnack(String title, String message) {
    if (Get.isSnackbarOpen) return;
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      icon: const Icon(Icons.check_circle, color: Colors.white),
      margin: const EdgeInsets.all(14),
      borderRadius: 14,
      duration: const Duration(seconds: 3),
    );
  }

  void _showInfoSnack(String title, String message) {
    if (Get.isSnackbarOpen) return;
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.orange.shade200,
      colorText: Colors.black,
      icon: const Icon(Icons.info_outline),
      margin: const EdgeInsets.all(14),
      borderRadius: 14,
      duration: const Duration(seconds: 3),
    );
  }

  void _showErrorSnack(String message) {
    if (Get.isSnackbarOpen) return;
    Get.snackbar(
      "Error",
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.redAccent,
      colorText: Colors.white,
      icon: const Icon(Icons.error_outline, color: Colors.white),
      margin: const EdgeInsets.all(14),
      borderRadius: 14,
      duration: const Duration(seconds: 3),
    );
  }
}
