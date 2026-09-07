import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get/get.dart';
import 'package:mighty_fitness/Chat/model/file_model.dart';
import 'package:mighty_fitness/controllers/apply_coupon_controller/access_gate_controller.dart';
import 'package:mighty_fitness/controllers/circuite_exercise_controller/circuite_exercise_controller.dart';
import 'package:mighty_fitness/controllers/translator_controller/translator_controller.dart';
import 'package:mighty_fitness/controllers/workout_mode_update_controller/workout_mode_controller.dart';
import 'package:mighty_fitness/features/shop/viewmodels/shop_view_model.dart';
import 'package:mighty_fitness/languageConfiguration/AppLocalizations.dart';
import 'package:mighty_fitness/languageConfiguration/BaseLanguage.dart';
import 'package:mighty_fitness/languageConfiguration/LanguageDataConstant.dart';
import 'package:mighty_fitness/languageConfiguration/LanguageDefaultJson.dart';
import 'package:mighty_fitness/languageConfiguration/ServerLanguageResponse.dart';
import 'package:mighty_fitness/security/screen_security_service.dart';
import 'package:mighty_fitness/security/secure_screen.dart';
import 'package:mighty_fitness/service/chat_message_service.dart';
import 'package:mighty_fitness/service/user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../extensions/extension_util/string_extensions.dart';
import '../../extensions/system_utils.dart';
import '../../store/app_store.dart';
import 'app_theme.dart';
import 'extensions/constants.dart';
import 'extensions/decorations.dart';
import 'screens/splash_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/complete_profile_screen.dart';
import 'screens/free_trial_autopay_subscription_screen.dart';
import 'store/UserStore/UserStore.dart';
import 'utils/app_common.dart';
import 'utils/app_config.dart';
import 'utils/app_constants.dart';

AppStore appStore = AppStore();
UserStore userStore = UserStore();
ChatMessageService chatMessageService = ChatMessageService();
LanguageJsonData? selectedServerLanguageData;
List<LanguageJsonData>? defaultServerLanguageData = [];
late Size mq;
late SharedPreferences sharedPreferences;
final navigatorKey = GlobalKey<NavigatorState>();
late BaseLanguage languages;
UserService userService = UserService();
late List<FileModel> fileList = [];
bool mIsEnterKey = false;
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

Future<void> main() async {
  await runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        log('FlutterError: ${details.exceptionAsString()}');
        log(details.stack);
      };
      PlatformDispatcher.instance.onError = (error, stack) {
        log('PlatformDispatcherError: $error');
        log(stack);
        return true;
      };

      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
      await ScreenSecurityService.instance.enableProtection();
      await Firebase.initializeApp();

      Get.put(WorkoutModeUpdateController(), permanent: true);
      Get.put(CircularWorkoutController(), permanent: true);
      Get.put(TranslatorController(), permanent: true);
      Get.put(AccessGateController(), permanent: true);

      sharedPreferences = await SharedPreferences.getInstance();

      if (Platform.isIOS &&
          (sharedPreferences.getString(TOKEN)?.trim().isNotEmpty ?? false)) {
        Get.put(ShopViewModel(), permanent: true);
      }

      userStore.addAllProgressSettingsListItem(progressSettingList());

      appStore.setLanguage(
        sharedPreferences.getString(SELECTED_LANGUAGE_CODE) ??
            defaultLanguageCode,
      );

      initJsonFile();
      setLogInValue();

      defaultAppButtonShapeBorder = RoundedRectangleBorder(
        borderRadius: radius(defaultAppButtonRadius),
      );

      final int savedThemeMode =
          sharedPreferences.getInt(THEME_MODE_INDEX) ?? ThemeModeSystem;
      final bool isDarkMode = savedThemeMode == ThemeModeSystem
          ? WidgetsBinding.instance.platformDispatcher.platformBrightness ==
              Brightness.dark
          : sharedPreferences.getBool('isDarkMode') ??
              savedThemeMode == ThemeModeDark;
      await appStore.applyThemeSelection(
        savedThemeMode,
        platformBrightness: isDarkMode ? Brightness.dark : Brightness.light,
      );

      runApp(const MyApp());
    },
    (error, stack) {
      log('runZonedGuarded: $error');
      log(stack);
    },
  );
}

/// ================= APP =================
class MyApp extends StatefulWidget {
  const MyApp({super.key});
  static String tag = '/MyApp';

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  VoidCallback? _removeScreenshotListener;

  @override
  void initState() {
    super.initState();
    _removeScreenshotListener =
        ScreenSecurityService.instance.addScreenshotListener(
      _showScreenshotWarning,
    );
  }

  void _showScreenshotWarning() {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      const SnackBar(
        content: Text('Screen capture is not allowed in this app.'),
      ),
    );
  }

  @override
  void dispose() {
    _removeScreenshotListener?.call();
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        return GetMaterialApp(
          navigatorObservers: [routeObserver],
          navigatorKey: navigatorKey,
          builder: (context, child) {
            return ScreenSecurityOverlay(
              child: child ?? const SizedBox.shrink(),
            );
          },
          title: APP_NAME,
          debugShowCheckedModeBanner: false,
          scrollBehavior: SBehavior(),

          /// 🌗 THEMES
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: appStore.isDarkMode ? ThemeMode.dark : ThemeMode.light,

          /// 🌍 LOCALIZATION
          localizationsDelegates: const [
            AppLocalizations(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', 'US'),
            Locale('hi', 'IN'),
            Locale('es'),
          ],
          locale: Locale(
            appStore.selectedLanguageCode.validate(value: DEFAULT_LANGUAGE),
          ),

          /// 🧭 ROUTES
          initialRoute: '/',
          getPages: [
            GetPage(
              name: '/',
              page: () => SplashScreen(),
            ),
            GetPage(
              name: '/dashboard',
              page: () => DashboardScreen(),
            ),
            GetPage(
              name: '/complete-profile',
              page: () => const CompleteProfileScreen(),
            ),
            GetPage(
              name: '/subscription-unlock',
              page: () => const FreeTrialAutoPaySubscriptionScreen(),
            ),
          ],
        );
      },
    );
  }
}
