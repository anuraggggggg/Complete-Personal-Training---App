import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mighty_fitness/models/category_diet_model.dart';
import 'package:mighty_fitness/models/diet_models.dart';
import 'package:mighty_fitness/models/language_lists.dart';
import 'package:mighty_fitness/network/api_urls.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DietFilterRepository {
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("TOKEN");
  }

  Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt("USER_ID");
  }

  Future<LanguageLists> fetchLanguages() async {
    final response = await http.get(
      Uri.parse(ApiEndpoints.endpoint("language-list")),
      headers: const {"Accept": "application/json"},
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to load languages");
    }

    return LanguageLists.fromJson(jsonDecode(response.body));
  }

  Future<CategoryDietModel> fetchCategoryDietList({required String token}) async {
    final response = await http.get(
      Uri.parse(ApiEndpoints.endpoint("categorydiet-list")),
      headers: {
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to load categories (${response.statusCode})");
    }

    return CategoryDietModel.fromJson(jsonDecode(response.body));
  }

  Future<http.Response> fetchDietList({
    required String token,
    required String variety,
    required int categoryId,
    required int languageId,
    required String gender,
  }) {
    final uri = Uri.parse(ApiEndpoints.endpoint("diet-list-v2")).replace(
      queryParameters: {
        "variety": variety,
        "category": categoryId.toString(),
        "language_id": languageId.toString(),
        "gender": gender,
      },
    );

    return http.get(
      uri,
      headers: {
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      },
    );
  }

  DieatListModel parseDietModel(Map<String, dynamic> decoded) {
    return DieatListModel.fromJson(decoded);
  }
}
