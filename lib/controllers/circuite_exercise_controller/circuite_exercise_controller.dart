import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mighty_fitness/extensions/extension_util/app_snackbar.dart';
import 'package:mighty_fitness/models/cuircuite_exercise_model.dart';
import 'package:mighty_fitness/network/api_urls.dart';

class CircularWorkoutController extends GetxController {
  // ===================== STATE =====================
  final RxBool isLoading = false.obs;
  final RxBool isError = false.obs;
  final RxString message = ''.obs;
  Future<void>? _inflightFetch;
  int? _lastUserId;
  int? _lastLanguageId;
  int? _lastSkipToday;

  /// Full API response
  final Rxn<CircuiteExercise> workoutResponse =
      Rxn<CircuiteExercise>();

  // ===================== CONFIG =====================
  static const String _baseUrl = ApiEndpoints.baseUrl;

  // ===================== GETTERS =====================

  /// ✅ All workouts
  List<Workout> get workouts =>
      workoutResponse.value?.workouts ?? [];

  /// ✅ Today workout (first one)
  Workout? get todayWorkout =>
      workouts.isNotEmpty ? workouts.first : null;

  /// ✅ Exercises for today
  List<Exercise> get todayExercises =>
      todayWorkout?.exercises ?? [];

  /// ✅ Check if workout exists
  bool get hasWorkout => todayExercises.isNotEmpty;

  Workout? get currentWorkout =>
    workouts.isNotEmpty ? workouts.first : null;

String? get warmupVideo =>
    currentWorkout?.warmupVideo;

// List<Exercise> get todayExercises =>
//     currentWorkout?.exercises ?? [];


  // ===================== API CALL =====================
  Future<void> fetchCircularWorkout({
    required int userId,
    int? languageId,
    int? skipToday,
    bool force = false,
    bool showFeedback = true,
  }) async {
    if (!force) {
      if (_inflightFetch != null) return _inflightFetch!;

      final bool sameRequest = _lastUserId == userId &&
          _lastLanguageId == languageId &&
          _lastSkipToday == skipToday;
      if (sameRequest && workoutResponse.value != null && !isError.value) {
        return;
      }
    }

    _lastUserId = userId;
    _lastLanguageId = languageId;
    _lastSkipToday = skipToday;

    final future = _fetchCircularWorkoutInternal(
      userId: userId,
      languageId: languageId,
      skipToday: skipToday,
      showFeedback: showFeedback,
    );
    _inflightFetch = future;

    try {
      await future;
    } finally {
      if (identical(_inflightFetch, future)) {
        _inflightFetch = null;
      }
    }
  }

  // ===================== HELPERS =====================
  Future<void> _fetchCircularWorkoutInternal({
    required int userId,
    int? languageId,
    int? skipToday,
    required bool showFeedback,
  }) async {
    try {
      isLoading.value = true;
      isError.value = false;
      message.value = '';

      // ---------- TOKEN ----------
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("TOKEN");

      if (token == null || token.isEmpty) {
        _setError(
          "Login Required",
          "Please login again to continue",
          showFeedback: showFeedback,
        );
        return;
      }

      // ---------- QUERY PARAMS ----------
      final Map<String, String> query = {};
      if (languageId != null) {
        query['lang'] = languageId.toString();
      }
      if (skipToday != null) {
        query['skip_today'] = skipToday.toString();
      }

      // ---------- API URL ----------
      final uri = Uri.parse(
        "$_baseUrl/user/$userId/circular-workouts",
      ).replace(queryParameters: query);

      log("📡 API URL → $uri");

      // ---------- API CALL ----------
      final response = await http
          .get(
            uri,
            headers: {
              "Accept": "application/json",
              "Authorization": "Bearer $token",
            },
          )
          .timeout(const Duration(seconds: 15));

      log("📥 STATUS → ${response.statusCode}");
      log("📥 BODY → ${response.body}");

      if (response.statusCode == 401) {
        _setError(
          "Session Expired",
          "Please login again",
          showFeedback: showFeedback,
        );
        return;
      }

      if (response.statusCode != 200) {
        _setError(
          "Server Error",
          "Unable to load workout",
          showFeedback: showFeedback,
        );
        return;
      }

      final Map<String, dynamic> json = jsonDecode(response.body);

      if (json['success'] != true) {
        _setWarning(
          "Workout Not Available",
          json['message'] ?? "No workout found",
          showFeedback: showFeedback,
        );
        return;
      }

      final parsed = CircuiteExercise.fromJson(json);
      workoutResponse.value = parsed;

      if (parsed.workouts == null || parsed.workouts!.isEmpty) {
        _setWarning(
          "Workout Not Assigned",
          json['message'] ?? "No circular workouts found",
          showFeedback: showFeedback,
        );
        return;
      }

      if (showFeedback) {
        AppSnackBar.success(
          "Workout Ready 💪",
          "Today's workout loaded successfully",
        );
      }
    } on TimeoutException {
      _setError(
        "Request Timed Out",
        "Workout loading took too long. Please try again.",
        showFeedback: showFeedback,
      );
    } catch (e, s) {
      log("❌ ERROR", error: e, stackTrace: s);
      _setError(
        "Unexpected Error",
        "Please try again",
        showFeedback: showFeedback,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void _setError(String title, String msg, {bool showFeedback = true}) {
    isError.value = true;
    message.value = msg;
    if (showFeedback) {
      AppSnackBar.error(title, msg);
    }
  }

  void _setWarning(String title, String msg, {bool showFeedback = true}) {
    isError.value = true;
    message.value = msg;
    if (showFeedback) {
      AppSnackBar.warning(title, msg);
    }
  }
}
