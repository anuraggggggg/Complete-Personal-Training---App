import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import '../extensions/loader_widget.dart';
import '../extensions/extension_util/context_extensions.dart';
import '../extensions/extension_util/int_extensions.dart';
import '../extensions/extension_util/widget_extensions.dart';
import '../extensions/app_button.dart';
import '../extensions/app_text_field.dart';
import '../extensions/common.dart';
import '../extensions/constants.dart';
import '../extensions/decorations.dart';
import '../extensions/text_styles.dart';
import '../extensions/widgets.dart';
import '../main.dart';
import '../network/rest_api.dart';
import '../utils/app_colors.dart';
import '../utils/app_common.dart';
import 'forgot_pwd_otp_screen.dart';

class ForgotPwdScreen extends StatefulWidget {
  const ForgotPwdScreen({super.key});

  @override
  State<ForgotPwdScreen> createState() => _ForgotPwdScreenState();
}

class _ForgotPwdScreenState extends State<ForgotPwdScreen> {
  GlobalKey<FormState> mFormKey = GlobalKey<FormState>();

  TextEditingController mEmailCont = TextEditingController();

  Future<void> resetPassword() async {
    hideKeyboard(context);
    if (mFormKey.currentState!.validate()) {
      mFormKey.currentState!.save();
      appStore.setLoading(true);
      final String email = mEmailCont.text.trim();
      Map req = {'email': email};
      await forgotPwdApi(req).then((value) {
        appStore.setLoading(false);
        toast(value.message);
        if (!mounted) return;
        ForgotPwdOtpScreen(email: email).launch(context);
      }).catchError((error) {
        toast(error.toString());
        appStore.setLoading(false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarWidget(
        "",
        color: appStore.isDarkMode ? scaffoldColorDark : Colors.white,
        context: context,
      ),
      body: Observer(builder: (context) {
        return Stack(
          children: [
            SingleChildScrollView(
              child: Form(
                key: mFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(languages.lblForgotPassword,
                        style: boldTextStyle(size: 22)),
                    12.height,
                    Text(languages.lblForgotPwdMsg,
                        style: secondaryTextStyle()),
                    24.height,
                    Text(languages.lblEmail,
                        style:
                            secondaryTextStyle(color: textPrimaryColorGlobal)),
                    4.height,
                    AppTextField(
                      controller: mEmailCont,
                      textFieldType: TextFieldType.EMAIL,
                      isValidationRequired: true,
                      // suffix: mSuffixTextFieldIconWidget(ic_mail),
                      onFieldSubmitted: (c) {
                        resetPassword();
                      },
                      decoration: defaultInputDecoration(context,
                          label: languages.lblEnterEmail),
                    ),
                    30.height,
                    AppButton(
                      text: languages.lblContinue,
                      width: context.width(),
                      color: primaryColor,
                      onTap: () {
                        resetPassword();
                      },
                    ),
                  ],
                ).paddingSymmetric(horizontal: 16),
              ),
            ),
            Loader().visible(appStore.isLoading)
          ],
        );
      }),
    );
  }
}
