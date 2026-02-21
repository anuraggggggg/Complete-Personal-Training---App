import 'package:shared_preferences/shared_preferences.dart';

Future<void> setFirstTimeOpen(bool? isFirstTime) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setBool('firstTimeOpen', isFirstTime??false);
}

Future<bool?> getFirstTimeOpen() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getBool('firstTimeOpen');
}

