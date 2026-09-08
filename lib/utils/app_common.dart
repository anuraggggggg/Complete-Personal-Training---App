import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:html/parser.dart';
import 'package:intl/intl.dart';
import 'package:mighty_fitness/extensions/extension_util/int_extensions.dart';
import 'package:mighty_fitness/extensions/system_utils.dart';
import 'package:mighty_fitness/screens/dashboard_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../extensions/extension_util/string_extensions.dart';
import '../../extensions/extension_util/widget_extensions.dart';
import '../../utils/app_images.dart';
import '../extensions/constants.dart';
import '../extensions/decorations.dart';
import '../extensions/shared_pref.dart';
import '../main.dart';
import '../models/get_setting_response.dart';
import '../models/user_response.dart';
import '../models/progress_setting_model.dart';
import '../network/rest_api.dart';
import 'app_constants.dart';

// Theme function
void setTheme() {
  int themeModeIndex =
      getIntAsync(THEME_MODE_INDEX, defaultValue: ThemeModeSystem);
  appStore.applyThemeSelection(themeModeIndex);
}

String _normalizeSettingKey(String? key) {
  return key.validate().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
}

bool _isPrivacyPolicyKey(String normalizedKey) {
  const keys = {
    'privacypolicy',
    'privacypolicyurl',
    'privacypolicycontent',
  };
  return keys.contains(normalizedKey);
}

bool _isTermsServiceKey(String normalizedKey) {
  const keys = {
    'termsservice',
    'termcondition',
    'termscondition',
    'termsofservice',
    'termsofuse',
    'termsconditions',
  };
  return keys.contains(normalizedKey);
}

bool hasPremiumSubscriptionAccess({bool includeCachedAccess = false}) {
  if (includeCachedAccess && getBoolAsync("HAS_SUBSCRIPTION")) return true;

  final subscriptionDetail = userStore.subscriptionDetail;
  if (subscriptionDetail?.hasAccess == 1) {
    final accessType = subscriptionDetail?.accessType.validate().toLowerCase();
    const allowedAccessTypes = <String>{'paid', 'trial', 'coupon', 'company'};
    if (!allowedAccessTypes.contains(accessType)) return false;

    if (accessType == 'company') {
      if (subscriptionDetail?.isCompanyAccessActive == 0) return false;
      final endsAt = DateTime.tryParse(
        subscriptionDetail?.companyAccessEndsAt.validate() ?? '',
      );
      if (endsAt != null && endsAt.isBefore(DateTime.now())) return false;
    }
    return true;
  }
  if (subscriptionDetail?.hasAccess == 0) return false;

  final isSubscribed =
      userStore.isSubscribe == 1 || subscriptionDetail?.isSubscribe == 1;
  final isTrialActive = subscriptionDetail?.isTrialActive == 1;

  if (!isSubscribed && !isTrialActive) return false;

  final subscriptionPlan = subscriptionDetail?.subscriptionPlan;
  if (subscriptionPlan == null) return isSubscribed || isTrialActive;

  final status = subscriptionPlan.status.validate().trim().toLowerCase();
  final paymentStatus =
      subscriptionPlan.paymentStatus.validate().trim().toLowerCase();
  final paymentType =
      subscriptionPlan.paymentType.validate().trim().toLowerCase();

  final isRazorpayAutopay = paymentType == PAYMENT_TYPE_RAZORPAY_AUTOPAY ||
      paymentType.contains('autopay');

  final hasActiveSubscription = status == ACTIVE || status == 'active';
  final hasAccessPaymentStatus = paymentStatus == 'paid' ||
      paymentStatus == 'trial' ||
      paymentStatus == 'active';

  if (isRazorpayAutopay) {
    const blockedStatuses = <String>{
      INACTIVE,
      CANCELLED,
      EXPIRED,
      'canceled',
      'expired',
      'failed',
      'payment_failed',
    };

    final isBlockedStatus = blockedStatuses.contains(status) ||
        blockedStatuses.contains(paymentStatus);

    if (!isBlockedStatus) return true;
  }

  if (!hasActiveSubscription || !hasAccessPaymentStatus) return false;

  if (!Platform.isIOS) return true;

  const allowedIosPaymentTypes = <String>{
    PAYMENT_TYPE_IAP,
    'app_store_iap',
    'ios_iap',
    'apple_iap',
  };

  return allowedIosPaymentTypes.contains(paymentType);
}

