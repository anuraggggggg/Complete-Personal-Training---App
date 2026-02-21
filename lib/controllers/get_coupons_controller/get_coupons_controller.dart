import 'dart:async';
import 'dart:convert';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/get_coupons.dart';

class GetCouponsController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  final RxList<CouponData> coupons = <CouponData>[].obs;
  final RxInt subscriptionId = 0.obs;
  Future<void>? _inflightFetch;

  static const _url =
      'https://fitness.completepersonaltraining.com/api/offer-coupons';

  @override
  void onInit() {
    super.onInit();
    fetchCoupons();
  }

  Future<void> fetchCoupons() async {
    if (_inflightFetch != null) return _inflightFetch!;
    _inflightFetch = _fetchCouponsInternal();

    try {
      await _inflightFetch;
    } finally {
      _inflightFetch = null;
    }
  }

  Future<void> _fetchCouponsInternal() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('TOKEN');
      if (token == null || token.isEmpty) {
        coupons.clear();
        subscriptionId.value = 0;
        errorMessage.value = 'User not logged in';
        return;
      }

      final res = await http.get(
        Uri.parse(_url),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 20));

      Map<String, dynamic> decoded = const {};
      if (res.body.trim().isNotEmpty) {
        final body = jsonDecode(res.body);
        if (body is Map<String, dynamic>) {
          decoded = body;
        }
      }

      if (res.statusCode != 200) {
        errorMessage.value =
            decoded['message']?.toString() ?? 'Failed to load coupons';
        return;
      }

      if (decoded.isEmpty) {
        coupons.clear();
        subscriptionId.value = 0;
        errorMessage.value = 'Invalid response format';
        return;
      }

      final model = GetCoupons.fromJson(decoded);
      if (model.status != true) {
        subscriptionId.value = model.subscriptionId ?? 0;
        errorMessage.value =
            decoded['message']?.toString() ?? 'Unable to fetch coupons';
        return;
      }

      subscriptionId.value = model.subscriptionId ?? 0;
      coupons.assignAll(model.data ?? <CouponData>[]);
    } on TimeoutException {
      coupons.clear();
      subscriptionId.value = 0;
      errorMessage.value = 'Request timed out';
    } on FormatException {
      coupons.clear();
      subscriptionId.value = 0;
      errorMessage.value = 'Invalid server response';
    } catch (_) {
      coupons.clear();
      subscriptionId.value = 0;
      errorMessage.value = 'Something went wrong';
    } finally {
      isLoading.value = false;
    }
  }

  List<CouponData> get activeCoupons => coupons
      .where(
        (c) =>
            (c.status ?? '').toLowerCase() == 'active' &&
            (c.remainingRedemptions ?? 0) > 0,
      )
      .toList();

  bool get canShowCoupons => subscriptionId.value > 0;
}
