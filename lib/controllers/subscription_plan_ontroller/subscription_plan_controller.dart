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
  final RxString subscriptionMessage = ''.obs;

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
    // reset state
    isLoading.value = true;
    isError.value = false;
    isSubscriptionRequired.value = false;
    errorMessage.value = "";
    dietList.clear();

    try {
      // =============================
      // TOKEN FROM SHARED PREFS
      // =============================
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("TOKEN");
      final userId = prefs.getInt("USER_ID");

      if (token == null || token.isEmpty || userId == null) {
        isError.value = true;
        errorMessage.value = "User not logged in";
        return;
      }

      // =============================
      // BUILD URL
      // =============================
      final uri = Uri.parse(baseUrl).replace(
        queryParameters: {
          "variety": variety,
          "category": categoryId.toString(),
          "language_id": languageId.toString(),
          "gender": gender,
        },
      );

      print("🌐 URL => $uri");
      print("🔑 TOKEN => $token");

      // =============================
      // API CALL (Bearer Token)
      // =============================
      final response = await http.get(
        uri,
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token", // ✅ SAME AS OTHER APIs
        },
      );

      print("📡 STATUS => ${response.statusCode}");
      print("📦 BODY => ${response.body}");

      // =============================
      // SUCCESS
      // =============================
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final model = DieatListModel.fromJson(jsonData);

        if (model.data != null && model.data!.isNotEmpty) {
          dietList.assignAll(model.data!);
        } else {
          isSubscriptionRequired.value = true;
          subscriptionMessage.value = "Subscription required";
        }
      }

      // =============================
      // AUTH / SUBSCRIPTION
      // =============================
      else if (response.statusCode == 401 ||
          response.statusCode == 403) {
        isSubscriptionRequired.value = true;
        subscriptionMessage.value = "Subscription required";
      }

      // =============================
      // NOT FOUND
      // =============================
      else if (response.statusCode == 404) {
        dietList.clear();
      }

      // =============================
      // OTHER ERRORS
      // =============================
      else {
        isError.value = true;
        errorMessage.value =
            "Server error (${response.statusCode})";
      }
    } catch (e, s) {
      print("🔥 ERROR => $e");
      print("📍 STACK => $s");
      isError.value = true;
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
}
