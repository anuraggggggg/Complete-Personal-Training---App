import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:mighty_fitness/network/api_urls.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePageRepository {
  static const Duration _kRequestTimeout = Duration(seconds: 20);
  Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();

  Future<String?> getToken() async => (await _prefs()).getString("TOKEN");
  Future<int?> getUserId() async => (await _prefs()).getInt("USER_ID");

  Future<int?> getSkipTodayValue() async =>
      (await _prefs()).getInt("SKIP_TODAY_VALUE");
  Future<int?> getSkipTodayTime() async =>
      (await _prefs()).getInt("SKIP_TODAY_TIME");

  Future<void> setSkipToday(int value) async {
    final prefs = await _prefs();
    await prefs.setInt("SKIP_TODAY_VALUE", value);
    await prefs.setInt("SKIP_TODAY_TIME", DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> clearSkipToday() async {
    final prefs = await _prefs();
    await prefs.remove("SKIP_TODAY_VALUE");
    await prefs.remove("SKIP_TODAY_TIME");
  }

  Future<String> getSavedLanguageCode() async =>
      (await _prefs()).getString("APP_LANGUAGE_CODE") ?? "hi";
  Future<int> getSavedLanguageId() async =>
      (await _prefs()).getInt("APP_LANGUAGE_ID") ?? 1;

  Future<void> saveLanguage({
    required String languageCode,
    required int languageId,
  }) async {
    final prefs = await _prefs();
    await prefs.setString("APP_LANGUAGE_CODE", languageCode);
    await prefs.setInt("APP_LANGUAGE_ID", languageId);
  }

  Future<http.Response> fetchLanguageList() {
    return http
        .get(Uri.parse(ApiEndpoints.endpoint("language-list")))
        .timeout(_kRequestTimeout);
  }

  Future<http.Response> fetchHomeWorkouts({
    required String token,
    required int languageId,
    required int skipToday,
    required int mode,
  }) {
    final baseUrl = ApiEndpoints.endpoint("user/workouts");
    final finalUrl =
        "$baseUrl?lang=$languageId&skip_today=$skipToday&mode=$mode";

    return http
        .get(
          Uri.parse(finalUrl),
          headers: {
            "Authorization": "Bearer $token",
            "Accept": "application/json",
          },
        )
        .timeout(_kRequestTimeout);
  }

  Future<int?> getWorkoutMarkTime(int workoutId) async =>
      (await _prefs()).getInt("WORKOUT_MARK_TIME_$workoutId");

  Future<void> setWorkoutMarkTime(int workoutId) async {
    final prefs = await _prefs();
    await prefs.setInt(
      "WORKOUT_MARK_TIME_$workoutId",
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<http.Response> markWorkoutComplete({
    required String token,
    required int userId,
    required int workoutId,
  }) {
    return http
        .post(
          Uri.parse(ApiEndpoints.endpoint("workout/complete-day")),
          headers: {
            "Content-Type": "application/json",
            "Accept": "application/json",
            "Authorization": "Bearer $token",
          },
          body: '{"user_id":$userId,"workout_id":$workoutId}',
        )
        .timeout(_kRequestTimeout);
  }
}
