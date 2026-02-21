import 'package:flutter/material.dart';
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
import '../../extensions/widgets.dart';
import '../../main.dart';
import '../utils/app_colors.dart' hide primary;
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
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
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
          appBar: appBarWidget(
            "",
            backWidget: const Icon(
              Octicons.chevron_left,
              color: Colors.black, // Back arrow black
              size: 28,
            ).onTap(() {
              if (appStore.signUpIndex == 0) {
                finish(context);
              } else {
                isNewTask = false;
                appStore.signUpIndex--;
                setState(() {});
              }
            }),
            color: Colors.white, // AppBar background white
            elevation: 0,
            textColor: Colors.black, // Title text black
            context: context,
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
                      backgroundColor:
                          appStore.signUpIndex >= index ? primary : GreyLightColor,
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
                const SignUpStep6Component().expand(),
              if (appStore.signUpIndex == 6)
                const SignUpStep7Component().expand(),
              if (appStore.signUpIndex == 7)
                const SignUpStep12Component().expand(),
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
