import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:pinput/pinput.dart';
import '../extensions/loader_widget.dart';
import '../extensions/extension_util/context_extensions.dart';
import '../extensions/extension_util/int_extensions.dart';
import '../extensions/extension_util/widget_extensions.dart';
import '../extensions/app_button.dart';
import '../extensions/common.dart';
import '../extensions/text_styles.dart';
import '../extensions/widgets.dart';
import '../main.dart';
import '../network/rest_api.dart';
import '../utils/app_colors.dart';
import '../utils/app_common.dart';
import 'forgot_pwd_reset_screen.dart';

class ForgotPwdOtpScreen extends StatefulWidget {
  final String email;

  const ForgotPwdOtpScreen({super.key, required this.email});

  @override
  State<ForgotPwdOtpScreen> createState() => _ForgotPwdOtpScreenState();
}

class _ForgotPwdOtpScreenState extends State<ForgotPwdOtpScreen> {
  String otpCode = '';

  Future<void> _continueToReset() async {
    hideKeyboard(context);

    if (otpCode.trim().length != 6) {
      toast('Please enter the 6-digit OTP');
      return;
    }

    ForgotPwdResetScreen(
      email: widget.email,
      otp: otpCode.trim(),
    ).launch(context);
  }

  Future<void> _resendOtp() async {
    hideKeyboard(context);
    appStore.setLoading(true);

    await forgotPwdApi({'email': widget.email}).then((value) {
      toast(value.message);
    }).catchError((error) {
      toast(error.toString());
    }).whenComplete(() {
      appStore.setLoading(false);
    });
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(languages.lblVerifyOTP,
                        style: boldTextStyle(size: 22)),
                    12.height,
                    Text(
                      'Enter the OTP sent to ${widget.email}',
                      style: secondaryTextStyle(),
                    ),
                    30.height,
                    Pinput(
                      length: 6,
                      defaultPinTheme: PinTheme(
                        width: context.width() * 0.12,
                        height: 54,
                        textStyle: primaryTextStyle(size: 20),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ).copyWith(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                      ),
                      focusedPinTheme: PinTheme(
                        width: context.width() * 0.12,
                        height: 54,
                        textStyle: primaryTextStyle(size: 20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: primaryColor, width: 2),
                        ),
                      ).copyWith(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                      ),
                      onChanged: (value) {
                        otpCode = value;
                      },
                      onCompleted: (value) {
                        otpCode = value;
                      },
                    ).center(),
                    30.height,
                    AppButton(
                      text: languages.lblContinue,
                      width: context.width(),
                      color: primaryColor,
                      onTap: _continueToReset,
                    ),
                    16.height,
                    TextButton(
                      onPressed: _resendOtp,
                      child: Text(
                        'Resend OTP',
                        style: primaryTextStyle(color: primaryColor),
                      ),
                    ).center(),
                  ],
                ).paddingSymmetric(horizontal: 16),
              ),
              Loader().visible(appStore.isLoading),
            ],
          );
        },
      ),
    );
  }
}
