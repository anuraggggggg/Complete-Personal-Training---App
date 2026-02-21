import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mighty_fitness/models/language_model.dart' as lang;
import 'package:mighty_fitness/models/get_all_exercise_model.dart';
import 'package:mighty_fitness/models/get_exercises_category_model.dart';
import 'package:mighty_fitness/screens/shop_screen.dart';

class EquipmentExerciseController extends GetxController {
  // =============================================================
  // 🔄 LOADING STATES
  // =============================================================
  final isSyncingCategory = false.obs;
  final isSyncingExercises = false.obs;
  final isLoadingLanguages = false.obs;

  // =============================================================
  // 📦 DATA
  // =============================================================
  final RxList<Data> categoryList = <Data>[].obs;
  final RxList<ExerciseItem> exerciseList = <ExerciseItem>[].obs;

  /// 🧠 MEMORY CACHE → equipmentId_langId_res
  final Map<String, List<ExerciseItem>> _memoryCache = {};

  // =============================================================
  // 🌐 LANGUAGE (API DRIVEN)
  // =============================================================
  final RxList<lang.Data> languageList = <lang.Data>[].obs;
  final RxList<lang.Data> filteredLanguages = <lang.Data>[].obs;

  final selectedLanguageLabel = "English".obs;
  final selectedLangId = 2.obs;
  final selectedLangCode = "en".obs;

  // =============================================================
  // 📂 CATEGORY / EQUIPMENT
  // =============================================================
  final selectedCategoryId = 0.obs;

  // =============================================================
  // 🎞️ VIDEO QUALITY
  // =============================================================
  final RxnInt selectedResolution = RxnInt(1080); // Default 1080p
  final RxString selectedQualityLabel = "1080p".obs;

  final List<int> availableResolutions = [
    1080,
    720,
    480,
    360,
    240,
    144,
  ];

  // =============================================================
  // 🔐 SUBSCRIPTION
  // =============================================================
  final RxBool isUserSubscribed = false.obs;

  final RxString subscriptionMessage =
      "Please subscribe to a 12-month or 24-month plan to unlock and watch all workout videos"
          .obs;

  // =============================================================
  // ❌ ERROR
  // =============================================================
  final errorMessage = "".obs;

  // =============================================================
  // 🌍 API URLS
  // =============================================================
  static const _categoryUrl =
      "https://fitness.completepersonaltraining.com/api/equipment-list";

  static const _exerciseUrl =
      "https://fitness.completepersonaltraining.com/api/all-videos";

  static const _languageUrl =
      "https://fitness.completepersonaltraining.com/api/language-list";

  // =============================================================
  // 🔐 AUTH
  // =============================================================
  String? _token;

  // =============================================================
  // 🚀 INIT
  // =============================================================
  @override
  void onInit() {
    super.onInit();
    debugPrint("🟢 EquipmentExerciseController INIT");

    Future.microtask(() async {
      await _loadAuth();
      await _loadSubscriptionStatus();
      await fetchLanguages(); // 🌐 language first
      fetchCategories();
    });
  }

