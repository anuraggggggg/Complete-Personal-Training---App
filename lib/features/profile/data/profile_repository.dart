import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mighty_fitness/models/workout_type_response.dart';
import 'package:mighty_fitness/network/api_urls.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileRepository {
  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  Future<String?> getToken() async {
    final prefs = await _prefs;
    return prefs.getString("TOKEN");
  }

  Future<int> getSavedWorkoutMode() async {
    final prefs = await _prefs;
    return prefs.getInt("WORKOUT_MODE") ?? 1;
  }

  Future<void> saveWorkoutMode(int mode) async {
    final prefs = await _prefs;
    await prefs.setInt("WORKOUT_MODE", mode);
  }

  Future<WorkoutTypeResponse?> fetchWorkoutModes(
      {required String token}) async {
    final response = await http.get(
      Uri.parse(ApiEndpoints.endpoint("workouttype-list")),
      headers: {
        "Authorization": "Bearer $token",
        "Accept": "application/json",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode != 200) return null;

    final decoded = jsonDecode(response.body);
    return WorkoutTypeResponse.fromJson(decoded);
  }

  Future<void> clearSession() async {
    final prefs = await _prefs;
    await prefs.clear();
  }

  Future<http.Response> updateWorkoutMode({
    required String token,
    required int mode,
  }) {
    return http.post(
      Uri.parse(ApiEndpoints.endpoint("update-workout-mode")),
      headers: {
        "Authorization": "Bearer $token",
        "Accept": "application/json",
        "Content-Type": "application/json",
      },
      body: jsonEncode({"workout_mode": mode}),
    );
  }

  Future<http.Response> logout({required String token}) {
    return http.get(
      Uri.parse(ApiEndpoints.endpoint("logout")),
      headers: {
        "Accept": "application/json",
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );
  }

  Future<http.Response> deleteAccount({required String token}) {
    return http.post(
      Uri.parse(ApiEndpoints.endpoint("delete-user-account")),
      headers: {
        "Accept": "application/json",
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );
  }
}
