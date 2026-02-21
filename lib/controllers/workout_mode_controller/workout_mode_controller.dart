import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mighty_fitness/models/workout_mode_model.dart';

class WorkoutModeController extends GetxController {
  RxBool isLoading = false.obs;
  WorkoutModeModel? workoutModeData;

  RxInt homeId = 0.obs;
  RxInt gymId = 0.obs;

  @override
  void onInit() {
    super.onInit();
    fetchWorkoutModes();
  }

  Future<void> fetchWorkoutModes() async {
    try {
      isLoading.value = true;

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString("TOKEN");

      String url =
          "https://fitness.completepersonaltraining.com/api/workouttype-list";
      print("🌐 Workout Type API URL: $url");

      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token"
        },
      );

      print("📩 RAW RESPONSE: ${response.body}");

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        workoutModeData = WorkoutModeModel.fromJson(jsonData);
        extractIds();
      } else {
        print("❌ API ERROR: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ EXCEPTION: $e");
    } finally {
      isLoading.value = false;
    }
  }

void extractIds() {
  if (workoutModeData?.data == null) return;

  for (var item in workoutModeData!.data!) {
    String title = (item.title ?? "").trim().toLowerCase();

    if (title.contains("home")) {
      homeId.value = item.id ?? 0;
    }
    if (title.contains("gym")) {
      gymId.value = item.id ?? 0;
    }
  }

  print("🏠 HOME ID = ${homeId.value}");
  print("💪 GYM ID = ${gymId.value}");
}

}
  