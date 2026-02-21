import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../extensions/extension_util/string_extensions.dart';
import '../../extensions/extension_util/context_extensions.dart';
import '../../extensions/extension_util/int_extensions.dart';
import '../../extensions/extension_util/widget_extensions.dart';
import '../../extensions/text_styles.dart';
import '../extensions/app_button.dart';
import '../main.dart';
import '../utils/app_colors.dart';

class SignUpStep3Component extends StatefulWidget {
  final bool? isNewTask;

  const SignUpStep3Component({this.isNewTask = false, super.key});

  @override
  State<SignUpStep3Component> createState() => _SignUpStep3ComponentState();
}

class _SignUpStep3ComponentState extends State<SignUpStep3Component> {
  int mSelectedIndex = 17;

  @override
  void initState() {
    super.initState();
    if (!userStore.age.isEmptyOrNull) {
      mSelectedIndex = int.parse(userStore.age.validate());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// TITLE
          Text(
            languages.lblHowOld,
            style: boldTextStyle(size: 22).copyWith(
              color: cs.onBackground, // ✅ theme aware
            ),
          ),

          SizedBox(
            height: context.height() * 0.6,
            child: Stack(
              alignment: Alignment.center,
              children: [
                /// AGE PICKER
                CupertinoPicker(
                  magnification: 1.4,
                  squeeze: 0.9,
                  useMagnifier: true,
                  selectionOverlay: const SizedBox(),
                  itemExtent: 36,
                  scrollController: FixedExtentScrollController(
                    initialItem: mSelectedIndex - 17,
                  ),
                  onSelectedItemChanged: (int index) {
                    setState(() {
                      mSelectedIndex = index + 17;
                    });
                  },
                  children: List.generate(
                    99 - 17 + 1,
                    (index) {
                      final age = index + 17;
                      return Center(
                        child: Text(
                          age.toString(),
                          style: boldTextStyle(size: 30).copyWith(
                            color: cs.onSurface, // ✅ theme safe
                          ),
                        ),
                      );
                    },
                  ),
                ),

                /// SELECTION LINES
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 2,
                      width: 110,
                      color: primaryColor,
                    ),
                    52.height,
                    Container(
                      height: 2,
                      width: 110,
                      color: primaryColor,
                    ),
                  ],
                ),
              ],
            ),
          ),

          24.height,

          /// NEXT BUTTON
          AppButton(
            text: languages.lblNext,
            width: context.width(),
            color: primaryColor,
            onTap: () {
              userStore.setAge(mSelectedIndex.toString());
              appStore.signUpIndex = 3;
              setState(() {});
            },
          ),
        ],
      ).paddingSymmetric(horizontal: 16),
    );
  }
}
