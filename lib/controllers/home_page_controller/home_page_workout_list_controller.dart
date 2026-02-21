import 'dart:convert';
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:mighty_fitness/controllers/attendance_controller/attendance_controller.dart';
import 'package:http/http.dart' as http;
import 'package:mighty_fitness/controllers/workout_mode_update_controller/workout_mode_controller.dart';
import 'package:mighty_fitness/models/home_page_error_request_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mighty_fitness/models/home_page_workout_list_request.dart';
import 'package:mighty_fitness/models/language_model.dart';
import 'package:video_player/video_player.dart';

class HomePageController extends GetxController {
  RxBool isLoading = false.obs;
  RxString errorMessage = "".obs;
  RxBool isError = false.obs;
  RxInt errorCode = 0.obs;

  HomePage? homePageData;

  // ------------------- LANGUAGE ----------------------
  RxList<Data> apiLanguageList = <Data>[].obs;
  RxList<Data> filteredLanguages = <Data>[].obs;

  RxString selectedLangCode = "hi".obs;
  RxInt selectedLanguageId = 1.obs;

  // ------------------- SKIP TODAY ----------------------
  // -1 → User not selected
  // 0  → YES (Show workout)
  // 1  → NO (Hide workout)
  RxInt skipToday = (-1).obs;

  // Workout completion
  RxBool isWorkoutCompleted = false.obs;
  bool _initialLoadDone = false;

  // Video cache
  RxMap<String, String> videoThumbCache = <String, String>{}.obs;
  Map<String, VideoPlayerController> videoCache = {};

  final WorkoutModeUpdateController workoutModeController =
      Get.find<WorkoutModeUpdateController>();

  late Worker _workoutModeWorker;

  /// 🔥 CALLED AFTER COUPON / SUBSCRIPTION
  void onCouponApplied() async {
    debugPrint("🔄 Coupon applied → refreshing Home page data");

    // 🔁 Force refresh home data (bypass guards)
    await fetchHomePageData(force: true);
  }

  void safeRefresh() {
    fetchHomePageData(force: true);
  }

  @override
  void onInit() {
    super.onInit();

    loadSavedLanguage();
    fetchLanguageList();

    // ✅ Mark READY first
    loadSkipToday().then((_) async {
      _initialLoadDone = true; // 👈 PEHLE
      await fetchHomePageData(); // 👈 PHIR
    });

    _workoutModeWorker = ever<int>(
      workoutModeController.workoutMode,
      (mode) {
        if (!_initialLoadDone) return; // 🛑 guard

        debugPrint("🏋️ Workout mode changed → $mode");

        Get.snackbar(
          "Workout Mode",
          mode == 1 ? "Gym workout loaded 💪" : "Home workout loaded 🏠",
          snackPosition: SnackPosition.TOP,
          duration: const Duration(milliseconds: 800),
        );

        fetchHomePageData(force: true);
      },
    );
  }

  @override
  void onClose() {
    videoCache.forEach((key, controller) => controller.dispose());

    // 🧹 cleanup
    _workoutModeWorker.dispose();

    super.onClose();
  }

  // =====================================================================
  //                           SKIP TODAY LOGIC
  // =====================================================================

  Future<void> saveSkipTodayChoice(bool showWorkout) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    skipToday.value = showWorkout ? 0 : 1;

    await prefs.setInt("SKIP_TODAY_VALUE", skipToday.value);
    await prefs.setInt(
        "SKIP_TODAY_TIME", DateTime.now().millisecondsSinceEpoch);

