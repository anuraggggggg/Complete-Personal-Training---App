import 'package:flutter/material.dart';
import 'package:tuple/tuple.dart';
import '../../extensions/loader_widget.dart';
import '../../extensions/extension_util/context_extensions.dart';
import '../../extensions/extension_util/int_extensions.dart';
import '../../extensions/extension_util/string_extensions.dart';
import '../../extensions/extension_util/widget_extensions.dart';
import '../../main.dart';
import '../../screens/dashboard_screen.dart';
import '../extensions/app_button.dart';
import '../extensions/app_text_field.dart';
import '../extensions/common.dart';
import '../extensions/decorations.dart';
import '../extensions/shared_pref.dart';
import '../extensions/text_styles.dart';
import '../models/register_request.dart';
import '../network/rest_api.dart';
import '../utils/app_common.dart';
import '../utils/app_constants.dart';
import '../widget/custome_height_picker.dart';
import '../widget/weight_widget.dart';

class SignUpStep4Component extends StatefulWidget {
  final bool? isNewTask;
  const SignUpStep4Component({super.key, this.isNewTask});

  @override
  State<SignUpStep4Component> createState() => _SignUpStep4ComponentState();
}

class _SignUpStep4ComponentState extends State<SignUpStep4Component> {
  final GlobalKey<FormState> mFormKey = GlobalKey<FormState>();

  final TextEditingController mWeightCont = TextEditingController();
  final TextEditingController mHeightCont = TextEditingController();

  final FocusNode mWeightFocus = FocusNode();
  final FocusNode mHeightFocus = FocusNode();

  bool isSnackbarVisible = false;

  WeightType weightType = WeightType.kg;
  double weight = 60;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    mWeightCont.text = userStore.weight.validate().isNotEmpty
        ? "${userStore.weight.validate()} ${userStore.weightUnit}"
        : "";

    mHeightCont.text = userStore.height.validate().isNotEmpty
        ? "${userStore.height.validate()} ${userStore.heightUnit}"
        : "";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Stack(
      children: [
        SingleChildScrollView(
          child: Form(
            key: mFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// TITLE
                Text(
                  languages.lblLetUsKnowBetter,
                  style: boldTextStyle(size: 22)
                      .copyWith(color: cs.onBackground),
                ),

                24.height,

                /// WEIGHT
                Text(
                  languages.lblWeight,
                  style: secondaryTextStyle(color: cs.onSurface),
                ),
                6.height,
                AppTextField(
                  readOnly: true,
                  controller: mWeightCont,
                  textFieldType: TextFieldType.NUMBER,
                  focus: mWeightFocus,
                  onTap: () => _openWeightPicker(context),
                  decoration: defaultInputDecoration(
                    context,
                    label: languages.lblEnterWeight,
                  ),
                ),

                16.height,

                /// HEIGHT
                Text(
                  languages.lblHeight,
                  style: secondaryTextStyle(color: cs.onSurface),
                ),
                6.height,
                AppTextField(
                  readOnly: true,
                  controller: mHeightCont,
                  textFieldType: TextFieldType.NUMBER,
                  focus: mHeightFocus,
                  onTap: () {
                    CustomeHeightPicker(
                      heightSelected: (val) {
                        mHeightCont.text =
                            "$val ${userStore.heightUnit.validate()}";
                      },
                    ).launch(context);
                  },
                  decoration: defaultInputDecoration(
                    context,
                    label: languages.lblEnterHeight,
                  ),
                ),

                70.height,

                /// DONE BUTTON
                AppButton(
                  text: languages.lblDone,
                  width: context.width(),
                  color: cs.primary,
                  onTap: () {
                    if (mWeightCont.text.isEmpty ||
                        mHeightCont.text.isEmpty) {
                      _showSnackBar(context, cs);
                      return;
                    }

                    final height = mHeightCont.text.split(' ');
                    final weight = mWeightCont.text.split(' ');

                    if (height.length >= 2) {
                      userStore.setHeight(height[0]);
                      userStore.setHeightUnit(height[1]);
                    }

                    if (weight.length >= 2) {
                      userStore.setWeight(weight[0]);
                      userStore.setWeightUnit(weight[1]);
                    }

                    appStore.signUpIndex = 4;
                    setState(() {});
                  },
                ),
              ],
            ).paddingSymmetric(horizontal: 16),
          ),
        ),

        /// LOADER
        Loader().visible(appStore.isLoading),
      ],
    );
  }

  void _showSnackBar(BuildContext context, ColorScheme cs) {
    if (isSnackbarVisible) return;
    isSnackbarVisible = true;

    ScaffoldMessenger.of(context)
        .showSnackBar(
          SnackBar(
            backgroundColor: cs.primary,
            content: Text(
              "Please enter height and weight",
              style: TextStyle(
                color: cs.onPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        )
        .closed
        .then((_) => isSnackbarVisible = false);
  }

  /// WEIGHT PICKER
  void _openWeightPicker(BuildContext context) async {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final res = await showModalBottomSheet<Tuple2<WeightType, double>>(
      context: context,
      backgroundColor: cs.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) {
        double currentWeight = weight;
        WeightType currentType = weightType;

        return StatefulBuilder(
          builder: (_, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Header(weightType: currentType, inKg: currentWeight),
                  Switcher(
                    weightType: currentType,
                    onChanged: (type) =>
                        setModalState(() => currentType = type),
                  ),
                  12.height,
                  Text(
                    "${currentWeight.toStringAsFixed(1)} ${currentType.name}",
                    style:
                        boldTextStyle(size: 18).copyWith(color: cs.onSurface),
                  ),
                  12.height,
                  DivisionSlider(
                    from: currentType == WeightType.kg ? 20 : 45,
                    max: currentType == WeightType.kg ? 200 : 400,
                    initialValue: currentWeight,
                    type: currentType,
                    onChanged: (val) =>
                        setModalState(() => currentWeight = val),
                  ),
                  16.height,
                  AppButton(
                    text: "Select",
                    width: context.width(),
                    color: cs.primary,
                    onTap: () {
                      Navigator.pop(
                        context,
                        Tuple2(currentType, currentWeight),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (res != null) {
      setState(() {
        weightType = res.item1;
        weight = res.item2;
        mWeightCont.text =
            "${res.item2.toStringAsFixed(1)} ${res.item1.name}";
      });
    }
  }
}
