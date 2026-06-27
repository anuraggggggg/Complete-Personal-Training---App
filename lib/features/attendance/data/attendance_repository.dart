import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mighty_fitness/network/api_urls.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthData {
  final int userId;
  final String token;
  const AuthData(this.userId, this.token);
}

class AttendanceRepository {
  Future<AuthData?> getAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt("USER_ID");
    final token = prefs.getString("TOKEN");
    if (userId == null || token == null || token.isEmpty) return null;
    return AuthData(userId, token);
  }

  Future<Map<String, dynamic>> fetchMonthlyAttendance({
    required AuthData auth,
    required int month,
    required int year,
  }) async {
    final response = await http.get(
      Uri.parse(ApiEndpoints.attendanceMonthly(
        userId: auth.userId,
        month: month,
        year: year,
      )),
      headers: {
        "Authorization": "Bearer ${auth.token}",
        "Accept": "application/json",
      },
    ).timeout(const Duration(seconds: 15));

    Map<String, dynamic> decoded = const {};
    if (response.body.trim().isNotEmpty) {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) {
        decoded = body;
      }
    }

    if (response.statusCode != 200) {
      throw Exception(
        decoded['message']?.toString() ??
            "Unable to sync attendance (${response.statusCode})",
      );
    }

    return decoded;
  }

  Future<void> cacheAttendance(int userId, String json) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey(userId), json);
  }

  Future<String?> loadCachedAttendance(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_cacheKey(userId));
  }

  String _cacheKey(int userId) => "ATTENDANCE_CACHE_$userId";
}
