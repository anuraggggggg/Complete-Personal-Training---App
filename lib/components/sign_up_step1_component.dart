import 'package:flutter/material.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:mighty_fitness/utils/app_config.dart';
import '../extensions/common.dart';
import '../extensions/shared_pref.dart';
import '../../extensions/extension_util/context_extensions.dart';
import '../../extensions/extension_util/int_extensions.dart';
import '../../extensions/extension_util/widget_extensions.dart';
import '../../screens/privacy_policy_screen.dart';
import '../../screens/sign_in_screen.dart';
import '../../screens/terms_and_conditions_screen.dart';
import '../extensions/app_button.dart';
import '../extensions/app_text_field.dart';
import '../extensions/decorations.dart';
import '../extensions/text_styles.dart';
import '../main.dart';
import '../utils/app_colors.dart';
import '../utils/app_common.dart';
import '../utils/app_constants.dart';

class SignUpStep1Component extends StatefulWidget {
  final bool? isNewTask;
  const SignUpStep1Component({this.isNewTask = false, super.key});

  @override
  State<SignUpStep1Component> createState() => _SignUpStep1ComponentState();
}

class _SignUpStep1ComponentState extends State<SignUpStep1Component> {
  final GlobalKey<FormState> mFormKey = GlobalKey<FormState>();

  String? dialCode;
  final mFNameCont = TextEditingController();
  final mLNameCont = TextEditingController();
  final mEmailCont = TextEditingController();
  final mPassCont = TextEditingController();
  final mConfirmPassCont = TextEditingController();
  final mMobileNumberCont = TextEditingController();

  final mEmailFocus = FocusNode();
  final mPassFocus = FocusNode();
  final mFNameFocus = FocusNode();
  final mLNameFocus = FocusNode();
  final mConfirmPassFocus = FocusNode();
  final mMobileNumberFocus = FocusNode();
  bool _hasAcceptedLegal = false;

