import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mighty_fitness/models/language_lists.dart';
import 'package:mighty_fitness/network/api_urls.dart';

class LanguageRepository {
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
}
