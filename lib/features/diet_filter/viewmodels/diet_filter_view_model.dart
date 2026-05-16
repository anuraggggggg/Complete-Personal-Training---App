import 'dart:io';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:mighty_fitness/core/mvvm/base_view_model.dart';
import 'package:mighty_fitness/features/diet_filter/data/diet_filter_repository.dart';
import 'package:mighty_fitness/models/category_diet_model.dart'
    as category_model;
import 'package:mighty_fitness/models/diet_models.dart' as diet_model;
import 'package:mighty_fitness/models/language_lists.dart' as lang_model;

class DietFilterViewModel extends BaseViewModel {
  DietFilterViewModel({DietFilterRepository? repository})
      : _repository = repository ?? DietFilterRepository();

  final DietFilterRepository _repository;

  final RxBool isLoading = false.obs;
  final RxBool isError = false.obs;
  final RxBool isSubscriptionRequired = false.obs;
  final RxBool isCategoryLoading = false.obs;
  final RxBool isLanguageLoading = false.obs;

  final RxString errorMessage = "".obs;
  final RxString subscriptionMessage = "".obs;

  final RxList<diet_model.Data> dietList = <diet_model.Data>[].obs;
  final RxList<category_model.Data> categoryDietList =
      <category_model.Data>[].obs;
  final RxList<lang_model.Data> languages = <lang_model.Data>[].obs;

  final RxInt selectedLanguageId = 1.obs;
  final RxString selectedLanguageCode = "en".obs;

  @override
  void onInit() {
    super.onInit();
    fetchLanguages();
    fetchCategoryDietList();
  }

  Future<void> fetchLanguages() async {
    try {
      isLanguageLoading.value = true;
      final model = await _repository.fetchLanguages();
      final active = (model.data ?? []).where((e) => e.status == 1).toList();
      languages.assignAll(active);

      final defaultLang = active.firstWhereOrNull((e) => e.isDefault == 1);
      if (defaultLang != null) {
        selectedLanguageId.value = defaultLang.id ?? 1;
        selectedLanguageCode.value = defaultLang.languageCode ?? "en";
      }
    } catch (_) {
      // Keep silent for UI resilience.
    } finally {
      isLanguageLoading.value = false;
    }
  }

  Future<void> fetchCategoryDietList() async {
    try {
      isCategoryLoading.value = true;
      final token = await _repository.getToken();
      if (token == null || token.isEmpty) return;

      final model = await _repository.fetchCategoryDietList(token: token);
      categoryDietList.assignAll(model.data ?? <category_model.Data>[]);
    } catch (_) {
      // Keep silent for UI resilience.
    } finally {
      isCategoryLoading.value = false;
    }
  }

  Future<void> fetchDietList({
    required String variety,
    required int categoryId,
    required int languageId,
    required String gender,
  }) async {
    _resetState();
    isLoading.value = true;
    setLoading();

    try {
      final token = await _repository.getToken();
      final userId = await _repository.getUserId();
      if (token == null || userId == null) {
        _setError("User not logged in");
        return;
      }

      final response = await _repository.fetchDietList(
        token: token,
        variety: variety,
        categoryId: categoryId,
        languageId: languageId,
        gender: gender,
      );

      final decoded = jsonDecode(response.body);

      switch (response.statusCode) {
        case 200:
          final model = _repository.parseDietModel(decoded);
          dietList.assignAll(model.data ?? <diet_model.Data>[]);
          setSuccess();
          break;
        case 401:
        case 403:
          isSubscriptionRequired.value = true;
          subscriptionMessage.value = decoded["message"] ??
              (Platform.isIOS
                  ? "Please subscribe to access diet plans on iOS."
                  : "Please subscribe or apply an active coupon to access diet plans");
          break;
        case 404:
          dietList.clear();
          break;
        default:
          _setError(
              decoded["message"] ?? "Server error (${response.statusCode})");
      }
    } catch (_) {
      _setError("Something went wrong. Please try again.");
    } finally {
      isLoading.value = false;
    }
  }

  List<lang_model.Data> get activeLanguages =>
      languages.where((e) => e.status == 1).toList();

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
    setError(message);
  }
}
