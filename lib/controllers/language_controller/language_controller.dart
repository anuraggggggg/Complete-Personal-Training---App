import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../../models/language_lists.dart';


class LanguageController extends GetxController {
  // ===============================
  // STATE
  // ===============================
  final RxBool isLoading = false.obs;
  final RxList<Data> languages = <Data>[].obs;

  /// selected language
  final RxString selectedLangCode = "".obs;
  final RxInt selectedLangId = 0.obs;

  static const String _url =
      "https://fitness.completepersonaltraining.com/api/language-list";

  // ===============================
  // INIT
  // ===============================
  @override
  void onInit() {
    super.onInit();
    fetchLanguages();
  }

  // ===============================
  // FETCH LANGUAGE LIST
  // ===============================
  Future<void> fetchLanguages() async {
    try {
      isLoading.value = true;

      final response = await http.get(
        Uri.parse(_url),
        headers: {
          "Accept": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final model =
            LanguageLists.fromJson(jsonDecode(response.body));

        final list = model.data ?? [];

        languages.assignAll(list);

        /// 🔥 auto-select default language
        final defaultLang =
            list.firstWhereOrNull((e) => e.isDefault == 1);

        if (defaultLang != null) {
          selectedLangCode.value =
              defaultLang.languageCode ?? "en";
          selectedLangId.value =
              defaultLang.id ?? 0;
        }
      } else {
        _showError("Failed to load languages");
      }
    } catch (e) {
      _showError("Language API error");
    } finally {
      isLoading.value = false;
    }
  }

  // ===============================
  // UPDATE LANGUAGE (FROM UI)
  // ===============================
  void updateLanguage(String code, int id) {
    selectedLangCode.value = code;
    selectedLangId.value = id;

    Get.snackbar(
      "Language Changed",
      "App language updated",
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  // ===============================
  // FILTER (OPTIONAL)
  // ===============================
  List<Data> get activeLanguages =>
      languages.where((e) => e.status == 1).toList();

  // ===============================
  // ERROR
  // ===============================
  void _showError(String msg) {
    Get.snackbar("Error", msg);
  }
}
