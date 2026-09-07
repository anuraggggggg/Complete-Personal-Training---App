import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

typedef ScreenshotTakenCallback = void Function();

class ScreenSecurityService {
  ScreenSecurityService._() {
    _channel.setMethodCallHandler(_handleNativeEvent);
  }

  static final ScreenSecurityService instance = ScreenSecurityService._();

  static const MethodChannel _channel =
      MethodChannel('com.myapp.screen_security');

  final ValueNotifier<bool> isScreenCaptured = ValueNotifier<bool>(false);
  final List<ScreenshotTakenCallback> _screenshotCallbacks = [];

  int _protectionCount = 0;
  bool _isProtectionEnabled = false;

  /// iOS does not provide a public API to completely prevent screenshots.
  /// This implementation protects sensitive content where technically possible,
  /// detects screenshots, and hides protected content during screen recording or
  /// mirroring.
  Future<void> enableProtection() async {
    _protectionCount++;
    if (_isProtectionEnabled) {
      await refreshCaptureState();
      return;
    }

    _isProtectionEnabled = true;
    if (!Platform.isIOS && !Platform.isAndroid) return;

    try {
      await _channel.invokeMethod<void>('enableProtection');
      await refreshCaptureState();
    } catch (error) {
      debugPrint('Screen security enableProtection failed: $error');
    }
  }

  Future<void> disableProtection() async {
    if (_protectionCount > 0) _protectionCount--;
    if (_protectionCount > 0 || !_isProtectionEnabled) return;

    _isProtectionEnabled = false;
    isScreenCaptured.value = false;

    if (!Platform.isIOS && !Platform.isAndroid) return;

    try {
      await _channel.invokeMethod<void>('disableProtection');
    } catch (error) {
      debugPrint('Screen security disableProtection failed: $error');
    }
  }

  Future<bool> refreshCaptureState() async {
    if (!Platform.isIOS && !Platform.isAndroid) {
      isScreenCaptured.value = false;
      return false;
    }

    try {
      final captured =
          await _channel.invokeMethod<bool>('isScreenCaptured') ?? false;
      isScreenCaptured.value = captured;
      return captured;
    } catch (error) {
      debugPrint('Screen security isScreenCaptured failed: $error');
      return isScreenCaptured.value;
    }
  }

  VoidCallback addScreenshotListener(ScreenshotTakenCallback callback) {
    _screenshotCallbacks.add(callback);
    return () => _screenshotCallbacks.remove(callback);
  }

  Future<void> _handleNativeEvent(MethodCall call) async {
    switch (call.method) {
      case 'screenCaptured':
        isScreenCaptured.value = true;
        break;
      case 'screenCaptureStopped':
        isScreenCaptured.value = false;
        break;
      case 'screenshotTaken':
        for (final callback in List<ScreenshotTakenCallback>.of(
          _screenshotCallbacks,
        )) {
          callback();
        }
        break;
      default:
        debugPrint('Unknown screen security event: ${call.method}');
    }
  }

  void dispose() {
    isScreenCaptured.dispose();
  }
}
