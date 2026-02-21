import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccessGateController extends GetxController {
  final hasAccess = false.obs;
  final isChecked = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadAccess();
  }

  Future<void> _loadAccess() async {
    final prefs = await SharedPreferences.getInstance();

    hasAccess.value =
        prefs.getBool("HAS_COUPON_ACCESS") == true ||
        prefs.getBool("HAS_SUBSCRIPTION") == true;

    isChecked.value = true;

    print("🔐 ACCESS CHECKED → hasAccess = ${hasAccess.value}");
  }

  /// coupon apply ke baad call hoga
  void grantAccess() {
    hasAccess.value = true;
    print("🔓 ACCESS GRANTED (coupon/subscription)");
  }
}
