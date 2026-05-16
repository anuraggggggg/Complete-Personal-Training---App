import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:mighty_fitness/app_theme.dart';
import 'package:mighty_fitness/components/sign_up_step_5.dart';
import 'package:mighty_fitness/components/signup_step_6.dart';
import 'package:mighty_fitness/components/signup_step_7.dart';
import 'package:mighty_fitness/screens/sign_up_step_12.dart';
import '../../extensions/decorations.dart';
import '../../extensions/extension_util/context_extensions.dart';
import '../../extensions/extension_util/int_extensions.dart';
import '../../extensions/extension_util/widget_extensions.dart';
import '../../extensions/system_utils.dart';
import '../../main.dart';
import '../extensions/shared_pref.dart';
import '../utils/app_colors.dart' hide primary;
import '../utils/app_constants.dart';
import '../components/sign_up_step1_component.dart';
import '../components/sign_up_step2_component.dart';
import '../components/sign_up_step3_component.dart';
import '../components/sign_up_step4_component.dart';

class SignUpScreen extends StatefulWidget {
  final String? phoneNumber;
  const SignUpScreen({super.key, this.phoneNumber});

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  bool? isNewTask = true;

  @override
  void initState() {
    super.initState();
    init();
  }

  init() async {
    appStore.signUpIndex = 0;
    await setValue(ACCEPTED_TERMS, false);
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appBarColor = isDark ? const Color(0xFF121212) : Colors.white;
    final backIconColor = Colors.red;
    final statusIconBrightness =
        isDark ? Brightness.light : Brightness.dark;

    return WillPopScope(
      onWillPop: () async {
        if (appStore.signUpIndex == 0) {
          appStore.setLoading(false);
          finish(context);
          return false;
        } else {
          isNewTask = false;
          appStore.signUpIndex--;
          setState(() {});
          return false;
        }
      },
      child: Observer(builder: (context) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: appBarColor,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                Octicons.chevron_left,
                color: backIconColor,
                size: 28,
              ),
              onPressed: () {
                if (appStore.signUpIndex == 0) {
                  finish(context);
                } else {
                  isNewTask = false;
                  appStore.signUpIndex--;
                  setState(() {});
                }
              },
            ),
            systemOverlayStyle: SystemUiOverlayStyle(
              statusBarColor: appBarColor,
              statusBarIconBrightness: statusIconBrightness,
              statusBarBrightness:
                  isDark ? Brightness.dark : Brightness.light,
            ),
          ),
          body: Column(
            children: [
              4.height,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(14, (index) {
                  return Container(
                    alignment: Alignment.center,
                    height: 5,
                    width: context.width() / 17,
                    decoration: boxDecorationWithRoundedCorners(
                      backgroundColor: appStore.signUpIndex >= index
                          ? primary
                          : GreyLightColor,
                    ),
                  );
                }).toList(),
              ).paddingSymmetric(horizontal: 12),
              16.height,
              if (appStore.signUpIndex == 0)
                SignUpStep1Component(isNewTask: isNewTask).expand(),
              if (appStore.signUpIndex == 1)
                SignUpStep2Component(isNewTask: isNewTask).expand(),
              if (appStore.signUpIndex == 2)
                SignUpStep3Component(isNewTask: isNewTask).expand(),
              if (appStore.signUpIndex == 3)
                SignUpStep4Component(isNewTask: isNewTask).expand(),
              if (appStore.signUpIndex == 4)
                const SignUpStep5Component().expand(),
              if (appStore.signUpIndex == 5)
                const SignUpStep12Component().expand(),
              if (appStore.signUpIndex == 6)
                const SignUpStep6Component().expand(),
              if (appStore.signUpIndex == 7)
                const SignUpStep7Component().expand(),
              // Skipped SignUpStep8Component
              // if (appStore.signUpIndex == 8)
              //   const SignUpStep10Component().expand(),
              // if (appStore.signUpIndex == 9)
              //   const SignUpStep11Component().expand(),
              // if (appStore.signUpIndex == 8)
              //     const SignUpStep13Component().expand(),
            ],
          ),
        );
      }),
    );
  }
}
