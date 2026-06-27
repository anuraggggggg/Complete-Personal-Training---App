import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:mighty_fitness/extensions/shared_pref.dart';
import 'package:mighty_fitness/main.dart';
import 'package:mighty_fitness/screens/dashboard_screen.dart';
import 'package:mighty_fitness/screens/free_trial_autopay_subscription_screen.dart';
import 'package:mighty_fitness/utils/app_common.dart';
import 'package:mighty_fitness/utils/app_constants.dart';

Future<void> _refreshCurrentUserSubscription() async {
  final context = Get.context;
  final userId = userStore.userId > 0 ? userStore.userId : getIntAsync(USER_ID);
  if (context == null || userId <= 0) return;

  await getUSerDetail(context, userId);
}

Future<void> openPostAuthDestination({
  bool allowFreeAutopayPrompt = true,
  bool forceFreeAutopayPrompt = false,
  bool refreshSubscription = true,
}) async {
  final userId = userStore.userId > 0 ? userStore.userId : getIntAsync(USER_ID);
  // Deprecated parameters are kept for call-site compatibility. Navigation is
  // decided only from the refreshed subscription status.

  if (refreshSubscription) {
    try {
      await _refreshCurrentUserSubscription();
    } catch (_) {}
  }

  if (hasPremiumSubscriptionAccess(includeCachedAccess: false)) {
    debugPrint(
      'SUBSCRIPTION_NAV: dashboard premium access for user=$userId '
      'isSubscribe=${userStore.isSubscribe}',
    );
    Get.offAll(() => DashboardScreen());
    return;
  }

  debugPrint(
    'SUBSCRIPTION_NAV: unlock page, no premium access for user=$userId '
    'isSubscribe=${userStore.isSubscribe}',
  );
  Get.offAll(() => const FreeTrialAutoPaySubscriptionScreen());
}
