import 'dart:convert';

import 'package:get/get.dart';
import 'package:mighty_fitness/core/mvvm/base_view_model.dart';
import 'package:mighty_fitness/features/faq/data/faq_repository.dart';
import 'package:mighty_fitness/models/faq_list.dart';

class FaqViewModel extends BaseViewModel {
  FaqViewModel({FaqRepository? repository})
      : _repository = repository ?? FaqRepository();

  final FaqRepository _repository;

  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxBool isError = false.obs;
  final RxString errorMessage = "".obs;

  final RxList<Data> faqList = <Data>[].obs;

  int currentPage = 1;
  int totalPages = 1;

  bool get hasMore => currentPage < totalPages;

  @override
  void onInit() {
    super.onInit();
    fetchFaqs();
  }

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
        setLoading();
      }

      final response = await _repository.fetchFaqPage(page: currentPage);

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final faqResponse = FaqList.fromJson(decoded);

        totalPages = faqResponse.pagination?.totalPages ?? 1;
        final newData = faqResponse.data ?? <Data>[];

        if (loadMore) {
          faqList.addAll(newData);
        } else {
          faqList.assignAll(newData);
        }

        setSuccess();
      } else {
        _setError("Server Error: ${response.statusCode}");
      }
    } catch (_) {
      _setError("Something went wrong. Please try again.");
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }

  Future<void> refreshFaqs() async {
    currentPage = 1;
    await fetchFaqs();
  }

  void _setError(String message) {
    isError.value = true;
    errorMessage.value = message;
    setError(message);
  }
}
