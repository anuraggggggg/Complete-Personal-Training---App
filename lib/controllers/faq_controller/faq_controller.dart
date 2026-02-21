import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../../models/faq_list.dart';

class FaqController extends GetxController {

  /// ===============================
  /// 🔄 UI STATES
  /// ===============================

  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxBool isError = false.obs;

  final RxString errorMessage = "".obs;

  final RxList<Data> faqList = <Data>[].obs;

  /// ===============================
  /// 📄 PAGINATION
  /// ===============================

  int currentPage = 1;
  int totalPages = 1;

  bool get hasMore => currentPage < totalPages;

  final String baseUrl = "https://fitness.completepersonaltraining.com/api/faq-list";

  

  /// ===============================
  /// 🚀 FETCH FAQ API
  /// ===============================

  Future<void> fetchFaqs({bool loadMore = false}) async {
    try {
      if (loadMore) {
        if (!hasMore) return;
        isLoadingMore.value = true;
        currentPage++;
      } else {
        isLoading.value = true;
        isError.value = false;
        errorMessage.value = "";
        currentPage = 1;
        faqList.clear();
      }

      final uri = Uri.parse(baseUrl).replace(
        queryParameters: {
          "page": currentPage.toString(),
        },
      );

      final response = await http.get(
        uri,
        headers: {
          "Accept": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);

        final faqResponse = FaqList.fromJson(decoded);

        /// ✅ Update pagination info
        totalPages = faqResponse.pagination?.totalPages ?? 1;

        final newData = faqResponse.data ?? [];

        if (loadMore) {
          faqList.addAll(newData);
        } else {
          faqList.assignAll(newData);
        }

      } else {
        _setError("Server Error: ${response.statusCode}");
      }

    } catch (e) {
      _setError("Something went wrong. Please try again.");
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }

  /// ===============================
  /// 🔁 REFRESH SUPPORT
  /// ===============================

  Future<void> refreshFaqs() async {
    currentPage = 1;
    await fetchFaqs();
  }

  /// ===============================
  /// ❌ ERROR HANDLER
  /// ===============================

  void _setError(String message) {
    isError.value = true;
    errorMessage.value = message;
  }

@override
void onInit() {
  super.onInit();
  fetchFaqs();
}

}
