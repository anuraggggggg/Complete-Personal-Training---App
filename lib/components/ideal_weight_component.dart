import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mighty_fitness/utils/WeightCalculator.dart';
import '../extensions/LiveStream.dart';
import '../extensions/colors.dart';
import '../extensions/decorations.dart';
import '../extensions/extension_util/context_extensions.dart';
import '../extensions/extension_util/int_extensions.dart';
import '../extensions/extension_util/string_extensions.dart';
import '../extensions/text_styles.dart';
import '../main.dart';
import '../utils/app_colors.dart';
import '../utils/app_constants.dart';
import '../utils/app_images.dart';
import 'count_down_progress_indicator.dart';

class IdealWeightComponent extends StatefulWidget {
  static String tag = '/BMIComponent';

  @override
  IdealWeightComponentState createState() => IdealWeightComponentState();
}

class IdealWeightComponentState extends State<IdealWeightComponent>
    with TickerProviderStateMixin {

  double result = 0.0;
  int feet = 0;
  int inches = 0;

  CountDownController mCountDownController = CountDownController();

  @override
  void initState() {
    super.initState();
    _init();
    LiveStream().on(PROGRESS, (_) {
      if (mounted) setState(() {});
    });
  }

  // ===========================
  // SAFE DOUBLE PARSER
  // ===========================
  double _safeDouble(dynamic value) {
    if (value == null) return 0.0;

    final cleaned = value
        .toString()
        .replaceAll(RegExp(r'[^0-9.]'), '')
        .trim();

    return double.tryParse(cleaned) ?? 0.0;
  }

  // ===========================
  // INIT
  // ===========================
  void _init() {
    final heightValue = _safeDouble(userStore.height);

    if (heightValue <= 0) {
      result = 0.0;
      return;
    }

    if (userStore.heightUnit == METRICS_CM) {
      _convertCmToFeet(heightValue);
    } else {
      _convertFeetDecimalToFeetInches(heightValue);
    }

    _calculateIdealWeight();
  }

  // ===========================
  // CALCULATION
  // ===========================
  void _calculateIdealWeight() {
    result = calculateIdealWeight(
      userStore.gender.validate(),
      feet.toDouble(),
      inches.toDouble(),
    );

    if (mounted) setState(() {});
  }

  // ===========================
  // CM → FEET / INCHES
  // ===========================
  void _convertCmToFeet(double cm) {
    final totalInches = cm / 2.54;
    feet = (totalInches / 12).floor();
    inches = (totalInches % 12).round();
  }

  // ===========================
  // 5.7 → FEET / INCHES
  // ===========================
  void _convertFeetDecimalToFeetInches(double feetDecimal) {
    feet = feetDecimal.floor();
    inches = ((feetDecimal - feet) * 12).round();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: appStore.isDarkMode
          ? boxDecorationWithRoundedCorners(
              borderRadius: radius(16),
              backgroundColor: context.cardColor,
            )
          : boxDecorationRoundedWithShadow(
              16,
              backgroundColor: context.cardColor,
            ),
      child: Observer(
        builder: (_) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    decoration: boxDecorationWithRoundedCorners(
                      borderRadius: radius(8),
                      backgroundColor:
                          appStore.isDarkMode ? Colors.black : Colors.white,
                    ),
                    padding: const EdgeInsets.all(6),
                    child: Image.asset(
                      ic_ideal_weight,
                      width: 20,
                      height: 20,
                      color: primaryColor,
                    ),
                  ),
                  Text(
                    languages.lblIdealWeight,
                    style: boldTextStyle(
                      color: appStore.isDarkMode ? primaryColor : black,
                    ),
                  ),
                ],
              ),

              12.height,

              Image.asset(
                ic_ideal_weight1,
                width: 50,
                height: 50,
                color: primaryColor,
              ),

              10.height,

              Text(
                result > 0 ? result.toStringAsFixed(1) : "--",
                style: boldTextStyle(size: 20),
              ),

              Text(
                languages.lblKg,
                style: secondaryTextStyle(),
              ),
            ],
          );
        },
      ),
    );
  }
}
