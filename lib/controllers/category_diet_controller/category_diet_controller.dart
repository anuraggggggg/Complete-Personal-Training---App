import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/category_diet_model.dart';


class CategoryDietController extends GetxController {
  // =============================
  // UI STATE
  // =============================
  final RxBool isLoading = false.obs;
  final RxBool isError = false.obs;
  final RxString errorMessage = ''.obs;

  // =============================
  // DATA
  // =============================
  final RxList<Data> categoryDietList = <Data>[].obs;
  final Rx<Pagination?> pagination = Rx<Pagination?>(null);

  // =============================
  // API
  // =============================
  static const String _baseUrl =
      "https://fitness.completepersonaltraining.com/api/categorydiet-list";

  // =============================
  // FETCH CATEGORY DIET LIST
  // =============================
  Future<void> fetchCategoryDietList() async {
    if (isLoading.value) return; // 🛑 double call protection

    isLoading.value = true;
    isError.value = false;
    errorMessage.value = '';
    categoryDietList.clear();

    debugPrint("🚀 FETCH CATEGORY DIET LIST START");

    try {
      // -----------------------------
      // TOKEN
      // -----------------------------
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("TOKEN");

      debugPrint("🔐 TOKEN FOUND = ${token != null}");

      if (token == null || token.isEmpty) {
        throw Exception("User not logged in");
      }

      // -----------------------------
      // API CALL
      // -----------------------------
      final response = await http.get(
        Uri.parse(_baseUrl),
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      debugPrint("📡 STATUS CODE = ${response.statusCode}");
      debugPrint("📦 RAW RESPONSE = ${response.body}");

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final model = CategoryDietModel.fromJson(jsonData);

        pagination.value = model.pagination;

        if (model.data != null && model.data!.isNotEmpty) {
          categoryDietList.assignAll(model.data!);
          debugPrint("✅ CATEGORY DIETS LOADED = ${categoryDietList.length}");
        } else {
          debugPrint("⚠ NO CATEGORY DIETS FOUND");
        }
      } else {
        throw Exception(
            "Server error (${response.statusCode})");
      }
    } catch (e, s) {
      debugPrint("🔥 ERROR = $e");
      debugPrint("📍 STACKTRACE = $s");
      isError.value = true;
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
      debugPrint("✅ FETCH CATEGORY DIET LIST END\n");
    }
  }

  // =============================
  // LIFECYCLE
  // =============================
  @override
  void onInit() {
    super.onInit();
    fetchCategoryDietList();
  }
}
