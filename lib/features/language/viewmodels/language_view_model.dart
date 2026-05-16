import 'package:get/get.dart';
import 'package:mighty_fitness/core/mvvm/base_view_model.dart';
import 'package:mighty_fitness/features/language/data/language_repository.dart';
import 'package:mighty_fitness/models/language_lists.dart';

class LanguageViewModel extends BaseViewModel {
  LanguageViewModel({LanguageRepository? repository})
      : _repository = repository ?? LanguageRepository();

  final LanguageRepository _repository;

  // Backward-compatible reactive fields for existing UI.
  final RxBool isLoading = false.obs;
  final RxString errorMessage = "".obs;
  final RxList<Data> languages = <Data>[].obs;
  final RxString selectedLangCode = "".obs;
  final RxInt selectedLangId = 0.obs;

  @override
  void onInit() {
    super.onInit();
    fetchLanguages();
  }

  Future<void> fetchLanguages() async {
    try {
      isLoading.value = true;
      errorMessage.value = "";
      setLoading();

      final model = await _repository.fetchLanguages();
      final list = model.data ?? [];
      languages.assignAll(list);

      final defaultLang = list.firstWhereOrNull((e) => e.isDefault == 1);
      if (defaultLang != null) {
        selectedLangCode.value = defaultLang.languageCode ?? "en";
        selectedLangId.value = defaultLang.id ?? 0;
      }

      setSuccess();
    } catch (_) {
      errorMessage.value = "Language API error";
      setError("Language API error");
      Get.snackbar("Error", "Language API error");
    } finally {
      isLoading.value = false;
    }
  }

  void updateLanguage(String code, int id) {
    selectedLangCode.value = code;
    selectedLangId.value = id;

    Get.snackbar(
      "Language Changed",
      "App language updated",
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  List<Data> get activeLanguages =>
      languages.where((e) => e.status == 1).toList();
}