Future<void> updateSubscriptionAccessState(
    SubscriptionDetail subscriptionDetail) async {
  await userStore.setSubscribe(subscriptionDetail.isSubscribe.validate());
  await userStore.setSubscriptionDetail(subscriptionDetail);
  await setValue(
    "HAS_SUBSCRIPTION",
    hasPremiumSubscriptionAccess(includeCachedAccess: false),
  );
}

Future<void> _persistLegalContent({
  String? privacyPolicy,
  String? termsService,
}) async {
  final privacyValue = privacyPolicy.validate().isNotEmpty
      ? privacyPolicy.validate()
      : PRIVACY_POLICY_URL;
  final termsValue = termsService.validate().isNotEmpty
      ? termsService.validate()
      : TERMS_SERVICE_URL;

  if (privacyValue.isNotEmpty) {
    await userStore.setPrivacyPolicy(privacyValue, isInitialization: true);
    await setValue(PRIVACY_POLICY, privacyValue);
    await setValue(PrivacyPolicy, privacyValue);
  }

  if (termsValue.isNotEmpty) {
    await userStore.setTermsCondition(termsValue, isInitialization: true);
    await setValue(TERMS_SERVICE, termsValue);
    await setValue(TermsCondition, termsValue);
  }
}

Future<void> syncLegalContentFromSettingsList(
    List<SettingList> settingsList) async {
  String privacyValue = '';
  String termsValue = '';

  for (final setting in settingsList) {
    final normalizedKey = _normalizeSettingKey(setting.key);

    if (privacyValue.isEmpty && _isPrivacyPolicyKey(normalizedKey)) {
      privacyValue = setting.value.validate();
    }

    if (termsValue.isEmpty && _isTermsServiceKey(normalizedKey)) {
      termsValue = setting.value.validate();
    }
  }

  await _persistLegalContent(
    privacyPolicy: privacyValue,
    termsService: termsValue,
  );
}

// Widget Helpers
Widget cachedImage(String? url,
    {double? height,
    Color? color,
    double? width,
    BoxFit? fit,
    AlignmentGeometry? alignment,
    bool usePlaceholderIfUrlEmpty = true,
    double? radius}) {
  if (url.validate().isEmpty) {
    return placeHolderWidget(
        height: height,
        width: width,
        fit: fit,
        alignment: alignment,
        radius: radius);
  } else if (url.validate().startsWith('http')) {
    return CachedNetworkImage(
      imageUrl: url!,
      height: height,
      width: width,
      fit: fit,
      color: color,
      alignment: alignment as Alignment? ?? Alignment.center,
      progressIndicatorBuilder: (context, url, progress) {
        return placeHolderWidget(
            height: height,
            width: width,
            fit: fit,
            alignment: alignment,
            radius: radius);
      },
      errorWidget: (_, s, d) {
        return placeHolderWidget(
            height: height,
            width: width,
            fit: fit,
            alignment: alignment,
            radius: radius);
      },
    );
  } else {
    return Image.asset(ic_placeholder,
            height: height,
            width: width,
            fit: BoxFit.cover,
            alignment: alignment ?? Alignment.center)
        .cornerRadiusWithClipRRect(radius ?? defaultRadius);
  }
}

Widget placeHolderWidget(
    {double? height,
    double? width,
    BoxFit? fit,
    AlignmentGeometry? alignment,
    double? radius}) {
  return Image.asset(ic_placeholder,
          height: height,
          width: width,
          fit: BoxFit.cover,
          alignment: alignment ?? Alignment.center)
      .cornerRadiusWithClipRRect(radius ?? defaultRadius);
}

toast(String? value,
    {ToastGravity? gravity,
    length = Toast.LENGTH_SHORT,
    Color? bgColor,
    Color? textColor}) {
  Fluttertoast.showToast(
    msg: value.validate(),
    toastLength: length,
    gravity: ToastGravity.BOTTOM,
    timeInSecForIosWeb: 1,
    backgroundColor: bgColor,
    textColor: textColor,
    fontSize: 16.0,
  );
}

int resolveWorkoutDaysCount(int? value, {int fallback = 3}) {
  if (value == 3 || value == 6) return value!;
  if (fallback == 3 || fallback == 6) return fallback;
  return 3;
}

List<String> defaultWorkoutDaysForCount(int count) {
  switch (resolveWorkoutDaysCount(count)) {
    case 6:
      return const <String>[
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
      ];
    case 3:
    default:
      return const <String>['Monday', 'Wednesday', 'Friday'];
  }
}

