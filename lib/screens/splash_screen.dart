import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mighty_fitness/extensions/constants.dart';
import 'package:mighty_fitness/languageConfiguration/LanguageDataConstant.dart';
import 'package:mighty_fitness/languageConfiguration/ServerLanguageResponse.dart';
import 'package:mighty_fitness/network/rest_api.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../extensions/extension_util/duration_extensions.dart';
import '../../extensions/extension_util/int_extensions.dart';
import '../extensions/shared_pref.dart';
import '../../extensions/extension_util/widget_extensions.dart';
import '../../main.dart';
import '../../utils/app_images.dart';
import '../utils/app_common.dart';
import '../utils/app_constants.dart';
import '../utils/subscription_navigation.dart';
import 'sign_in_screen.dart';
import 'walk_through_screen.dart';

class SplashScreen extends StatefulWidget {
  static String tag = '/SplashScreen';

  const SplashScreen({super.key});

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // init();
    Future.delayed(Duration.zero).then((val) {
      _checkNotifyPermission();
    });
  }

  init() async {
    await 1.seconds.delay;

    final isFirstTime = getBoolAsync(IS_FIRST_TIME);
    final isLoggedIn = getBoolAsync(IS_LOGIN);
    final token = getStringAsync(TOKEN);

    debugPrint(
      "🧠 Splash Check → firstTime=$isFirstTime, "
      "loggedIn=$isLoggedIn, token=${token.isNotEmpty}",
    );

    /// 🆕 FIRST TIME USER
    if (!isFirstTime) {
      WalkThroughScreen().launch(context, isNewTask: true);
      return;
    }

    /// ✅ ALREADY LOGGED IN USER
    if (isLoggedIn == true && token.isNotEmpty) {
      openPostAuthDestination(allowFreeAutopayPrompt: false);
      return;
    }

    /// ❌ NOT LOGGED IN
    SignInScreen().launch(context, isNewTask: true);
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  void _checkNotifyPermission() async {
    String versionNo =
        getStringAsync(CURRENT_LAN_VERSION, defaultValue: LanguageVersion);
    print("---------59>>>$versionNo");
    await getLanguageList(versionNo).then((value) {
      print("---------61>>>${value.data?.length}");
      appStore.setLoading(false);
      if (value.status == true) {
        setValue(CURRENT_LAN_VERSION, value.currentVersionNo.toString());
        if (value.data!.isNotEmpty) {
          defaultServerLanguageData = value.data;
          performLanguageOperation(defaultServerLanguageData);
          setValue(LanguageJsonDataRes, value.toJson());
          bool isSetLanguage =
              sharedPreferences.getBool(IS_SELECTED_LANGUAGE_CHANGE) ?? false;
          if (!isSetLanguage) {
            for (int i = 0; i < value.data!.length; i++) {
              if (value.data![i].isDefaultLanguage == 1) {
                setValue(SELECTED_LANGUAGE_CODE, value.data![i].languageCode);
                setValue(
                    SELECTED_LANGUAGE_COUNTRY_CODE, value.data![i].countryCode);
                appStore.setLanguage(value.data![i].languageCode!,
                    context: context);
                break;
              }
            }
          }
        } else {
          defaultServerLanguageData = [];
          selectedServerLanguageData = null;
          setValue(LanguageJsonDataRes, "");
        }
      } else {
        String getJsonData = getStringAsync(LanguageJsonDataRes);

        if (getJsonData.isNotEmpty) {
          ServerLanguageResponse languageSettings =
              ServerLanguageResponse.fromJson(json.decode(getJsonData.trim()));
          if (languageSettings.data!.isNotEmpty) {
            defaultServerLanguageData = languageSettings.data;
            performLanguageOperation(defaultServerLanguageData);
          }
        }
      }
    }).catchError((error) {
      appStore.setLoading(false);
      // log(error);
    });
    await getSettingData().catchError((_) {});
    if (await Permission.notification.isGranted) {
      init();
    } else {
      await Permission.notification.request();
      init();
    }
  }

  @override
  Widget build(BuildContext context) {
    mq = MediaQuery.of(context).size;
    return AnnotatedRegion(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            appStore.isDarkMode ? Brightness.light : Brightness.dark,
        systemNavigationBarIconBrightness:
            appStore.isDarkMode ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        // backgroundColor: appStore.isDarkMode ? context.scaffoldBackgroundColor : whiteColor,
        body: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                45.height,
                // Image.asset(ic_splash_logo2, fit: BoxFit.fill),
                //  Image.asset(ic_splash_logo, width: 220, height: 140, fit: BoxFit.fill),
                Image.asset(ic_splash_logo,
                    width: 250, height: 250, fit: BoxFit.fill),
                // 16.height,
                // Text(APP_NAME, style: boldTextStyle(size: 26, letterSpacing: 1)),
              ],
            ).center(),
          ],
        ).paddingBottom(10),
      ),
    );
  }
}
