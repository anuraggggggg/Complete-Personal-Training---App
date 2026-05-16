import 'dart:io';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:mighty_fitness/models/diet_models.dart';
import 'package:mighty_fitness/network/api_urls.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DietListController extends GetxController {
  // =============================
  // UI STATE
  // =============================

  final RxBool isLoading = false.obs;
  final RxBool isError = false.obs;
  final RxBool isSubscriptionRequired = false.obs;

  final RxString errorMessage = "".obs;
  final RxString subscriptionMessage = "".obs;

  final RxList<Data> dietList = <Data>[].obs;

  // =============================
  // API
  // =============================

  final String baseUrl = ApiEndpoints.endpoint("diet-list-v2");

  // =============================
  // FETCH DIET LIST
  // =============================

  Future<void> fetchDietList({
    required String variety,
    required int categoryId,
    required int languageId,
    required String gender,
  }) async {
    _resetState();

    try {
      isLoading.value = true;

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("TOKEN");
      final userId = prefs.getInt("USER_ID");

      if (token == null || userId == null) {
        _setError("User not logged in");
        return;
      }

      final uri = Uri.parse(baseUrl).replace(
        queryParameters: {
          "variety": variety,
          "category": categoryId.toString(),
          "language_id": languageId.toString(),
          "gender": gender,
        },
      );

      final response = await http.get(
        uri,
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      print("📥 Status Code = ${response.statusCode}");
      print("📥 Raw Body = ${response.body}");

      final decoded = jsonDecode(response.body);

      switch (response.statusCode) {
        // =============================
        // SUCCESS
        // =============================
        case 200:
          final model = DieatListModel.fromJson(decoded);

          if (model.data != null && model.data!.isNotEmpty) {
            dietList.assignAll(model.data!);
          } else {
            // Empty list but success
            dietList.clear();
          }
          break;

        // =============================
        // SUBSCRIPTION REQUIRED
        // =============================
        case 401:
        case 403:
          isSubscriptionRequired.value = true;
          subscriptionMessage.value = decoded["message"] ??
              (Platform.isIOS
                  ? "Please subscribe to access diet plans on iOS."
                  : "Please subscribe or apply an active coupon to access diet plans");
          break;

        // =============================
        // NOT FOUND
        // =============================
        case 404:
          dietList.clear();
          break;

        // =============================
        // SERVER ERROR
        // =============================
        default:
          _setError(
            decoded["message"] ?? "Server error (${response.statusCode})",
          );
      }
    } catch (e) {
      _setError("Something went wrong. Please try again.");
      print("🔥 EXCEPTION: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // =============================
  // HELPERS
  // =============================

  void _resetState() {
    isError.value = false;
    isSubscriptionRequired.value = false;
    errorMessage.value = "";
    subscriptionMessage.value = "";
    dietList.clear();
  }

  void _setError(String message) {
    isError.value = true;
    errorMessage.value = message;
  }
}
