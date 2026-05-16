import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:mighty_fitness/controllers/attendance_controller/attendance_controller.dart';
import 'package:mighty_fitness/controllers/workout_mode_update_controller/workout_mode_controller.dart';
import 'package:mighty_fitness/core/mvvm/base_view_model.dart';
import 'package:mighty_fitness/features/home/data/home_page_repository.dart';
import 'package:mighty_fitness/models/home_page_workout_list_request.dart';
import 'package:mighty_fitness/models/language_model.dart';
import 'package:video_player/video_player.dart';

class HomePageViewModel extends BaseViewModel {
  HomePageViewModel({HomePageRepository? repository})
      : _repository = repository ?? HomePageRepository();

  final HomePageRepository _repository;

  RxBool isLoading = false.obs;
  RxString errorMessage = "".obs;
  RxBool isError = false.obs;
  RxInt errorCode = 0.obs;

  HomePage? homePageData;

  RxList<Data> apiLanguageList = <Data>[].obs;
  RxList<Data> filteredLanguages = <Data>[].obs;
  RxString selectedLangCode = "hi".obs;
  RxInt selectedLanguageId = 1.obs;

  RxInt skipToday = (-1).obs;
  RxBool isWorkoutCompleted = false.obs;
  bool _initialLoadDone = false;

  RxMap<String, String> videoThumbCache = <String, String>{}.obs;
  Map<String, VideoPlayerController> videoCache = {};

  final WorkoutModeUpdateController workoutModeController =
      Get.find<WorkoutModeUpdateController>();

  late Worker _workoutModeWorker;

  void onCouponApplied() async {
    debugPrint("Coupon applied -> refreshing Home page data");
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

    loadSkipToday().then((_) async {
      _initialLoadDone = true;
      await fetchHomePageData();
    });

    _workoutModeWorker = ever<int>(
      workoutModeController.workoutMode,
      (mode) {
        if (!_initialLoadDone) return;

        Get.snackbar(
          "Workout Mode",
          mode == 1 ? "Gym workout loaded" : "Home workout loaded",
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
    _workoutModeWorker.dispose();
    super.onClose();
  }

  Future<void> saveSkipTodayChoice(bool showWorkout) async {
    skipToday.value = showWorkout ? 0 : 1;
    await _repository.setSkipToday(skipToday.value);
  }

  Future<void> loadSkipToday() async {
    final saved = await _repository.getSkipTodayValue();
    final time = await _repository.getSkipTodayTime();

    if (saved != null && time != null) {
      final diff =
          DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(time));

      if (diff.inHours >= 24) {
        skipToday.value = -1;
        await _repository.clearSkipToday();
      } else {
        skipToday.value = saved;
      }
    }
  }

  Future<void> loadSavedLanguage() async {
    selectedLangCode.value = await _repository.getSavedLanguageCode();
    selectedLanguageId.value = await _repository.getSavedLanguageId();
  }

  Future<void> updateLanguage(String lang, int id) async {
    await _repository.saveLanguage(languageCode: lang, languageId: id);
    selectedLangCode.value = lang;
    selectedLanguageId.value = id;
  }

  Future<void> fetchLanguageList() async {
    try {
      final res = await _repository.fetchLanguageList();
      if (res.statusCode == 200) {
        final model = LanguageModel.fromJson(json.decode(res.body));
        apiLanguageList.value = model.data ?? [];
        filteredLanguages.value = apiLanguageList;
      }
    } catch (e) {
      debugPrint("Language Error: $e");
    }
  }

  Future<void> fetchHomePageData({bool force = false}) async {
    if (isLoading.value && !force) return;

    isLoading.value = true;
    errorMessage.value = "";
    setLoading();

    try {
      final token = await _repository.getToken();
      final userId = await _repository.getUserId();
      debugPrint("FETCH HOME -> userId=$userId");

      if (token == null || token.isEmpty) {
        errorMessage.value = "User not logged in!";
        return;
      }

      final mode = workoutModeController.workoutMode.value;
      final response = await _repository.fetchHomeWorkouts(
        token: token,
        languageId: selectedLanguageId.value,
        skipToday: skipToday.value,
        mode: mode,
      );

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
        return;
      }

      final decoded = json.decode(response.body);
      homePageData = HomePage.fromJson(decoded);

      final workouts = homePageData?.workoutsForToday;
      if (workouts != null && workouts.isNotEmpty) {
        await checkWorkoutCompletion(workouts.first.workoutId ?? 0);
      } else {
        isWorkoutCompleted.value = false;
      }
      setSuccess();
    } on TimeoutException {
      errorMessage.value = "Connection timed out. Please try again.";
      setError(errorMessage.value);
      debugPrint("fetchHomePageData timeout");
    } catch (e) {
      errorMessage.value = "Network error. Please try again.";
      setError(errorMessage.value);
      debugPrint("fetchHomePageData error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> checkWorkoutCompletion(int workoutId) async {
    if (workoutId == 0) {
      isWorkoutCompleted.value = false;
      return;
    }

    final saved = await _repository.getWorkoutMarkTime(workoutId);
    if (saved == null) {
      isWorkoutCompleted.value = false;
      return;
    }

    final diff =
        DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(saved));
    isWorkoutCompleted.value = diff.inHours < 2;
  }

  Future<void> markWorkoutComplete(int workoutId) async {
    try {
      if (workoutId <= 0) {
        Get.snackbar("Error", "Invalid workout id");
        return;
      }

      final userId = await _repository.getUserId();
      final token = await _repository.getToken();
      if (userId == null) {
        Get.snackbar("Error", "User not found. Please login again");
        return;
      }
      if (token == null || token.isEmpty) {
        Get.snackbar("Error", "Session expired. Please login again");
        return;
      }

      final res = await _repository.markWorkoutComplete(
        token: token,
        userId: userId,
        workoutId: workoutId,
      );

      Map<String, dynamic> data = {};
      try {
        final decoded = jsonDecode(res.body);
        if (decoded is Map<String, dynamic>) data = decoded;
      } catch (_) {}

      if (res.statusCode == 200) {
        await _repository.setWorkoutMarkTime(workoutId);
        isWorkoutCompleted.value = true;

        if (Get.isRegistered<AttendanceController>()) {
          final attendanceCtrl = Get.find<AttendanceController>();
          attendanceCtrl.markTodayPresentInstant();
          unawaited(attendanceCtrl.fetchAttendance(force: true));
        }

        Get.snackbar("Workout", data["message"] ?? "Workout marked complete");
        return;
      }

      if (res.statusCode == 401) {
        Get.snackbar(
            "Error", data["message"]?.toString() ?? "Unauthenticated. Please login again");
        return;
      }

      final String msg = data["message"]?.toString().isNotEmpty == true
          ? data["message"].toString()
          : "Failed to mark workout complete (${res.statusCode})";
      Get.snackbar("Error", msg);
    } catch (_) {
      Get.snackbar("Error", "Something went wrong. Please try again");
    }
  }
}