  @override
  void initState() {
    super.initState();
    _hasAcceptedLegal = getBoolAsync(ACCEPTED_TERMS, defaultValue: false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Form(
        key: mFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// TITLE
            Text(
              languages.lblTellUsAboutYourself,
              style: boldTextStyle(
                size: 22,
                color: cs.onBackground,
              ),
            ),

            16.height,

            /// FIRST NAME
            Text(languages.lblFirstName,
                style: secondaryTextStyle(color: cs.onSurface)),
            4.height,
            AppTextField(
              controller: mFNameCont,
              textFieldType: TextFieldType.NAME,
              focus: mFNameFocus,
              nextFocus: mLNameFocus,
              decoration:
                  defaultInputDecoration(context, label: languages.lblEnterFirstName),
            ),

            16.height,

            /// LAST NAME
            Text(languages.lblLastName,
                style: secondaryTextStyle(color: cs.onSurface)),
            4.height,
            AppTextField(
              controller: mLNameCont,
              textFieldType: TextFieldType.NAME,
              focus: mLNameFocus,
              nextFocus: mMobileNumberFocus,
              decoration:
                  defaultInputDecoration(context, label: languages.lblEnterLastName),
            ),

            16.height,

            /// PHONE
            Text(languages.lblPhoneNumber,
                style: secondaryTextStyle(color: cs.onSurface))
                .visible(getBoolAsync(IS_OTP) != true),
            4.height.visible(getBoolAsync(IS_OTP) != true),

            AppTextField(
              controller: mMobileNumberCont,
              textFieldType: TextFieldType.PHONE,
              focus: mMobileNumberFocus,
              nextFocus: mEmailFocus,
              decoration: defaultInputDecoration(
                context,
                label: languages.lblEnterPhoneNumber,
                mPrefix: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CountryCodePicker(
                      initialSelection:
                          getStringAsync(COUNTRY_CODE, defaultValue: countryCode!),
                      showFlag: false,
                      showCountryOnly: false,
                      textStyle: TextStyle(color: cs.onSurface),
                      boxDecoration: BoxDecoration(
                        color: cs.surface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      dialogTextStyle:
                          TextStyle(color: cs.onSurface),
                      searchStyle:
                          TextStyle(color: cs.onSurface),
                      onInit: (c) {
                        dialCode = c?.dialCode;
                        setValue(COUNTRY_CODE, c?.code);
                      },
                      onChanged: (c) {
                        dialCode = c.dialCode;
                        setValue(COUNTRY_CODE, c.code);
                      },
                    ),
                    VerticalDivider(
                      color: cs.onSurface.withOpacity(0.3),
                    ),
                    8.width,
                  ],
                ),
              ),
            ).visible(getBoolAsync(IS_OTP) != true),

            16.height.visible(getBoolAsync(IS_OTP) != true),

            /// EMAIL
            Text(languages.lblEmail,
                style: secondaryTextStyle(color: cs.onSurface)),
            4.height,
            AppTextField(
              controller: mEmailCont,
              textFieldType: TextFieldType.EMAIL,
              focus: mEmailFocus,
              nextFocus: mPassFocus,
              decoration:
                  defaultInputDecoration(context, label: languages.lblEnterEmail),
            ),

            16.height.visible(getBoolAsync(IS_OTP) != true),

            /// PASSWORD
            Text(languages.lblPassword,
                style: secondaryTextStyle(color: cs.onSurface))
                .visible(getBoolAsync(IS_OTP) != true),
            4.height.visible(getBoolAsync(IS_OTP) != true),
            AppTextField(
              controller: mPassCont,
              focus: mPassFocus,
              nextFocus: mConfirmPassFocus,
              textFieldType: TextFieldType.PASSWORD,
              decoration:
                  defaultInputDecoration(context, label: languages.lblEnterPassword),
            ).visible(getBoolAsync(IS_OTP) != true),

            16.height.visible(getBoolAsync(IS_OTP) != true),

            /// CONFIRM PASSWORD
            Text(languages.lblConfirmPassword,
                style: secondaryTextStyle(color: cs.onSurface))
                .visible(getBoolAsync(IS_OTP) != true),
            4.height.visible(getBoolAsync(IS_OTP) != true),
            AppTextField(
              controller: mConfirmPassCont,
              focus: mConfirmPassFocus,
              textFieldType: TextFieldType.PASSWORD,
              decoration: defaultInputDecoration(
                  context, label: languages.lblEnterConfirmPwd),
            ).visible(getBoolAsync(IS_OTP) != true),

            24.height,

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: _hasAcceptedLegal,
                  activeColor: primaryColor,
                  onChanged: (value) async {
                    final isAccepted = value ?? false;
                    await setValue(ACCEPTED_TERMS, isAccepted);
                    setState(() {
                      _hasAcceptedLegal = isAccepted;
                    });
                  },
                ),
                Expanded(
                  child: Wrap(
                    children: [
                      Text(
                        'I agree to the ',
                        style: secondaryTextStyle(
                            color: cs.onSurface, size: 12),
                      ),
                      Text(
                        languages.lblTermsOfServices,
                        style:
                            primaryTextStyle(color: primaryColor, size: 12),
                      ).onTap(() {
                        const TermsAndConditionScreen().launch(context);
                      }),
                      Text(
                        ' and ',
                        style: secondaryTextStyle(
                            color: cs.onSurface, size: 12),
                      ),
                      Text(
                        languages.lblPrivacyPolicy,
                        style:
                            primaryTextStyle(color: primaryColor, size: 12),
                      ).onTap(() {
                        const PrivacyPolicyScreen().launch(context);
                      }),
                      Text(
                        '.',
                        style: secondaryTextStyle(
                            color: cs.onSurface, size: 12),
                      ),
                    ],
                  ).paddingTop(12),
                ),
              ],
            ),

            8.height,

            /// NEXT BUTTON
            AppButton(
              text: languages.lblNext,
              width: context.width(),
              color: primaryColor,
              onTap: () {
                if (!mFormKey.currentState!.validate()) return;
                if (!_hasAcceptedLegal) {
                  toast(
                      'Please accept Terms of Service and Privacy Policy to continue.');
                  return;
                }
                setValue(ACCEPTED_TERMS, true);
                hideKeyboard(context);

                userStore.setFirstName(mFNameCont.text);
                userStore.setLastName(mLNameCont.text);
                userStore.setUserEmail(mEmailCont.text);

                if (getBoolAsync(IS_OTP) != true) {
                  userStore.setUserPassword(mPassCont.text);
                  userStore.setPhoneNo("${dialCode ?? ''}${mMobileNumberCont.text}");
                }

                appStore.signUpIndex = 1;
                setState(() {});
              },
            ),

            24.height,

            /// LOGIN
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  languages.lblAlreadyAccount,
                  style: TextStyle(color: cs.onSurface),
                ),
                GestureDetector(
                  onTap: () => SignInScreen().launch(context),
                  child: Text(
                    languages.lblLogin,
                    style: primaryTextStyle(color: primaryColor),
                  ).paddingLeft(4),
                ),
              ],
            ),
          ],
        ).paddingAll(16),
      ),
    );
  }
}
