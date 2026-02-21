import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
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
import 'package:mighty_fitness/languageConfiguration/AppLocalizations.dart';
import 'package:mighty_fitness/languageConfiguration/BaseLanguage.dart';
import 'package:mighty_fitness/languageConfiguration/LanguageDataConstant.dart';
import 'package:mighty_fitness/languageConfiguration/LanguageDefaultJson.dart';
import 'package:mighty_fitness/languageConfiguration/ServerLanguageResponse.dart';
import 'package:mighty_fitness/service/chat_message_service.dart';
import 'package:mighty_fitness/service/user_service.dart';
// import 'package:no_screenshot/no_screenshot.dart';
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
import 'store/UserStore/UserStore.dart';
import 'utils/app_common.dart';
import 'utils/app_config.dart';



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
  WidgetsFlutterBinding.ensureInitialized();
    await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);


  Get.put(WorkoutModeUpdateController(), permanent: true);
  Get.put(CircularWorkoutController(), permanent: true);
  Get.put(TranslatorController(), permanent: true);
  Get.put(AccessGateController(), permanent: true);

 
  sharedPreferences = await SharedPreferences.getInstance();

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


  final bool isDarkMode =
      sharedPreferences.getBool('isDarkMode') ?? true;
  appStore.setDarkMode(isDarkMode);

  runApp(const MyApp());
}

/// ================= APP =================
class MyApp extends StatefulWidget {
  const MyApp({super.key});
  static String tag = '/MyApp';

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StreamSubscription<List<ConnectivityResult>>?
      _connectivitySubscription;



  @override
  void initState() {
    super.initState();
  }
  


  @override
  void dispose() {
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
          title: APP_NAME,
          debugShowCheckedModeBanner: false,
          scrollBehavior: SBehavior(),
          /// 🌗 THEMES
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: appStore.isDarkMode
              ? ThemeMode.dark
              : ThemeMode.light,

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
            appStore.selectedLanguageCode
                .validate(value: DEFAULT_LANGUAGE),
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
          ],
        );
      },
    );
  }
}
