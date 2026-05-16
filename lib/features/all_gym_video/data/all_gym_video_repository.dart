import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:mighty_fitness/network/api_urls.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AllGymVideoRepository {
  String get categoryUrl => ApiEndpoints.endpoint("equipment-list");
  String get exerciseUrl => ApiEndpoints.endpoint("all-videos");
  String get languageUrl => ApiEndpoints.endpoint("language-list");

  Future<SharedPreferences> get _prefs async =>
      SharedPreferences.getInstance();

  Future<String?> getToken() async {
    final prefs = await _prefs;
    return prefs.getString("TOKEN");
  }

  Future<bool> getIsSubscribed() async {
    final prefs = await _prefs;
    return prefs.getBool("IS_SUBSCRIBED") ?? false;
  }

  Future<String?> getSubscriptionMessage() async {
    final prefs = await _prefs;
    return prefs.getString("SUBSCRIPTION_MESSAGE");
  }

  Future<http.Response> fetchLanguages() {
    return http.get(Uri.parse(languageUrl));
  }

  Future<http.Response> fetchCategories() {
    return http.get(Uri.parse(categoryUrl));
  }

  Future<http.Response> fetchExercises({
    required int equipmentId,
    required int languageId,
    int? resolution,
    String? token,
  }) {
    final resParam = resolution != null ? "&res=$resolution" : "";
    final url = "$exerciseUrl?equipment_id=$equipmentId"
        "&lang_id=$languageId"
        "$resParam";

    return http.get(
      Uri.parse(url),
      headers: {
        if (token != null && token.isNotEmpty) "Authorization": "Bearer $token",
      },
    );
  }
}
