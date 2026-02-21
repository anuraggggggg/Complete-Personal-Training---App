import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_chrome_cast/lib.dart';
import 'dart:async';

class CastManager {
  GoogleCastOptions? options;

  Future<void> initPlatformState({int retryCount = 0, int maxRetries = 3}) async {
    try {
      const appId = GoogleCastDiscoveryCriteria.kDefaultApplicationId;
      print("Initializing Google Cast with appId: $appId");

      if (Platform.isIOS) {
        options = IOSGoogleCastOptions(
          GoogleCastDiscoveryCriteriaInitialize.initWithApplicationID(appId),
        );
      } else if (Platform.isAndroid) {
        options = GoogleCastOptionsAndroid(
          appId: appId,
        );
      } else {
        throw UnsupportedError("Platform not supported");
      }

      // Initialize Cast context
      await GoogleCastContext.instance.setSharedInstanceWithOptions(options!);
      print("GoogleCastContext initialized successfully");
    } catch (e, s) {
      print('Error initializing CastContext: $e');
      print('Stack trace: $s');

      // Retry logic
      if (retryCount < maxRetries) {
        print("Retrying initialization (attempt ${retryCount + 1}/$maxRetries)...");
        await Future.delayed(Duration(seconds: retryCount + 1));
        return initPlatformState(retryCount: retryCount + 1, maxRetries: maxRetries);
      } else {
        print("Failed to initialize CastContext after $maxRetries attempts.");
        rethrow;
      }
    }
  }

  // Example method to connect to a device
  Future<void> connectToChromecast(BuildContext context) async {
    try {
      await initPlatformState();
      // Add logic to select and connect to a device
      print("Connected to Chromecast");
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to connect: $e")),
      );
    }
  }
}