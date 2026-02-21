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
import '../models/progress_setting_model.dart';
import '../network/rest_api.dart';
import 'app_constants.dart';

// Theme function
void setTheme() {
  int themeModeIndex = getIntAsync(THEME_MODE_INDEX, defaultValue: ThemeModeSystem);
  if (themeModeIndex == ThemeModeLight) {
    appStore.setDarkMode(false);
  } else if (themeModeIndex == ThemeModeDark) {
    appStore.setDarkMode(true);
  }
}

// Widget Helpers
Widget cachedImage(String? url, {double? height, Color? color, double? width, BoxFit? fit, AlignmentGeometry? alignment, bool usePlaceholderIfUrlEmpty = true, double? radius}) {
  if (url.validate().isEmpty) {
    return placeHolderWidget(height: height, width: width, fit: fit, alignment: alignment, radius: radius);
  } else if (url.validate().startsWith('http')) {
    return CachedNetworkImage(
      imageUrl: url!,
      height: height,
      width: width,
      fit: fit,
      color: color,
      alignment: alignment as Alignment? ?? Alignment.center,
      progressIndicatorBuilder: (context, url, progress) {
        return placeHolderWidget(height: height, width: width, fit: fit, alignment: alignment, radius: radius);
      },
      errorWidget: (_, s, d) {
        return placeHolderWidget(height: height, width: width, fit: fit, alignment: alignment, radius: radius);
      },
    );
  } else {
    return Image.asset(ic_placeholder, height: height, width: width, fit: BoxFit.cover, alignment: alignment ?? Alignment.center).cornerRadiusWithClipRRect(radius ?? defaultRadius);
  }
}

Widget placeHolderWidget({double? height, double? width, BoxFit? fit, AlignmentGeometry? alignment, double? radius}) {
  return Image.asset(ic_placeholder, height: height, width: width, fit: BoxFit.cover, alignment: alignment ?? Alignment.center).cornerRadiusWithClipRRect(radius ?? defaultRadius);
}

toast(String? value, {ToastGravity? gravity, length = Toast.LENGTH_SHORT, Color? bgColor, Color? textColor}) {
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

// User / login values
setLogInValue() {
  print(getBoolAsync(IS_LOGIN));
  userStore.setLogin(getBoolAsync(IS_LOGIN));
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
  await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication).catchError((e) {
    log(e);
    toast('Invalid URL: $url');
  });
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
  await getAppSettingApi().then((value) {
    print('------------------------------>>-${value.toJson()}');

    app_update_check=value.appVersion;
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
    setValue(PRIVACY_POLICY, value.helpSupportUrl.validate());
    setValue(TERMS_SERVICE, value.helpSupportUrl.validate());
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
    userStore.setSubscribe(value.subscriptionDetail!.isSubscribe.validate());
    userStore.setSubscriptionDetail(value.subscriptionDetail!);
    print("user data->${value.toJson()}");
    appStore.setLoading(false);
  }).catchError((e) {
    print("error-$e");
    appStore.setLoading(false);
  });
}

Widget mSuffixTextFieldIconWidget(String? img) {
  return Image.asset(img.validate(), height: 20, width: 20, color:Colors.grey).paddingAll(14);
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
