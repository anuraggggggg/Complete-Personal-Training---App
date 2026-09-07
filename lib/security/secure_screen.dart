import 'package:flutter/material.dart';

import 'screen_security_service.dart';

class SecureScreen extends StatefulWidget {
  const SecureScreen({
    super.key,
    required this.child,
    this.onScreenshotTaken,
    this.showScreenshotWarning = true,
    this.screenshotWarningMessage =
        'Screenshot detected on a protected screen.',
  });

  final Widget child;
  final VoidCallback? onScreenshotTaken;
  final bool showScreenshotWarning;
  final String screenshotWarningMessage;

  @override
  State<SecureScreen> createState() => _SecureScreenState();
}

class _SecureScreenState extends State<SecureScreen>
    with WidgetsBindingObserver {
  final ScreenSecurityService _screenSecurity = ScreenSecurityService.instance;
  VoidCallback? _removeScreenshotListener;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _removeScreenshotListener =
        _screenSecurity.addScreenshotListener(_handleScreenshotTaken);
    _screenSecurity.enableProtection();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _screenSecurity.refreshCaptureState();
    }
  }

  @override
  void didUpdateWidget(covariant SecureScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.onScreenshotTaken != widget.onScreenshotTaken) {
      _removeScreenshotListener?.call();
      _removeScreenshotListener =
          _screenSecurity.addScreenshotListener(_handleScreenshotTaken);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _removeScreenshotListener?.call();
    _screenSecurity.disableProtection();
    super.dispose();
  }

  void _handleScreenshotTaken() {
    widget.onScreenshotTaken?.call();

    if (!widget.showScreenshotWarning || !mounted) return;

    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(content: Text(widget.screenshotWarningMessage)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _screenSecurity.isScreenCaptured,
      builder: (context, isCaptured, child) {
        return Stack(
          fit: StackFit.expand,
          children: [
            child!,
            if (isCaptured) const _PrivacyOverlay(),
          ],
        );
      },
      child: widget.child,
    );
  }
}

class _PrivacyOverlay extends StatelessWidget {
  const _PrivacyOverlay();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: 'Screen capture is disabled',
      child: ColoredBox(
        color: const Color(0xFF111315),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.lock_outline,
                    color: Colors.white,
                    size: 52,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Screen capture is disabled',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'For your security, this content cannot be viewed while screen recording or mirroring is active.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ScreenSecurityOverlay extends StatelessWidget {
  const ScreenSecurityOverlay({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ScreenSecurityService.instance.isScreenCaptured,
      builder: (context, isCaptured, child) {
        return Stack(
          fit: StackFit.expand,
          children: [
            child!,
            if (isCaptured) const _PrivacyOverlay(),
          ],
        );
      },
      child: child,
    );
  }
}