    print("✔ Saved skipToday = ${skipToday.value}");
  }

  Future<void> loadSkipToday() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    int? saved = prefs.getInt("SKIP_TODAY_VALUE");
    int? time = prefs.getInt("SKIP_TODAY_TIME");

    if (saved != null && time != null) {
      Duration diff =
          DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(time));

      if (diff.inHours >= 24) {
        skipToday.value = -1; // Ask again next day
        prefs.remove("SKIP_TODAY_VALUE");
        prefs.remove("SKIP_TODAY_TIME");
      } else {
        skipToday.value = saved;
      }
    }

    print("⏳ Loaded skipToday = ${skipToday.value}");
  }

  // =====================================================================
  //                           LANGUAGE MANAGEMENT
  // =====================================================================

  Future<void> loadSavedLanguage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    selectedLangCode.value = prefs.getString("APP_LANGUAGE_CODE") ?? "hi";
    selectedLanguageId.value = prefs.getInt("APP_LANGUAGE_ID") ?? 1;

    print("🌍 Loaded Language: ${selectedLangCode.value}");
  }

  Future<void> updateLanguage(String lang, int id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.setString("APP_LANGUAGE_CODE", lang);
    await prefs.setInt("APP_LANGUAGE_ID", id);

    selectedLangCode.value = lang;
    selectedLanguageId.value = id;

    print("🌐 Updated Language = $lang / $id");
  }

  Future<void> fetchLanguageList() async {
    try {
      var res = await http.get(
        Uri.parse(
            "https://fitness.completepersonaltraining.com/api/language-list"),
      );

      if (res.statusCode == 200) {
        LanguageModel model = LanguageModel.fromJson(json.decode(res.body));

        apiLanguageList.value = model.data ?? [];
        filteredLanguages.value = apiLanguageList;
      }
    } catch (e) {
      print("Language Error: $e");
    }
  }

  // =====================================================================
  //                           FETCH HOME PAGE
  // =====================================================================

  Future<void> fetchHomePageData({bool force = false}) async {
    // 🛑 Guard: already loading
    if (isLoading.value && !force) {
      debugPrint("⏭ fetchHomePageData skipped (already loading)");
      return;
    }

    homePageData = null;
    isLoading.value = true;
    errorMessage.value = "";

    try {
      // ✅ Token
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("TOKEN");

      /// 🔎 SAFE ADD (NO LOGIC CHANGE)
      final userId = prefs.getInt("USER_ID");
      debugPrint("📡 FETCH HOME → userId=$userId");

      if (token == null) {
        errorMessage.value = "User not logged in!";
        debugPrint("❌ TOKEN NULL");
        return;
      }

      // ======================================================
      // 🏋️ WORKOUT MODE AWARE API
      // ======================================================
      final mode = workoutModeController.workoutMode.value;
      debugPrint(
        "🧠 STATE → mode=$mode, "
        "lang=${selectedLanguageId.value}, skip=${skipToday.value}",
      );

      final baseUrl =
          "https://fitness.completepersonaltraining.com/api/user/workouts";

      final finalUrl = "$baseUrl?lang=${selectedLanguageId.value}"
          "&skip_today=${skipToday.value}"
          "&mode=$mode";

      debugPrint("📡 FETCH [$mode] → $finalUrl");

      // ======================================================
      // 🌐 API CALL
      // ======================================================
      final response = await http.get(
        Uri.parse(finalUrl),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      debugPrint("📡 STATUS → ${response.statusCode}");

      // ======================================================
      // ❌ ERROR HANDLING (NO STRUCTURE CHANGE)
      // ======================================================
      if (response.statusCode != 200) {
        try {
          final decodedError = json.decode(response.body);

          if (decodedError is Map<String, dynamic> &&
              decodedError.containsKey("message")) {
            errorMessage.value = decodedError["message"] ?? "Server error";
          } else {
            errorMessage.value = "Server error (${response.statusCode})";
          }
        } catch (_) {
          errorMessage.value = "Server error (${response.statusCode})";
        }

        debugPrint("❌ API ERROR: ${errorMessage.value}");
        return;
      }

      // ======================================================
      // 📦 PARSE RESPONSE
      // ======================================================
      final decoded = json.decode(response.body);
      homePageData = HomePage.fromJson(decoded);

      final workouts = homePageData?.workoutsForToday;

      if (workouts != null && workouts.isNotEmpty) {
        debugPrint("🏋️ WORKOUT COUNT: ${workouts.length}");

        // ✅ sync completion state
        await checkWorkoutCompletion(
          workouts.first.workoutId ?? 0,
        );
      } else {
        debugPrint("⚠️ NO WORKOUTS FOR TODAY");
        isWorkoutCompleted.value = false;
      }
    } catch (e, s) {
      debugPrint("🔥 ERROR fetchHomePageData: $e");
      debugPrint("📌 STACKTRACE: $s");

      errorMessage.value = "Network error. Please try again.";
    } finally {
      // ✅ ALWAYS turn off loader
      isLoading.value = false;
    }
  }

  void _handleApiError(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);

      final error = HomePageErrorRequest.fromJson(decoded);

      errorMessage.value = error.message;
    } catch (_) {
      errorMessage.value = "Unexpected server error (${response.statusCode})";
    }

    errorCode.value = response.statusCode;
    isError.value = true;
  }

  // =====================================================================
  //                         WORKOUT COMPLETION
  // =====================================================================

  Future<void> checkWorkoutCompletion(int workoutId) async {
    if (workoutId == 0) {
      isWorkoutCompleted.value = false;
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? saved = prefs.getInt("WORKOUT_MARK_TIME_$workoutId");

    if (saved == null) {
      isWorkoutCompleted.value = false;
      return;
    }

    Duration diff =
        DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(saved));

    isWorkoutCompleted.value = diff.inHours < 2;
  }

  // =====================================================================
  //                       MARK WORKOUT DONE
  // =====================================================================

  Future<void> markWorkoutComplete(int workoutId) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int? userId = prefs.getInt("USER_ID");
      if (userId == null) return;

      Map<String, dynamic> body = {"user_id": userId, "workout_id": workoutId};

      var res = await http.post(
        Uri.parse(
            "https://fitness.completepersonaltraining.com/api/assign-workout/status"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      final data = jsonDecode(res.body);

      if (res.statusCode == 200) {
        prefs.setInt("WORKOUT_MARK_TIME_$workoutId",
            DateTime.now().millisecondsSinceEpoch);
        isWorkoutCompleted.value = true;

        if (Get.isRegistered<AttendanceController>()) {
          final attendanceCtrl = Get.find<AttendanceController>();
          attendanceCtrl.markTodayPresentInstant();
          unawaited(attendanceCtrl.fetchAttendance(force: true));
        }
      }

      Get.snackbar("Workout", data["message"] ?? "Success");
    } catch (e) {
      Get.snackbar("Error", e.toString());
    }
  }
}
