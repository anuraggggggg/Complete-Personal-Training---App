import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:mighty_fitness/models/subscription_List_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserSubscriptionController extends GetxController {
  /// Loading State
  var isLoading = false.obs;

  /// Subscription Records List
  var orders = <Data>[].obs;

  /// Pagination
  Pagination? pagination;

  /// ✅ Correct API URL
  final String orderListUrl =
      "https://fitness.completepersonaltraining.com/api/subscriptionplan-list";

  // -------------------------------------------------------------------
  // FETCH USER SUBSCRIPTION ORDERS
  // -------------------------------------------------------------------
  Future<void> fetchUserSubscriptions() async {
    try {
      isLoading.value = true;

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString("TOKEN");

      if (token == null || token.isEmpty) {
        Get.snackbar("Authentication Failed", "Please login again.");
        return;
      }

      print("📡 Fetching USER Subscription List: $orderListUrl");

      var response = await http.get(
        Uri.parse(orderListUrl),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      print("🟡 STATUS CODE: ${response.statusCode}");
      print("🟡 RESPONSE: ${response.body}");

      if (response.statusCode == 200) {
        var jsonData = jsonDecode(response.body);

        SubscriptionList model = SubscriptionList.fromJson(jsonData);

        pagination = model.pagination;
        orders.value = model.data ?? [];

        print("✔ User Orders Loaded: ${orders.length}");
      } else {
        Get.snackbar("Error", "Failed to load subscription orders.");
      }
    } catch (e) {
      print("🔥 Exception Error: $e");
      Get.snackbar("Error", "Unexpected error occurred.");
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onInit() {
    super.onInit();
    print("🚀 UserSubscriptionController Initialized");
    fetchUserSubscriptions();
  }
}
