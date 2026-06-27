import 'dart:ui';
import 'package:crisp_chat/crisp_chat.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mighty_fitness/screens/chatting_image_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mighty_fitness/controllers/home_page_controller/home_page_workout_list_controller.dart';
import 'package:mighty_fitness/models/app_setting_response.dart';
import 'package:mighty_fitness/models/question_answer_model.dart';
import 'package:mighty_fitness/screens/all_gym_video_list.dart';
import 'package:mighty_fitness/screens/attandance_calendar.dart';
import 'package:mighty_fitness/screens/diet_list_screen.dart';
import 'package:mighty_fitness/screens/free_trial_autopay_subscription_screen.dart';
import 'package:mighty_fitness/screens/shop_screen.dart';
import '../components/double_back_to_close_app.dart';
import '../components/permission.dart';
import '../extensions/LiveStream.dart';
import '../extensions/constants.dart';
import '../extensions/shared_pref.dart';
import '../main.dart';
import '../models/bottom_bar_item_model.dart';
import '../network/rest_api.dart';
import '../utils/app_constants.dart';
import '../utils/app_common.dart';
import '../utils/app_images.dart';
import 'home_screen.dart';
import 'profile_screen.dart';

bool? isFirstTime = false;
AppVersion? app_update_check;

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  final HomePageController homePageController =
      Get.put(HomePageController(), permanent: true);

  int mCurrentIndex = 0;
  late AnimationController _controller;
  late Animation<double> _animation;

  final List<Widget> tab = [
    HomeScreen(),
    DietFilterScreen(),
    ShopScreen(),
    AttendanceCalendarScreen(),
    AllGymVideoList(),
    ProfileScreen(),
  ];

  final List<BottomBarItemModel> bottomItemList = [
    BottomBarItemModel(
        iconData: ic_home_outline,
        selectedIconData: ic_home_fill,
        labelText: languages.lblHome),
    BottomBarItemModel(
        iconData: ic_diet_outline,
        selectedIconData: ic_diet_fill,
        labelText: languages.lblDiet),
    BottomBarItemModel(
        iconData: ic_store_outline,
        selectedIconData: ic_store_fill,
        labelText: languages.lblShop),
    BottomBarItemModel(
        iconData: ic_schedule,
        selectedIconData: ic_fill_schedule,
        labelText: languages.lblSchedule),
    BottomBarItemModel(
        iconData: ic_video_outline,
        selectedIconData: ic_video_fill,
        labelText: "Gym List"),
    BottomBarItemModel(
        iconData: ic_user,
        selectedIconData: ic_user_fill_icon,
        labelText: languages.lblProfile),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    init();
    LiveStream().on("LANGUAGE", (_) => setState(() {}));
  }

  Future<void> init() async {
    PlatformDispatcher.instance.onPlatformBrightnessChanged = () {
      if (getIntAsync(THEME_MODE_INDEX) == ThemeModeSystem) {
        appStore.setDarkMode(
          MediaQuery.of(context).platformBrightness == Brightness.dark,
        );
      }
    };

    if (userStore.userId > 0) {
      await getUSerDetail(context, userStore.userId);
    }

    await getSettingList();
    getFitBotListApiCall();
    Permissions.activityPermissionsGranted();
  }

  Future<void> getSettingList() async {
    try {
      final value = await getSettingApi();
      if (value == null) return;

      for (final data in value.data ?? []) {
        if (data.key == "CHATGPT_API_KEY") {
          userStore.setChatGptApiKey(data.value.validate());
        }
      }
    } catch (_) {}
  }

  Future<void> getFitBotListApiCall() async {
    final value = await getFitBotList();
    if (value == null) return;

    value.data?.reversed.forEach((data) {
      questionAnswers.insert(
        0,
        QuestionImageAnswerModel(
          question: data.question,
          imageUri: "",
          answer: StringBuffer(data.answer ?? ""),
          isLoading: false,
          smartCompose: '',
        ),
      );
    });
  }

  Future<void> _openWhatsApp() async {
    final uri = Uri.parse(
        "https://wa.me/+918879232755?text=${Uri.encodeComponent("Hello, I need support")}");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildBottomItem(int index) {
    final cs = Theme.of(context).colorScheme;
    final isSelected = index == mCurrentIndex;

    final iconPath = isSelected
        ? bottomItemList[index].selectedIconData
        : bottomItemList[index].iconData;

    return GestureDetector(
      onTap: () => setState(() => mCurrentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? cs.primary.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              iconPath!,
              height: 20,
              color: cs.onSurface,
            ),
            const SizedBox(height: 4),
            Text(
              bottomItemList[index].labelText!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.roboto(
                fontSize: 10,
                color: cs.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (!hasPremiumSubscriptionAccess(includeCachedAccess: false)) {
      return const FreeTrialAutoPaySubscriptionScreen();
    }

    return Scaffold(
      body: DoubleBackToCloseApp(
        snackBar: SnackBar(
          backgroundColor: cs.surface,
          content: Text(
            languages.lblTapBackAgainToLeave,
            style: TextStyle(color: cs.onSurface),
          ),
        ),
        child: tab[mCurrentIndex],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "whatsapp_fab",
        backgroundColor: const Color(0xFF25D366), // WhatsApp green
        elevation: 6,
        onPressed: _openWhatsApp,
        child: const FaIcon(
          FontAwesomeIcons.whatsapp,
          color: Colors.white,
          size: 28, // favicon-like perfect size
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border.all(
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
              child: Row(
                children: List.generate(
                  bottomItemList.length,
                  (i) => Expanded(child: _buildBottomItem(i)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// ================= CRISP =================
void configureCrispChat() async {
  FlutterCrispChat.setSessionString(
    key: "user_id",
    value: userStore.userId.toString(),
  );
}
