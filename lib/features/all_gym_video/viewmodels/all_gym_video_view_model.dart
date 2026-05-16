import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mighty_fitness/core/mvvm/base_view_model.dart';
import 'package:mighty_fitness/features/all_gym_video/data/all_gym_video_repository.dart';
import 'package:mighty_fitness/models/get_all_exercise_model.dart';
import 'package:mighty_fitness/models/get_exercises_category_model.dart'
    as category_model;
import 'package:mighty_fitness/models/language_model.dart' as lang_model;
import 'package:mighty_fitness/screens/shop_screen.dart';

class AllGymVideoViewModel extends BaseViewModel {
  AllGymVideoViewModel({AllGymVideoRepository? repository})
      : _repository = repository ?? AllGymVideoRepository();

  final AllGymVideoRepository _repository;

  final RxBool isSyncingCategory = false.obs;
  final RxBool isSyncingExercises = false.obs;
  final RxBool isLoadingLanguages = false.obs;

  final RxList<category_model.Data> categoryList = <category_model.Data>[].obs;
  final RxList<ExerciseItem> exerciseList = <ExerciseItem>[].obs;
  final Map<String, List<ExerciseItem>> _memoryCache = {};

  final RxList<lang_model.Data> languageList = <lang_model.Data>[].obs;
  final RxList<lang_model.Data> filteredLanguages = <lang_model.Data>[].obs;

  final RxString selectedLanguageLabel = "English".obs;
  final RxInt selectedLangId = 2.obs;
  final RxString selectedLangCode = "en".obs;

  final RxInt selectedCategoryId = 0.obs;

  final RxnInt selectedResolution = RxnInt(1080);
  final RxString selectedQualityLabel = "1080p".obs;
  final List<int> availableResolutions = [1080, 720, 480, 360, 240, 144];

  final RxBool isUserSubscribed = false.obs;
  final RxString subscriptionMessage =
      "Please subscribe to a 12-month or 24-month plan to unlock and watch all workout videos"
          .obs;

  final RxString errorMessage = "".obs;

  String? _token;

  @override
  void onInit() {
    super.onInit();
    Future.microtask(() async {
      await _loadAuth();
      await _loadSubscriptionStatus();
      await fetchLanguages();
      await fetchCategories();
    });
  }

  Future<void> _loadAuth() async {
    _token = await _repository.getToken();
  }

  Future<void> _loadSubscriptionStatus() async {
    isUserSubscribed.value = await _repository.getIsSubscribed();
    subscriptionMessage.value =
        await _repository.getSubscriptionMessage() ?? subscriptionMessage.value;
  }

  Future<void> fetchLanguages() async {
    if (isLoadingLanguages.value) return;
    isLoadingLanguages.value = true;

    try {
      final response = await _repository.fetchLanguages();
      if (response.statusCode != 200) return;

      final model =
          lang_model.LanguageModel.fromJson(jsonDecode(response.body));
      final activeLangs =
          model.data?.where((e) => e.status == 1).toList() ?? <lang_model.Data>[];

      languageList.assignAll(activeLangs);
      filteredLanguages.assignAll(activeLangs);

      final defaultLang = activeLangs.firstWhereOrNull((e) => e.isDefault == 1);
      if (defaultLang != null) {
        selectedLangId.value = defaultLang.id ?? 2;
        selectedLangCode.value = defaultLang.languageCode ?? "en";
        selectedLanguageLabel.value = defaultLang.languageName ?? "English";
      }
    } catch (e) {
      debugPrint("fetchLanguages error: $e");
    } finally {
      isLoadingLanguages.value = false;
    }
  }

  Future<void> updateLanguage(String code, int id) async {
    selectedLangCode.value = code;
    selectedLangId.value = id;

    final selected = languageList.firstWhereOrNull((e) => e.id == id);
    if (selected != null) {
      selectedLanguageLabel.value = selected.languageName ?? "English";
    }

    _memoryCache.clear();
    if (selectedCategoryId.value != 0) {
      await fetchExercisesByCategory(selectedCategoryId.value);
    }
  }

  Future<void> fetchCategories() async {
    if (isSyncingCategory.value) return;
    isSyncingCategory.value = true;

    try {
      final response = await _repository.fetchCategories();
      if (response.statusCode == 200) {
        final model = category_model.ExercisesCategoryModel.fromJson(
          jsonDecode(response.body),
        );
        categoryList.assignAll(model.data ?? <category_model.Data>[]);
      }
    } catch (_) {
      errorMessage.value = "Failed to load equipment list";
    } finally {
      isSyncingCategory.value = false;
    }
  }

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
    setLoading();

    try {
      final response = await _repository.fetchExercises(
        equipmentId: equipmentId,
        languageId: langId,
        resolution: res,
        token: _token,
      );

      if (response.statusCode != 200) {
        setError("Failed to load videos");
        return;
      }

      final parsed = await compute(_parseExerciseResponse, response.body);
      if (parsed == null || parsed.isEmpty) {
        errorMessage.value = subscriptionMessage.value;
        exerciseList.clear();
        setSuccess();
        return;
      }

      _memoryCache[cacheKey] = parsed;
      exerciseList.assignAll(parsed);
      setSuccess();
    } finally {
      isSyncingExercises.value = false;
    }
  }

  Future<void> changeVideoQuality({int? resolution}) async {
    selectedResolution.value = resolution;
    selectedQualityLabel.value = resolution == null ? "Auto" : "${resolution}p";

    _memoryCache.clear();
    if (selectedCategoryId.value != 0) {
      await fetchExercisesByCategory(selectedCategoryId.value);
    }
  }

  bool canPlayExercise(ExerciseItem item) {
    return !item.isLocked || isUserSubscribed.value;
  }

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
        style: TextButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFFE10600),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          minimumSize: const Size(0, 0),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Text(
          "SUBSCRIBE",
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  bool get hasExercises => exerciseList.isNotEmpty;

  String resolveVideoUrl(ExerciseItem item) =>
      item.getVideoByLanguage(selectedLangId.value);
}

List<ExerciseItem>? _parseExerciseResponse(String body) {
  final jsonData = jsonDecode(body);
  final model = GetAllExerciseModel.fromJson(jsonData);
  return model.data ?? [];
}
