import 'dart:async';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:mighty_fitness/controllers/home_page_controller/home_page_workout_list_controller.dart';
import 'package:mighty_fitness/extensions/shared_pref.dart';
import 'package:mighty_fitness/models/home_page_workout_list_request.dart';
import 'package:mighty_fitness/screens/exercise_detail_screen.dart';
import 'package:mighty_fitness/main.dart';
import 'package:mighty_fitness/screens/exercise_detail_widget/video_card.dart';
import 'package:mighty_fitness/screens/flutter_cache_manager.dart';
import 'package:mighty_fitness/screens/home_page_wigets/home_app_bar.dart';
import 'package:mighty_fitness/screens/home_page_wigets/stretching_card.dart';
import 'package:mighty_fitness/screens/home_page_wigets/warm_up_card_widget.dart';
import 'package:mighty_fitness/screens/instant_exercise_preview.dart';
import 'package:mighty_fitness/utils/app_colors.dart';
import 'package:mighty_fitness/utils/app_common.dart';
import 'package:mighty_fitness/utils/app_constants.dart';
import 'package:vibration/vibration.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver, RouteAware {
  late final HomePageController controller;

  bool dialogShown = false;
  bool _imagesPrecached = false;
  bool _hasController = false;
  String? _prefetchedWorkoutKey;

  late ConfettiController _confettiController;
  String _todayKey(int userId) {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    return "TODAY_EXERCISE_ANSWER_${userId}_$today";
  }

  Future<bool> _hasAnsweredToday() async {
    final key = _todayKey(getIntAsync(USER_ID));
    return getBoolAsync(key);
  }

  Future<void> _markAnsweredToday() async {
    final key = _todayKey(getIntAsync(USER_ID));
    await setValue(key, true);
  }

//   void _openLanguageSelectorOnce() {
//   if (controller.languageSheetShown.value) return;

