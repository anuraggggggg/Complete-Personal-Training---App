import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import '../extensions/extension_util/context_extensions.dart';
import '../extensions/extension_util/int_extensions.dart';
import '../extensions/extension_util/string_extensions.dart';
import '../extensions/extension_util/widget_extensions.dart';
import '../extensions/loader_widget.dart';
import '../extensions/app_button.dart';
import '../extensions/app_text_field.dart';
import '../extensions/common.dart';
import '../extensions/constants.dart';
import '../extensions/decorations.dart';
import '../extensions/shared_pref.dart';
import '../extensions/text_styles.dart';
import '../extensions/widgets.dart';
import '../main.dart';
import '../network/rest_api.dart';
import '../utils/app_colors.dart';
import '../utils/app_common.dart';
import '../utils/app_constants.dart';
import '../utils/subscription_navigation.dart';

class ForgotPwdResetScreen extends StatefulWidget {
  final String email;
  final String otp;

  const ForgotPwdResetScreen({
    super.key,
    required this.email,
    required this.otp,
  });

  @override
  State<ForgotPwdResetScreen> createState() => _ForgotPwdResetScreenState();
}

class _ForgotPwdResetScreenState extends State<ForgotPwdResetScreen> {
  final GlobalKey<FormState> mFormKey = GlobalKey<FormState>();

  final TextEditingController mPassCont = TextEditingController();
  final TextEditingController mConfirmPassCont = TextEditingController();

  final FocusNode mPassFocus = FocusNode();
  final FocusNode mConfirmPassFocus = FocusNode();

  Future<void> _resetPassword() async {
    hideKeyboard(context);

    if (!mFormKey.currentState!.validate()) return;

    appStore.setLoading(true);

    try {
      final resetResponse = await resetPwdApi({
        'email': widget.email,
        'otp': widget.otp,
        'password': mPassCont.text.trim(),
        'password_confirmation': mConfirmPassCont.text.trim(),
      });

      final loginResponse = await logInApi({
        'email': widget.email,
        'username': widget.email,
        'password': mPassCont.text.trim(),
        'login_type': LoginTypeApp,
        'user_type': LoginUser,
        'status': statusActive,
        'player_id': getStringAsync(PLAYER_ID).validate(),
      });

      await setValue(TOKEN, loginResponse.data?.apiToken.validate() ?? '');
      await setValue(EMAIL, widget.email);
      await setValue(PASSWORD, mPassCont.text.trim());
      await setValue(IS_LOGIN, true);

      if (!mounted) return;

      toast(resetResponse.message.validate().isNotEmpty
          ? resetResponse.message.validate()
          : 'Password reset successfully');
      openPostAuthDestination(allowFreeAutopayPrompt: false);
    } catch (error) {
      toast(error.toString());
    } finally {
      appStore.setLoading(false);
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
      body: Observer(
        builder: (context) {
          return Stack(
            children: [
              SingleChildScrollView(
                child: Form(
                  key: mFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(languages.lblNewPassword,
                          style: boldTextStyle(size: 22)),
                      12.height,
                      Text(
                        'Set a new password for ${widget.email}',
                        style: secondaryTextStyle(),
                      ),
                      24.height,
                      Text(
                        languages.lblNewPassword,
                        style:
                            secondaryTextStyle(color: textPrimaryColorGlobal),
                      ),
                      4.height,
                      AppTextField(
                        controller: mPassCont,
                        focus: mPassFocus,
                        nextFocus: mConfirmPassFocus,
                        textFieldType: TextFieldType.PASSWORD,
                        keyboardType: TextInputType.visiblePassword,
                        isValidationRequired: true,
                        decoration: defaultInputDecoration(
                          context,
                          label: languages.lblEnterNewPwd,
                        ),
                      ),
                      16.height,
                      Text(
                        languages.lblConfirmPassword,
                        style:
                            secondaryTextStyle(color: textPrimaryColorGlobal),
                      ),
                      4.height,
                      AppTextField(
                        controller: mConfirmPassCont,
                        focus: mConfirmPassFocus,
                        textFieldType: TextFieldType.PASSWORD,
                        keyboardType: TextInputType.visiblePassword,
                        decoration: defaultInputDecoration(
                          context,
                          label: languages.lblEnterConfirmPwd,
                        ),
                        validator: (String? value) {
                          if (value!.isEmpty) return errorThisFieldRequired;
                          if (value.length < passwordLengthGlobal) {
                            return languages.errorPwdLength;
                          }
                          if (value.trim() != mPassCont.text.trim()) {
                            return languages.errorPwdMatch;
                          }
                          return null;
                        },
                        onFieldSubmitted: (value) {
                          _resetPassword();
                        },
                      ),
                      24.height,
                      AppButton(
                        text: languages.lblSubmit,
                        width: context.width(),
                        color: primaryColor,
                        onTap: _resetPassword,
                      ),
                    ],
                  ).paddingSymmetric(horizontal: 16),
                ),
              ),
              Loader().visible(appStore.isLoading),
            ],
          );
        },
      ),
    );
  }
}