  // =============================================================
  // 🔐 LOAD TOKEN
  // =============================================================
  Future<void> _loadAuth() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString("TOKEN");
    debugPrint("🔐 TOKEN LOADED: ${_token != null}");
  }

  // =============================================================
  // 🌐 FETCH LANGUAGES (LanguageModel)
  // =============================================================
  Future<void> fetchLanguages() async {
    if (isLoadingLanguages.value) return;
    isLoadingLanguages.value = true;

    try {
      final response = await http.get(Uri.parse(_languageUrl));

      if (response.statusCode != 200) return;

      final model = lang.LanguageModel.fromJson(jsonDecode(response.body));

      final activeLangs =
          model.data?.where((e) => e.status == 1).toList() ?? [];

      languageList.assignAll(activeLangs);
      filteredLanguages.assignAll(activeLangs);

      /// ✅ default language
      final defaultLang = activeLangs.firstWhereOrNull((e) => e.isDefault == 1);

      if (defaultLang != null) {
        selectedLangId.value = defaultLang.id ?? 2;
        selectedLangCode.value = defaultLang.languageCode ?? "en";
        selectedLanguageLabel.value = defaultLang.languageName ?? "English";
      }

      debugPrint("🌐 LANGUAGES LOADED: ${languageList.length}");
    } catch (e) {
      debugPrint("❌ Language API error: $e");
    } finally {
      isLoadingLanguages.value = false;
    }
  }

  // =============================================================
  // 🌐 UPDATE LANGUAGE (FROM BOTTOM SHEET)
  // =============================================================
  Future<void> updateLanguage(String code, int id) async {
    selectedLangCode.value = code;
    selectedLangId.value = id;

    final selected = languageList.firstWhereOrNull((e) => e.id == id);

    if (selected != null) {
      selectedLanguageLabel.value = selected.languageName ?? "English";
    }

    debugPrint("🌐 LANGUAGE SET → id:$id | code:$code");

    _memoryCache.clear(); // language changed → cache reset

    if (selectedCategoryId.value != 0) {
      await fetchExercisesByCategory(selectedCategoryId.value);
    }
  }

  // =============================================================
  // 🔐 SUBSCRIPTION STATE
  // =============================================================
  Future<void> _loadSubscriptionStatus() async {
    final prefs = await SharedPreferences.getInstance();

    isUserSubscribed.value = prefs.getBool("IS_SUBSCRIBED") ?? false;

    subscriptionMessage.value =
        prefs.getString("SUBSCRIPTION_MESSAGE") ?? subscriptionMessage.value;

    debugPrint("🔓 SUBSCRIPTION: ${isUserSubscribed.value}");
  }

  // =============================================================
  // 📂 FETCH CATEGORIES
  // =============================================================
  Future<void> fetchCategories() async {
    if (isSyncingCategory.value) return;
    isSyncingCategory.value = true;

    try {
      final response = await http.get(Uri.parse(_categoryUrl));

      if (response.statusCode == 200) {
        final model =
            ExercisesCategoryModel.fromJson(jsonDecode(response.body));
        categoryList.assignAll(model.data ?? []);
      }
    } catch (e) {
      errorMessage.value = "Failed to load equipment list";
    } finally {
      isSyncingCategory.value = false;
    }
  }

  // =============================================================
  // 🏋️ FETCH EXERCISES (LANG + QUALITY)
  // =============================================================
  Future<void> fetchExercisesByCategory(int equipmentId) async {
    final langId = selectedLangId.value;
    final res = selectedResolution.value;
    final cacheKey = "${equipmentId}_${langId}_${res ?? 'auto'}";

    if (_memoryCache.containsKey(cacheKey)) {
      exerciseList.assignAll(_memoryCache[cacheKey]!);
      return;
    }

    selectedCategoryId.value = equipmentId;
    isSyncingExercises.value = true;
    errorMessage.value = "";

    try {
      final resParam = res != null ? "&res=$res" : "";

      final url = "$_exerciseUrl?equipment_id=$equipmentId"
          "&lang_id=$langId"
          "$resParam";

      final response = await http.get(
        Uri.parse(url),
        headers: {
          if (_token != null) "Authorization": "Bearer $_token",
        },
      );

      if (response.statusCode != 200) return;

      final parsed = await compute(_parseExerciseResponse, response.body);

      if (parsed == null || parsed.isEmpty) {
        errorMessage.value = subscriptionMessage.value;
        exerciseList.clear();
        return;
      }

      _memoryCache[cacheKey] = parsed;
      exerciseList.assignAll(parsed);
    } finally {
      isSyncingExercises.value = false;
    }
  }

  // =============================================================
  // 🎞️ VIDEO QUALITY
  // =============================================================
  Future<void> changeVideoQuality({int? resolution}) async {
    selectedResolution.value = resolution;
    selectedQualityLabel.value = resolution == null ? "Auto" : "${resolution}p";

    _memoryCache.clear();

    if (selectedCategoryId.value != 0) {
      await fetchExercisesByCategory(selectedCategoryId.value);
    }
  }

  // =============================================================
  // 🔐 PLAY PERMISSION
  // =============================================================
  bool canPlayExercise(ExerciseItem item) {
    return !item.isLocked || isUserSubscribed.value;
  }

  // =============================================================
  // 🔔 SUBSCRIPTION WARNING
  // =============================================================
  void showSubscriptionWarning() {
    Get.snackbar(
      "Subscription Required",
      subscriptionMessage.value,
      snackPosition: SnackPosition.TOP,
      backgroundColor: const Color(0xFFE10600),
      colorText: Colors.white,
      margin: const EdgeInsets.all(14),
      borderRadius: 14,
      icon: const Icon(Icons.lock, color: Colors.white),
      duration: const Duration(seconds: 4),
      mainButton: TextButton(
        onPressed: () => Get.to(() => const ShopScreen()),
        child: const Text("SUBSCRIBE"),
      ),
    );
  }

  // =============================================================
  // 🧠 HELPERS
  // =============================================================
  bool get hasExercises => exerciseList.isNotEmpty;

  String resolveVideoUrl(ExerciseItem item) =>
      item.getVideoByLanguage(selectedLangId.value);
}

/// =============================================================
/// 🧵 ISOLATE PARSER
/// =============================================================
List<ExerciseItem>? _parseExerciseResponse(String body) {
  final jsonData = jsonDecode(body);
  final model = GetAllExerciseModel.fromJson(jsonData);
  return model.data ?? [];
}