//   controller.languageSheetShown.value = true;
//   _openLanguageSelector();
// }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(
      this,
      ModalRoute.of(context)! as PageRoute,
    );
  }

  @override
  void initState() {
    super.initState();

    /// 🔁 App lifecycle observer
    WidgetsBinding.instance.addObserver(this);

    /// 🎉 Confetti controller
    _confettiController =
        ConfettiController(duration: const Duration(milliseconds: 900));

    /// 🧹 SAFETY: remove old controller if exists (old user case)
    if (Get.isRegistered<HomePageController>()) {
      Get.delete<HomePageController>(force: true);
    }

    /// ✅ CREATE FRESH CONTROLLER (PER USER)
    controller = Get.put(
      HomePageController(),
      permanent: false, // 🔥 VERY IMPORTANT
    );
    _hasController = true;

    /// 🚀 FORCE FRESH API FOR CURRENT USER
    controller.fetchHomePageData(force: true);

    /// 🌐 LANGUAGE CHANGE LISTENER
    ever<String>(controller.selectedLangCode, (lang) {
      debugPrint("🌐 Language changed → refreshing HomeScreen ($lang)");
      controller.fetchHomePageData(force: true);
    });

    /// ⏱️ POST FRAME TASKS
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowYesNoDialog();
    });

    /// 🧠 DEBUG (OPTIONAL – remove later)
    debugPrint("🏠 HomeScreen init → USER_ID = ${getIntAsync(USER_ID)}");
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_hasController) return;
    if (state == AppLifecycleState.resumed) {
      debugPrint("🔄 HomeScreen resumed → refreshing");
      controller.fetchHomePageData();
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _confettiController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    if (!_hasController) return;
    debugPrint("🔄 Back to Home → refreshing");
    controller.safeRefresh(); // ya fetchHomePageData()
  }

  // ------------------------------------------------
  // YES / NO DIALOG
  // ------------------------------------------------
  void _scheduleWorkoutGifPrefetch(WorkoutsForToday today) {
    final sampleUrls =
        today.exercises.map((ex) => ex.homePreviewUrl).take(3).join("|");
    final key = "${today.workoutId}_${today.exercises.length}_$sampleUrls";
    if (_imagesPrecached && _prefetchedWorkoutKey == key) return;

    _imagesPrecached = true;
    _prefetchedWorkoutKey = key;
    unawaited(_prefetchWorkoutGifs(today));
  }

  Future<void> _prefetchWorkoutGifs(WorkoutsForToday today) async {
    final urls = today.exercises
        .map((ex) => (ex.exerciseGif ?? "").trim())
        .where((url) => url.isNotEmpty)
        .toSet()
        .take(10)
        .toList();

    if (urls.isEmpty) return;

    Future<void> warm(String url) async {
      try {
        await FastGifCacheManager.instance.downloadFile(url);
      } catch (_) {
        // Ignore cache warm-up failures; preview widget handles fallback.
      }
    }

    final immediate = urls.take(3).toList();
    final delayed = urls.skip(3).toList();

    // Phase 1: First visible cards should become ready ASAP.
    await Future.wait(immediate.map(warm));

    // Phase 2: Warm remaining gifs in background with small stagger.
    for (var i = 0; i < delayed.length; i++) {
      await Future.delayed(Duration(milliseconds: 180 * (i + 1)));
      unawaited(warm(delayed[i]));
    }
  }

  void _maybeShowYesNoDialog() async {
    if (!hasPremiumSubscriptionAccess() || !_hasController) return;
    final alreadyAnswered = await _hasAnsweredToday();

    if (alreadyAnswered) {
      debugPrint("✅ Today’s exercise dialog already answered");
      return;
    }

    _showYesNoDialog();
  }

  void _showYesNoDialog() {
    final cs = Theme.of(context).colorScheme;

    Get.dialog(
      AlertDialog(
        backgroundColor: cs.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          "Do you want to do today's exercise?",
          style: GoogleFonts.montserrat(
            color: cs.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          "If you choose NO, today's exercises will be hidden for 24 hours.",
          style: GoogleFonts.montserrat(
            color: cs.onSurface.withOpacity(0.7),
            fontSize: 13,
          ),
        ),
        actions: [
          /// ❌ NO
          TextButton(
            onPressed: () async {
              // save user choice (backend / local)
              await controller.saveSkipTodayChoice(false);

              // 🔐 mark dialog as already answered (USER-SPECIFIC)
              await setValue(
                "HAS_ASKED_TODAY_EXERCISE_${getIntAsync(USER_ID)}",
                true,
              );

              // refresh data
              controller.fetchHomePageData(force: true);

              Get.back();
            },
            child: Text(
              "NO",
              style: GoogleFonts.montserrat(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          /// ✅ YES
          ElevatedButton(
            onPressed: () async {
              await controller.saveSkipTodayChoice(true);

              // 🔒 lock dialog for today
              await _markAnsweredToday();

              controller.fetchHomePageData(force: true);
              Get.back();
            },
            child: const Text("YES"),
          ),
        ],
      ),
      barrierDismissible: false, // ❌ user must choose
    );
  }

  // ------------------------------------------------
  // MAIN BUILD
  // ------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        appBar: const HomeAppBar(),
        body: Stack(
          children: [
            Obx(() => _body(cs)),
            Obx(() => controller.isLoading.value
                ? const Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: LinearProgressIndicator(
                      minHeight: 2,
                    ),
                  )
                : const SizedBox()),
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,

                /// 💥 EK BAAR ME PHATNE WALA BLAST
                blastDirectionality: BlastDirectionality.explosive,

                /// ❌ loop band (sirf ek baar)
                shouldLoop: false,

                /// 🔥 ek hi burst – spray nahi
                emissionFrequency: 0.01,

                /// 🎆 BOHOT ZYADA PARTICLES (atishbaji feel)
                numberOfParticles: 300,

                /// 🚀 ROCKET TYPE FORCE
                maxBlastForce: 70,
                minBlastForce: 45,

                /// ⬇ thoda slow girne do (sky feel)
                gravity: 0.18,

                /// 🎨 BRIGHT FIREWORK COLORS
                colors: const [
                  Colors.red,
                  Colors.orange,
                  Colors.yellow,
                  Colors.white,
                  Colors.blue,
                  Colors.purple,
                ],
              ),
            ),
            Positioned(
              bottom: 80,
              right: 20,
              child: FloatingActionButton.extended(
                backgroundColor: primaryColor,
                icon: const Icon(
                  Icons.public,
                  size: 18,
                  color: Colors.white,
                ),
                label: Text(
                  "Language",
                  style: GoogleFonts.poppins(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                onPressed: _openLanguageSelector,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(ColorScheme cs) {
    // ================= ERROR UI =================
    if (controller.errorMessage.value.isNotEmpty &&
        controller.homePageData == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ❌ Icon hata diya
              // ✅ Payment Failed GIF
              SizedBox(
                width: 140,
                height: 140,
                child: Lottie.asset(
                  'assets/Payment Failed.json',
                  repeat: true,
                  animate: true,
                ),
              ),

              Text(
                controller.errorMessage.value,
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface.withOpacity(0.8),
                ),
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: () {
                  controller.fetchHomePageData(force: true);
                },
                child: const Text(
                  "Retry",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ================= LOADING =================
    if (controller.isLoading.value && controller.homePageData == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: primaryColor),
            const SizedBox(height: 12),
            Text(
              "Loading your workout…",
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w600,
                color: cs.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      );
    }

//   ================= WORKOUT COMPLETED SUCCESS =================
// if (controller.isWorkoutCompleted.value) {
//   return Center(
//     child: Column(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Container(
//           width: 90,
//           height: 90,
//           decoration: BoxDecoration(
//             shape: BoxShape.circle,
//             color: Colors.green.withOpacity(0.12),
//           ),
//           child: Center(
//             child: Lottie.asset(
//               'assets/checkmark.json',
//               width: 170,
//               height: 170,
//               repeat: true,
//               animate: true,
//             ),
//           ),
//         ),
//         const SizedBox(height: 16),
//         Text(
//           "Workout Completed!",
//           style: GoogleFonts.montserrat(
//             fontSize: 18,
//             fontWeight: FontWeight.w800,
//             color: cs.onSurface,
//           ),
//         ),
//         const SizedBox(height: 8),
//         Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 36),
//           child: Text(
//             "Great job! You’ve successfully completed today’s workout.\n\n"
//             "Take some time to rest, hydrate yourself,\n"
//             "and come back even stronger tomorrow 💪",
//             textAlign: TextAlign.center,
//             style: GoogleFonts.montserrat(
//               fontSize: 14.5,
//               height: 1.6,
//               fontWeight: FontWeight.w500,
//               color: cs.onSurface.withOpacity(0.7),
//             ),
//           ),
//         ),
//       ],
//     ),
//   );
// }

    // ================= SHOW WORKOUT UI =================
    final homeData = controller.homePageData;
    if (homeData != null && homeData.workoutsForToday.isNotEmpty) {
      final todayWorkout = homeData.workoutsForToday.first;
      _scheduleWorkoutGifPrefetch(todayWorkout);

      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: _showWorkoutUI(todayWorkout, cs),
      );
    }

    // 👇 Default fallback
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /// 🎞 NO DATA ANIMATION (SMALLER)
            SizedBox(
              height: 130, // ⬅️ pehle 180
              width: 130,
              child: Lottie.asset(
                'assets/No-Data (1).json',
                repeat: true,
                animate: true,
              ),
            ),

            const SizedBox(height: 14),

            /// 🏋️ HEADLINE (SMALLER)
            Text(
              "No Workout Today",
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 16, // ⬅️ pehle 18
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),

            const SizedBox(height: 6),

            /// 💬 SUBTEXT (COMPACT)
            Text(
              "You don’t have any workouts scheduled right now.\nPlease check again later 💪",
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 13, // ⬅️ pehle 14
                height: 1.45,
                fontWeight: FontWeight.w500,
                color: cs.onSurface.withOpacity(0.6),
              ),
            ),

            const SizedBox(height: 16),

            /// 🔄 REFRESH (OPTIONAL & SMALL)
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: cs.primary,
                side: BorderSide(color: cs.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              onPressed: () {
                controller.fetchHomePageData(force: true);
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text(
                "Refresh",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------
  // SHOW WORKOUT UI
  // ------------------------------------------------
  Widget _showWorkoutUI(WorkoutsForToday today, ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Today's ${today.workoutName}",
          style: GoogleFonts.montserrat(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 20),
        _warmupCard(today),
        const SizedBox(height: 16),
        ...today.exercises.map(_exerciseCard),
        const SizedBox(height: 16),
        StretchingCard(today: today),
        const SizedBox(height: 24),
        Obx(
          () => controller.isWorkoutCompleted.value
              ? _completedBox()
              : _attendanceButton(today.workoutId ?? 0),
        ),
      ],
    );
  }

  // ------------------------------------------------
  // EXERCISE CARD
  // ------------------------------------------------
  String _exerciseDisplayName(Exercises ex) {
    final exerciseTitle = (ex.exerciseTitle ?? '').trim();
    if (exerciseTitle.isNotEmpty) return exerciseTitle;

    final title = (ex.title ?? '').trim();
    if (title.isNotEmpty) return title;

    return 'Chest Press Machine';
  }

  Widget _exerciseCard(Exercises ex) {
    final cs = Theme.of(context).colorScheme;
    final exerciseName = _exerciseDisplayName(ex);

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        debugPrint("▶️ selectedVideoUrl: ${ex.selectedVideoUrl}");

        Get.to(
          () => ExerciseDetailsScreen(
            exercise: ex,
            id: ex.id ?? 0,
            name: exerciseName,
            videoPath: ex.selectedVideoUrl ?? "",
            instruction: ex.instruction ?? "",
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 18),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: cs.onSurface.withOpacity(0.12),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            /// 🏋️ EXERCISE NAME
            Expanded(
              child: Text(
                exerciseName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.montserrat(
                  color: cs.onSurface,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ),

            const SizedBox(width: 16),

            /// 🎞 BIGGER GIF / IMAGE PREVIEW
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: 75,
                height: 75,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: InstantExercisePreview(
                  url: ex.homePreviewUrl,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------
// BUTTONS
// ------------------------------------------------
  Widget _attendanceButton(int workoutId) {
    return Center(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: () async {
          // ❌ double tap safety
          if (controller.isWorkoutCompleted.value) return;

          // ✅ mark workout complete (API + state)
          await controller.markWorkoutComplete(workoutId);

          // ===================== 💥 DHAMAKA START =====================

          /// 🎉 CONFETTI BLAST
          _confettiController.play();

          /// 📳 STRONG VIBRATION (ANDROID – FULL POWER)
          if (await Vibration.hasVibrator() ?? false) {
            if (await Vibration.hasAmplitudeControl() ?? false) {
              // 🔥 High intensity vibration pattern
              Vibration.vibrate(
                pattern: [
                  0,
                  600,
                  120,
                  600,
                  120,
                  600,
                ],
                intensities: [
                  255,
                  255,
                  255,
                ],
              );
            } else {
              // fallback
              Vibration.vibrate(duration: 600);
            }
          }

          /// 💥 HAPTIC FEEDBACK (iOS + Android)
          HapticFeedback.heavyImpact();
          HapticFeedback.vibrate();

          /// 🔊 SYSTEM CLICK (extra punch)
          SystemSound.play(SystemSoundType.click);

          // ===================== 💥 DHAMAKA END =====================
        },
        child: Text(
          "Complete Your Attendance",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _completedBox() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: Text(
          "Workout Completed ✔",
          style: TextStyle(
              color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // ------------------------------------------------
  // WARMUP & STRETCHING
  // ------------------------------------------------
  Widget _warmupCard(WorkoutsForToday workout) {
    final warmupUrl = workout.warmupVideo ?? "";

    // 🛑 safety: agar warmup video hi nahi hai
    if (warmupUrl.isEmpty) {
      return const SizedBox.shrink();
    }

    return AnimatedWarmupCard(
      video: warmupUrl,
      onTap: () {
        Get.to(
          () => Scaffold(
            backgroundColor: Colors.black,
            body: SafeArea(
              child: VideoCard(
                // 👇 Warm-up me actual exercise nahi hota
                exercise: Exercises.empty(),

                // 🔥 YAHIN warmup video inject hota hai
                overrideVideo: warmupUrl,
              ),
            ),
          ),
          transition: Transition.fadeIn,
          duration: const Duration(milliseconds: 220),
        );
      },
    );
  }

  // ------------------------------------------------
  // LANGUAGE BOTTOM SHEET
  // ------------------------------------------------
  void _openLanguageSelector() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // 🔁 THEME FLIP
    final sheetBg = isDark ? Colors.white : const Color(0xFF121212);
    final textColor = isDark ? Colors.black87 : Colors.white;
    final subTextColor = isDark ? Colors.black54 : Colors.white70;
    final tileBg = isDark ? Colors.grey.shade100 : const Color(0xFF1E1E1E);
    final borderColor = isDark ? Colors.grey.shade300 : Colors.white12;

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
        decoration: BoxDecoration(
          color: sheetBg,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(28),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 18,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              /// ── Drag Handle ──
              Container(
                height: 4,
                width: 42,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              /// ── Title ──
              Text(
                "Select Language",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                "Choose your preferred language",
                style: theme.textTheme.bodySmall?.copyWith(
                  color: subTextColor,
                ),
              ),

              const SizedBox(height: 18),

              /// ── Language List ──
              ...controller.filteredLanguages.map((lang) {
                final selected =
                    controller.selectedLangCode.value == lang.languageCode;

                IconData langIcon = Icons.language;
                if (lang.languageName == "Hindi") {
                  langIcon = Icons.translate;
                } else if (lang.languageName == "Spanish") {
                  langIcon = Icons.public;
                }

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.red.withOpacity(isDark ? 0.12 : 0.18)
                        : tileBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: selected ? Colors.redAccent : borderColor,
                      width: 1.2,
                    ),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.2),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ]
                        : [],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    leading: Container(
                      height: 38,
                      width: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selected
                            ? Colors.red.withOpacity(0.2)
                            : isDark
                                ? Colors.grey.shade200
                                : Colors.grey.shade800,
                      ),
                      child: Icon(
                        langIcon,
                        color: selected
                            ? Colors.redAccent
                            : textColor.withOpacity(0.7),
                        size: 20,
                      ),
                    ),
                    title: Text(
                      (lang.languageName ?? "").split(' ').first,
                      style: TextStyle(
                        fontWeight:
                            selected ? FontWeight.bold : FontWeight.w600,
                        color: selected ? Colors.redAccent : textColor,
                      ),
                    ),
                    trailing: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: selected
                          ? const Icon(
                              Icons.check_circle,
                              key: ValueKey(true),
                              color: Colors.redAccent,
                              size: 22,
                            )
                          : const SizedBox(
                              key: ValueKey(false),
                              width: 22,
                            ),
                    ),
                    onTap: () {
                      controller.updateLanguage(
                        lang.languageCode ?? "",
                        lang.id ?? 1,
                      );
                      Get.back();
                    },
                  ),
                );
              }),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }
}
