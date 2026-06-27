import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mighty_fitness/extensions/common.dart';
import 'package:mighty_fitness/extensions/extension_util/string_extensions.dart';
import 'package:mighty_fitness/extensions/extension_util/widget_extensions.dart';
import 'package:mighty_fitness/network/rest_api.dart';
import '../../main.dart';
import '../../screens/forgot_pwd_screen.dart';
import '../../screens/sign_up_screen.dart';
import '../extensions/app_button.dart';
import '../extensions/app_text_field.dart';
import '../extensions/decorations.dart';
import '../extensions/loader_widget.dart';
import '../extensions/shared_pref.dart';
import '../extensions/text_styles.dart';
import '../service/auth_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_common.dart';
import '../utils/app_constants.dart';
import '../utils/subscription_navigation.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});
  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final GlobalKey<FormState> mFormKey = GlobalKey<FormState>();

  final TextEditingController mEmailCont = TextEditingController();
  final TextEditingController mPassCont = TextEditingController();

  final FocusNode mEmailFocus = FocusNode();
  final FocusNode mPassFocus = FocusNode();

  @override
  void initState() {
    super.initState();

    /// 🔐 AUTH GUARD — agar user already logged-in hai
    final bool isLoggedIn = getBoolAsync(IS_LOGIN);

    if (isLoggedIn) {
      // next frame me redirect (safe navigation)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        openPostAuthDestination(allowFreeAutopayPrompt: false);
      });
      return; // 🔥 very important
    }

    _init();
  }

  Future<void> _init() async {
    await setValue(ACCEPTED_TERMS, false);
    if (getBoolAsync(IS_REMEMBER)) {
      mEmailCont.text = getStringAsync(EMAIL);
      mPassCont.text = getStringAsync(PASSWORD);
    }
    await _getCountryCodeFromLocale();
  }

  Future<void> _save() async {
    hideKeyboard(context);
    if (!mFormKey.currentState!.validate()) return;
    appStore.setLoading(true);

    try {
      final value = await logInApi({
        'email': mEmailCont.text.trim(),
        'username': mEmailCont.text.trim(),
        'password': mPassCont.text.trim(),
        'login_type': LoginTypeApp,
        'user_type': LoginUser,
        'status': statusActive,
        'player_id': getStringAsync(PLAYER_ID).validate(),
      });

      final token = value.data?.apiToken.validate() ?? '';
      if (token.isEmpty) {
        throw 'Login succeeded but no API token was returned.';
      }

      await setValue(TOKEN, token);
      await setValue(IS_LOGIN, true);

      appStore.setLoading(false);
      openPostAuthDestination(allowFreeAutopayPrompt: false);
    } catch (e) {
      appStore.setLoading(false);
      toast(e.toString());
    }
  }

  Future<void> _handleAppleLogin() async {
    final bool didLogin = await appleLogIn();

    if (!mounted) return;

    if (didLogin || getBoolAsync(IS_LOGIN) || userStore.isLoggedIn) {
      openPostAuthDestination(allowFreeAutopayPrompt: false);
    }
  }

  Future<String?> _getCountryCodeFromLocale() async {
    try {
      String localeName = Platform.localeName;
      if (localeName.contains('_')) {
        setValue(COUNTRY_CODE, localeName.split('_').last);
        return localeName.split('_').last;
      }
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final info = await deviceInfo.androidInfo;
        return info.device;
      }
    } catch (_) {}
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool showAppleSignIn = !getBoolAsync(IS_LOGIN) && Platform.isIOS;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            SafeArea(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Form(
                  key: mFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// LOGIN TITLE
                      Text(
                        languages.lblLogin,
                        style: boldTextStyle(
                          size: 18,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: 40,
                        height: 2,
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        languages.lblWelcomeBack,
                        style: boldTextStyle(
                          size: 22,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        languages.lblWelcomeBackDesc,
                        style: secondaryTextStyle(
                          color: cs.onSurface.withOpacity(0.65),
                        ),
                      ),
                      const SizedBox(height: 28),

                      /// EMAIL
                      Text(
                        languages.lblEmail,
                        style: secondaryTextStyle(color: cs.onSurface),
                      ),
                      const SizedBox(height: 6),
                      AppTextField(
                        controller: mEmailCont,
                        focus: mEmailFocus,
                        textFieldType: TextFieldType.EMAIL,
                        nextFocus: mPassFocus,
                        decoration: defaultInputDecoration(
                          context,
                          label: languages.lblEnterEmail,
                        ),
                      ),
                      const SizedBox(height: 16),

                      /// PASSWORD
                      Text(
                        languages.lblPassword,
                        style: secondaryTextStyle(color: cs.onSurface),
                      ),
                      const SizedBox(height: 6),
                      AppTextField(
                        controller: mPassCont,
                        focus: mPassFocus,
                        textFieldType: TextFieldType.PASSWORD,
                        decoration: defaultInputDecoration(
                          context,
                          label: languages.lblEnterPassword,
                        ),
                        onFieldSubmitted: (_) => _save(),
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () {
                            ForgotPwdScreen().launch(context);
                          },
                          child: Text(
                            languages.lblForgotPassword,
                            style: primaryTextStyle(
                              color: primaryColor,
                              weight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      /// LOGIN BUTTON
                      AppButton(
                        text: languages.lblLogin,
                        width: double.infinity,
                        color: primaryColor,
                        onTap: _save,
                      ),
                      const SizedBox(height: 16),

                      /// REGISTER
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            languages.lblNewUser,
                            style: primaryTextStyle(
                              color: cs.onSurface,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              SignUpScreen().launch(context);
                            },
                            child: Text(
                              languages.lblRegisterNow,
                              style: primaryTextStyle(
                                color: primaryColor,
                              ),
                            ).paddingLeft(4),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      /// DIVIDER
                      if (showAppleSignIn) ...[
                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: cs.onSurface.withOpacity(0.2),
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                "OR",
                                style: secondaryTextStyle(
                                  color: cs.onSurface.withOpacity(0.6),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: cs.onSurface.withOpacity(0.2),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: _handleAppleLogin,
                          child: Container(
                            height: 52,
                            decoration: BoxDecoration(
                              color: cs.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: cs.onSurface.withOpacity(0.25),
                              ),
                            ),
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  FaIcon(
                                    FontAwesomeIcons.apple,
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    "Continue with Apple",
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),

            /// LOADER
            Observer(
              builder: (_) => Loader().center().visible(appStore.isLoading),
            ),
          ],
        ),
      ),
    );
  }
}
