import 'package:flutter/material.dart';

// App Color
const primaryColor = Color(0xFFAF001C);
const primaryLightColor = Color(0xfff6bea3);

// Dark Color
const scaffoldBackgroundColor = Color(0xFF4A4A4A);

const scaffoldColorDark = Color(0xFF1D1D1D);

const Color kBg = Color(0xFF050505);
const Color kCard = Color(0xFF141414);
const Color kAccent = Color(0xFFE10600);
const Color kGlow = Color(0x44E10600);

Color bg(BuildContext c) =>
    Theme.of(c).brightness == Brightness.dark
        ? kBg
        : Theme.of(c).colorScheme.surface;

Color card(BuildContext c) =>
    Theme.of(c).brightness == Brightness.dark
        ? kCard
        : Theme.of(c).colorScheme.surface;

Color textPrimary(BuildContext c) =>
    Theme.of(c).colorScheme.onSurface;

Color textSecondary(BuildContext c) =>
    Theme.of(c).colorScheme.onSurface.withOpacity(0.7);



/// ✅ BACKWARD COMPATIBILITY (IMPORTANT)
/// Old code me jahan-jahan `primary` use hua hai
/// un sab ke liye alias
const Color primary = primaryColor;

/// Existing colors (example)
const Color cardLightColor = Colors.white;
const Color cardDarkColor = Color(0xFF141414);


// Other Color
const socialBackground = Color(0xFF2F2F2F);

const BackgroundColorImageColor = Color(0xffFAFAFA);

const GreyLightColor = Color(0xffEDEDED);

const cardBackground = Color(0xFFFAFAFA);

const grayColor = Color(0xffC5C6C7);

const primaryOpacity = Color(0xffFDF2ED);

const replyMsgBgColor = Color(0xFF243037);

const textColor = Color(0xff8A8A8A);

const GreenColor = Color(0xff199226);

const RedColor = Color(0xffF4462C);

const YellowColor = Color(0xffF9AA00);
const stepBackground = Color(0xffEEF4FF);
const favDietBackground = Color(0xffC2D5D9);
const favBackground = Color(0xffA4A29B);
