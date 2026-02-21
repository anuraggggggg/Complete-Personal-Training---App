import 'package:flutter/material.dart';
import '../../extensions/extension_util/context_extensions.dart';
import '../../utils/app_colors.dart';
import '../../extensions/text_styles.dart';
import '../main.dart';
import 'colors.dart' hide cardDarkColor, cardLightColor;
import 'constants.dart';

/// ===========================================================
/// 🔥 THEME SAFE INPUT DECORATION (LIGHT + DARK)
/// ===========================================================
InputDecoration defaultInputDecoration(
  BuildContext context, {
  String? hint,
  String? label,
  TextStyle? textStyle,
  bool? isFocusTExtField = false,
  Widget? mPrefix,
}) {
  final theme = Theme.of(context);
  final cs = theme.colorScheme;
  final isDark = theme.brightness == Brightness.dark;

  return InputDecoration(
    contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),

    floatingLabelBehavior: FloatingLabelBehavior.never,

    prefixIcon: mPrefix,

    /// 🔥 TEXT & HINT
    labelText: label ?? hint,
    labelStyle: secondaryTextStyle(
      color: cs.onSurface.withOpacity(0.6),
    ),
    hintText: hint,
    hintStyle: TextStyle(
      color: cs.onSurface.withOpacity(0.45),
    ),

    /// 🔥 BACKGROUND (MOST IMPORTANT FIX)
    filled: true,
    fillColor: isDark
        ? cs.surface.withOpacity(0.75) // 🌙 dark
        : cs.surface,                  // ☀️ light

    isDense: true,

    /// 🔲 NORMAL BORDER
    border: OutlineInputBorder(
      borderRadius: radius(),
      borderSide: BorderSide(
        color: cs.onSurface.withOpacity(0.25),
      ),
    ),

    /// 🔲 ENABLED BORDER
    enabledBorder: OutlineInputBorder(
      borderRadius: radius(),
      borderSide: BorderSide(
        color: cs.onSurface.withOpacity(0.25),
      ),
    ),

    /// 🔲 FOCUSED BORDER
    focusedBorder: OutlineInputBorder(
      borderRadius: radius(),
      borderSide: BorderSide(
        color: primaryColor,
        width: 1.5,
      ),
    ),

    /// ❌ ERROR BORDER
    errorBorder: OutlineInputBorder(
      borderRadius: radius(),
      borderSide: const BorderSide(color: Colors.red),
    ),

    focusedErrorBorder: OutlineInputBorder(
      borderRadius: radius(),
      borderSide: const BorderSide(color: Colors.red),
    ),
  );
}

/// ===========================================================
/// RADIUS HELPERS (UNCHANGED)
/// ===========================================================
BorderRadius radius([double? radius]) {
  return BorderRadius.all(radiusCircular(radius ?? defaultRadius));
}

Radius radiusCircular([double? radius]) {
  return Radius.circular(radius ?? defaultRadius);
}

ShapeBorder dialogShape([double? borderRadius]) {
  return RoundedRectangleBorder(
    borderRadius: radius(borderRadius ?? defaultRadius),
  );
}

BorderRadius radiusOnly({
  double? topRight,
  double? topLeft,
  double? bottomRight,
  double? bottomLeft,
}) {
  return BorderRadius.only(
    topRight: radiusCircular(topRight ?? 0),
    topLeft: radiusCircular(topLeft ?? 0),
    bottomRight: radiusCircular(bottomRight ?? 0),
    bottomLeft: radiusCircular(bottomLeft ?? 0),
  );
}

/// ===========================================================
/// BOX DECORATIONS (LIGHT + DARK SAFE)
/// ===========================================================
Decoration boxDecorationDefault({
  BorderRadiusGeometry? borderRadius,
  Color? color,
  Gradient? gradient,
  BoxBorder? border,
  BoxShape? shape,
  BlendMode? backgroundBlendMode,
  List<BoxShadow>? boxShadow,
  DecorationImage? image,
}) {
  return BoxDecoration(
    borderRadius:
        (shape != null && shape == BoxShape.circle) ? null : (borderRadius ?? radius()),
    boxShadow: boxShadow ?? defaultBoxShadow(),
    color: color ??
        (appStore.isDarkMode ? cardDarkColor : cardLightColor),
    gradient: gradient,
    border: border,
    shape: shape ?? BoxShape.rectangle,
    backgroundBlendMode: backgroundBlendMode,
    image: image,
  );
}

/// rounded box decoration
Decoration boxDecorationWithRoundedCorners({
  Color? backgroundColor,
  BorderRadius? borderRadius,
  LinearGradient? gradient,
  BoxBorder? border,
  List<BoxShadow>? boxShadow,
  DecorationImage? decorationImage,
  BoxShape boxShape = BoxShape.rectangle,
}) {
  return BoxDecoration(
    color: backgroundColor ??
        (appStore.isDarkMode ? cardDarkColor : cardLightColor),
    borderRadius: boxShape == BoxShape.circle ? null : (borderRadius ?? radius()),
    gradient: gradient,
    border: border,
    boxShadow: boxShadow,
    image: decorationImage,
    shape: boxShape,
  );
}

/// box decoration with shadow
Decoration boxDecorationWithShadow({
  Color? backgroundColor,
  Color? shadowColor,
  double? blurRadius,
  double? spreadRadius,
  Offset offset = const Offset(0.0, 0.0),
  LinearGradient? gradient,
  BoxBorder? border,
  List<BoxShadow>? boxShadow,
  DecorationImage? decorationImage,
  BoxShape boxShape = BoxShape.rectangle,
  BorderRadius? borderRadius,
}) {
  return BoxDecoration(
    boxShadow: boxShadow ??
        defaultBoxShadow(
          shadowColor: shadowColor,
          blurRadius: blurRadius,
          spreadRadius: spreadRadius,
          offset: offset,
        ),
    color: backgroundColor ??
        (appStore.isDarkMode ? cardDarkColor : cardLightColor),
    gradient: gradient,
    border: border,
    image: decorationImage,
    shape: boxShape,
    borderRadius: borderRadius,
  );
}

/// rounded box decoration with shadow
Decoration boxDecorationRoundedWithShadow(
  int radiusAll, {
  Color? backgroundColor,
  Color? shadowColor,
  double? blurRadius,
  double? spreadRadius,
  Offset offset = const Offset(0, 0),
  LinearGradient? gradient,
}) {
  return BoxDecoration(
    boxShadow: defaultBoxShadow(
      shadowColor: shadowColor ?? Colors.grey.withOpacity(0.065),
      blurRadius: blurRadius ?? defaultBlurRadius,
      spreadRadius: spreadRadius ?? defaultSpreadRadius,
      offset: offset,
    ),
    color: backgroundColor ??
        (appStore.isDarkMode ? cardDarkColor : cardLightColor),
    gradient: gradient,
    borderRadius: radius(radiusAll.toDouble()),
  );
}

/// default box shadow
List<BoxShadow> defaultBoxShadow({
  Color? shadowColor,
  double? blurRadius,
  double? spreadRadius,
  Offset offset = const Offset(0.0, 0.0),
}) {
  return [
    BoxShadow(
      color: shadowColor ?? Colors.grey.withOpacity(0.065),
      blurRadius: blurRadius ?? defaultBlurRadius,
      spreadRadius: spreadRadius ?? defaultSpreadRadius,
      offset: offset,
    )
  ];
}
