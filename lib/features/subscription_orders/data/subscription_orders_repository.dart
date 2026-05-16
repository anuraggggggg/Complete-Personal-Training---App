import 'package:http/http.dart' as http;
import 'package:mighty_fitness/network/api_urls.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SubscriptionOrdersRepository {
  String get orderListUrl => ApiEndpoints.endpoint("subscriptionplan-list");

  Future<SharedPreferences> get _prefs async =>
      SharedPreferences.getInstance();

  Future<String?> getToken() async {
    final prefs = await _prefs;
    return prefs.getString("TOKEN");
  }

  Future<http.Response> fetchOrders({required String token}) {
    return http.get(
      Uri.parse(orderListUrl),
      headers: {
        "Authorization": "Bearer $token",
        "Accept": "application/json",
      },
    );
  }
}
