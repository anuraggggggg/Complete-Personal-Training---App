import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mighty_fitness/controllers/translator_controller/translator_controller.dart';

class TText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? align;
  final int? maxLines;

  const TText(
    this.text, {
    super.key,
    this.style,
    this.align,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<TranslatorController>();

    return GetBuilder<TranslatorController>(
      builder: (_) => Text(
        ctrl.tr(text),
        style: style,
        textAlign: align,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
