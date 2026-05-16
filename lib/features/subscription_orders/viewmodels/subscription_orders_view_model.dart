import 'dart:convert';

import 'package:get/get.dart';
import 'package:mighty_fitness/core/mvvm/base_view_model.dart';
import 'package:mighty_fitness/features/subscription_orders/data/subscription_orders_repository.dart';
import 'package:mighty_fitness/models/subscription_List_model.dart';

class SubscriptionOrdersViewModel extends BaseViewModel {
  SubscriptionOrdersViewModel({SubscriptionOrdersRepository? repository})
      : _repository = repository ?? SubscriptionOrdersRepository();

  final SubscriptionOrdersRepository _repository;

  final RxBool isLoading = false.obs;
  final RxList<Data> orders = <Data>[].obs;
  final RxString errorMessage = "".obs;
  final RxBool isError = false.obs;

  Pagination? pagination;

  @override
  void onInit() {
    super.onInit();
    fetchUserSubscriptions();
  }

  Future<void> fetchUserSubscriptions() async {
    try {
      isLoading.value = true;
      isError.value = false;
      errorMessage.value = "";
      setLoading();

      final token = await _repository.getToken();
      if (token == null || token.isEmpty) {
        errorMessage.value = "Please login again.";
        isError.value = true;
        Get.snackbar("Authentication Failed", errorMessage.value);
        setError(errorMessage.value);
        return;
      }

      final response = await _repository.fetchOrders(token: token);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final model = SubscriptionList.fromJson(jsonData);
        pagination = model.pagination;
        orders.value = model.data ?? <Data>[];
        setSuccess();
      } else {
        errorMessage.value = "Failed to load subscription orders.";
        isError.value = true;
        Get.snackbar("Error", errorMessage.value);
        setError(errorMessage.value);
      }
    } catch (_) {
      errorMessage.value = "Unexpected error occurred.";
      isError.value = true;
      Get.snackbar("Error", errorMessage.value);
      setError(errorMessage.value);
    } finally {
      isLoading.value = false;
    }
  }
}