// User / login values
setLogInValue() {
  print(getBoolAsync(IS_LOGIN));
  userStore.setLogin(getBoolAsync(IS_LOGIN));
  final cachedTerms = getStringAsync(TermsCondition).validate().isNotEmpty
      ? getStringAsync(TermsCondition).validate()
      : getStringAsync(TERMS_SERVICE).validate();
  final cachedPrivacy = getStringAsync(PrivacyPolicy).validate().isNotEmpty
      ? getStringAsync(PrivacyPolicy).validate()
      : getStringAsync(PRIVACY_POLICY).validate();
  userStore.setTermsCondition(cachedTerms, isInitialization: true);
  userStore.setPrivacyPolicy(cachedPrivacy, isInitialization: true);

  if (userStore.isLoggedIn) {
    userStore.setToken(getStringAsync(TOKEN));
    userStore.setUserID(getIntAsync(USER_ID));
    userStore.setUserEmail(getStringAsync(EMAIL));
    userStore.setFirstName(getStringAsync(FIRSTNAME));
    userStore.setLastName(getStringAsync(LASTNAME));
    userStore.setUserPassword(getStringAsync(PASSWORD));
    userStore.setUserImage(getStringAsync(USER_PROFILE_IMG));
    userStore.setPhoneNo(getStringAsync(PHONE_NUMBER));
    userStore.setDisplayName(getStringAsync(DISPLAY_NAME));
    userStore.setGender(getStringAsync(GENDER));
    userStore.setAge(getStringAsync(AGE));
    userStore.setHeight(getStringAsync(HEIGHT));
    userStore.setHeightUnit(getStringAsync(HEIGHT_UNIT));
    userStore.setWeight(getStringAsync(WEIGHT));
    userStore.setWeightUnit(getStringAsync(WEIGHT_UNIT));
    userStore.setGoal(getStringAsync(GOAL));
    userStore.setWorkoutLoc(getStringAsync(WORKLOC));
    userStore.setlevel(getStringAsync(LEVEL));
    final workoutDaysNo = resolveWorkoutDaysCount(getIntAsync(WORKOUT_DAYS_NO));
    userStore.setWorkoutDaysNo(workoutDaysNo);
    userStore.setWorkoutDays(
      getStringListAsync(WORKOUT_DAYS) ??
          defaultWorkoutDaysForCount(workoutDaysNo),
    );
    userStore.setSubscribe(getIntAsync(IS_SUBSCRIBE), isInitialization: true);
    final cachedSubscriptionDetail = getStringAsync(SUBSCRIPTION_DETAIL);
    if (cachedSubscriptionDetail.validate().isNotEmpty) {
      try {
        final decoded = jsonDecode(cachedSubscriptionDetail);
        if (decoded is Map<String, dynamic>) {
          userStore.setSubscriptionDetail(
            SubscriptionDetail.fromJson(decoded),
            isInitialization: true,
          );
        }
      } catch (e) {
        log('Subscription detail cache parse error: $e');
      }
    }
  }
}

// Utilities
String parseHtmlString(String? htmlString) {
  return parse(parse(htmlString).body!.text).documentElement!.text;
}

String parseDocumentDate(DateTime dateTime, [bool includeTime = false]) {
  if (includeTime) {
    return DateFormat('dd MMM, yyyy hh:mm a').format(dateTime);
  } else {
    return DateFormat('dd MMM, yyyy').format(dateTime);
  }
}

Duration parseDuration(String durationString) {
  List<String> components = durationString.split(':');

  int hours = int.parse(components[0]);
  int minutes = int.parse(components[1]);
  int seconds = int.parse(components[2]);

  return Duration(hours: hours, minutes: minutes, seconds: seconds);
}

progressDateStringWidget(String date) {
  DateFormat dateFormat = DateFormat('yyyy-MM-dd');
  DateTime dateTime = DateTime.parse(date);
  var dateValue = dateFormat.format(dateTime);
  return dateValue;
}

Future<void> launchUrls(String url, {bool forceWebView = false}) async {
  try {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  } catch (e) {
    log(e);
    toast('Invalid URL: $url');
  }
}

// Example UI Widgets
Widget mBlackEffect(double? width, double? height, {double? radiusValue = 16}) {
  return Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      borderRadius: radius(radiusValue),
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.black.withOpacity(0.2),
          Colors.black.withOpacity(0.2),
          Colors.black.withOpacity(0.4),
          Colors.black.withOpacity(0.4),
        ],
      ),
    ),
    alignment: Alignment.bottomLeft,
  );
}

