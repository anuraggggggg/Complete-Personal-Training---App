import 'package:http/http.dart' as http;
import 'package:mighty_fitness/network/api_urls.dart';

class FaqRepository {
  String get baseUrl => ApiEndpoints.endpoint("faq-list");

  Future<http.Response> fetchFaqPage({required int page}) {
    final uri = Uri.parse(baseUrl).replace(
      queryParameters: {"page": page.toString()},
    );

    return http.get(
      uri,
      headers: {
        "Accept": "application/json",
      },
    );
  }
}
