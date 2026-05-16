import 'package:mighty_fitness/extensions/extension_util/device_extensions.dart';

class ApiEndpoints {
  static const String baseUrl =
      "https://fitness.completepersonaltraining.com/api";

  static String endpoint(String path) {
    final normalized = path.startsWith('/') ? path.substring(1) : path;
    return "$baseUrl/$normalized";
  }

  static String packageList({int? page, int? perPage}) {
    final queryParameters = <String, String>{};

    if (page != null) {
      queryParameters["page"] = page.toString();
    }
    if (perPage != null) {
      queryParameters["per_page"] = perPage.toString();
    }
    if (isIOS) {
      queryParameters["platform"] = "ios";
    }

    final uri = Uri.parse(endpoint("package-list")).replace(
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    );
    return uri.toString();
  }

  /// Old attendance endpoint (kept for backward compatibility)
  static String attendanceByMonth(int userId) {
    return "$baseUrl/assign-workouts/user/$userId/workout/month";
  }

  /// New attendance endpoint
  static String attendanceMonthly({
    required int userId,
    required int month,
    required int year,
  }) {
    return "$baseUrl/attendance/monthly?user_id=$userId&month=$month&year=$year";
  }
}