Future<void> getSettingData() async {
  await getAppSettingApi().then((value) async {
    print('------------------------------>>-${value.toJson()}');

    app_update_check = value.appVersion;
    print("fkfjkjfjfdfj:${value.appVersion}");
    print("fasdfkjfeueir:$app_update_check");
    setValue(SITE_NAME, value.siteName.validate());
    setValue(SITE_DESCRIPTION, value.siteDescription.validate());
    setValue(SITE_COPYRIGHT, value.siteCopyright.validate());
    setValue(FACEBOOK_URL, value.facebookUrl.validate());
    setValue(INSTAGRAM_URL, value.instagramUrl.validate());
    setValue(TWITTER_URL, value.twitterUrl.validate());
    setValue(LINKED_URL, value.linkedinUrl.validate());
    setValue(CONTACT_EMAIL, value.contactEmail.validate());
    setValue(CONTACT_NUMBER, value.contactNumber.validate());
    setValue(HELP_SUPPORT, value.helpSupportUrl.validate());
    await _persistLegalContent(
      privacyPolicy: value.privacyPolicy,
      termsService: value.termsService,
    );
  });
}

Future<void> getUSerDetail(BuildContext context, int? id) async {
  await getUserDataApi(id: id.validate()).then((value) async {
    userStore.setFirstName(value.data!.firstName.validate());
    userStore.setUserEmail(value.data!.email.validate());
    userStore.setLastName(value.data!.lastName.validate());
    userStore.setGender(value.data!.gender.validate());
    userStore.setUserID(value.data!.id!.validate());
    userStore.setPhoneNo(value.data!.phoneNumber.validate());
    userStore.setUsername(value.data!.username.validate());
    userStore.setDisplayName(value.data!.displayName.validate());
    userStore.setUserImage(value.data!.profileImage.validate());
    userStore.setAge(value.data!.userProfile!.age.validate());
    userStore.setHeight(value.data!.userProfile!.height.validate());
    userStore.setWeight(value.data!.userProfile!.weight.validate());
    userStore.setWeightUnit(value.data!.userProfile!.weightUnit.validate());
    userStore.setHeightUnit(value.data!.userProfile!.heightUnit.validate());
    if (value.data!.userProfile!.goal != null) {
      userStore.setGoal(value.data!.userProfile!.goal.toString());
    }
    if (value.data!.userProfile!.workoutMode != null) {
      userStore.setWorkoutLoc(value.data!.userProfile!.workoutMode.toString());
    }
    if (value.data!.userProfile!.workoutLevel != null) {
      userStore.setlevel(value.data!.userProfile!.workoutLevel.toString());
    }
    final workoutDaysNo = resolveWorkoutDaysCount(
      value.data!.userProfile!.workoutDaysNo ??
          value.data!.userProfile!.workoutDays,
      fallback: resolveWorkoutDaysCount(
        userStore.workoutDaysNo,
        fallback: getIntAsync(WORKOUT_DAYS_NO, defaultValue: 3),
      ),
    );
    userStore.setWorkoutDaysNo(workoutDaysNo);
    userStore.setWorkoutDays(defaultWorkoutDaysForCount(workoutDaysNo));
    final subscriptionDetail = value.subscriptionDetail;
    if (subscriptionDetail != null) {
      await updateSubscriptionAccessState(subscriptionDetail);
    } else {
      userStore.setSubscribe(value.data?.isSubscribe.validate() ?? 0);
      await setValue(
        "HAS_SUBSCRIPTION",
        hasPremiumSubscriptionAccess(includeCachedAccess: false),
      );
    }
    print("user data->${value.toJson()}");
    appStore.setLoading(false);
  }).catchError((e) {
    print("error-$e");
    appStore.setLoading(false);
  });
}

Widget mSuffixTextFieldIconWidget(String? img) {
  return Image.asset(img.validate(), height: 20, width: 20, color: Colors.grey)
      .paddingAll(14);
}

// Progress Settings
List<ProgressSettingModel> progressSettingList() {
  return [
    ProgressSettingModel(id: 1, name: 'Weight', isEnable: true),
    ProgressSettingModel(id: 2, name: 'Heart Rate', isEnable: true),
    ProgressSettingModel(id: 3, name: 'Push ups in 1 minutes', isEnable: true),
  ];
}

// Others (example)
double poundsToKilograms(double pounds) {
  return pounds * 0.453592;
}
