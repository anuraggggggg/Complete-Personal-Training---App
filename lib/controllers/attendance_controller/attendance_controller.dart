import 'dart:async';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:mighty_fitness/models/attendance_model.dart';
import 'package:mighty_fitness/network/api_urls.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AttendanceController extends GetxController {
  final RxBool isSyncing = false.obs;
  final RxBool hasError = false.obs;
  final RxString errorMessage = ''.obs;

  AttendanceModel? attendanceModel;
  final RxMap<DateTime, int> attendanceMap = <DateTime, int>{}.obs;

  Future<void>? _inflightFetch;

  @override
  void onInit() {
    super.onInit();
    Future.microtask(() async {
      final auth = await _getAuthData();
      if (auth != null) {
        await _loadCachedAttendance(auth.userId);
      }
      unawaited(fetchAttendance());
    });
  }

  Future<void> fetchAttendance({bool force = false}) async {
    if (!force && _inflightFetch != null) return _inflightFetch!;
    _inflightFetch = _fetchAttendanceInternal();
    try {
      await _inflightFetch;
    } finally {
      _inflightFetch = null;
    }
  }

  Future<void> _fetchAttendanceInternal() async {
    isSyncing.value = true;
    hasError.value = false;
    errorMessage.value = '';

    try {
      final auth = await _getAuthData();
      if (auth == null) return;

      final response = await http
          .get(
            Uri.parse(ApiEndpoints.attendanceByMonth(auth.userId)),
            headers: _headers(auth.token),
          )
          .timeout(const Duration(seconds: 20));

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

      final model = AttendanceModel.fromJson(decoded);
      if (model.status != true) {
        throw Exception(
            decoded['message']?.toString() ?? 'Invalid attendance response');
      }

      attendanceModel = model;
      _buildAttendanceMap();
      await _cacheAttendance(auth.userId, response.body);
    } on TimeoutException {
      hasError.value = true;
      errorMessage.value = "Attendance sync timed out";
    } catch (e) {
      hasError.value = true;
      errorMessage.value = e.toString();
    } finally {
      isSyncing.value = false;
    }
  }

  Future<void> _cacheAttendance(int userId, String json) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey(userId), json);
  }

  Future<void> _loadCachedAttendance(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_cacheKey(userId));
    if (cached == null || cached.trim().isEmpty) return;

    try {
      attendanceModel = AttendanceModel.fromJson(jsonDecode(cached));
      _buildAttendanceMap();
    } catch (_) {}
  }

  String _cacheKey(int userId) => "ATTENDANCE_CACHE_$userId";

  void _buildAttendanceMap() {
    attendanceMap.clear();
    if (attendanceModel == null) return;

    final Set<DateTime> presentDates = {};

    if (attendanceModel!.completedDates != null &&
        attendanceModel!.completedDates!.isNotEmpty) {
      for (final d in attendanceModel!.completedDates!) {
        final parsed = DateTime.tryParse(d);
        if (parsed == null) continue;
        presentDates.add(DateTime(parsed.year, parsed.month, parsed.day));
      }
    } else if (attendanceModel!.data != null) {
      for (final item in attendanceModel!.data!) {
        if (item.updatedAt == null || item.status != 1) continue;
        final parsed = DateTime.tryParse(item.updatedAt!);
        if (parsed == null) continue;
        final date = parsed.toLocal();
        presentDates.add(DateTime(date.year, date.month, date.day));
      }
    }

    final range = _resolveMonthRange();
    final firstDay = range.$1;
    final lastDay = range.$2;
    final totalDays = lastDay.day;

    for (int i = 0; i < totalDays; i++) {
      final day = firstDay.add(Duration(days: i));
      final key = DateTime(day.year, day.month, day.day);
      attendanceMap[key] = presentDates.contains(key) ? 1 : 0;
    }
  }

  // Optimistic UI update immediately after workout completion.
  void markTodayPresentInstant() {
    final now = DateTime.now();
    final key = DateTime(now.year, now.month, now.day);
    attendanceMap[key] = 1;
    attendanceMap.refresh();
  }

  (DateTime, DateTime) _resolveMonthRange() {
    final raw = attendanceModel?.monthRange ?? '';
    final parts = raw.split('to');
    if (parts.length == 2) {
      final start = DateTime.tryParse(parts[0].trim());
      final end = DateTime.tryParse(parts[1].trim());
      if (start != null && end != null) {
        return (
          DateTime(start.year, start.month, start.day),
          DateTime(end.year, end.month, end.day),
        );
      }
    }

    final now = DateTime.now();
    return (
      DateTime(now.year, now.month, 1),
      DateTime(now.year, now.month + 1, 0),
    );
  }

  bool isPresent(DateTime date) {
    final key = DateTime(date.year, date.month, date.day);
    return attendanceMap[key] == 1;
  }

  bool isAbsent(DateTime date) {
    final key = DateTime(date.year, date.month, date.day);
    return attendanceMap[key] == 0;
  }

  int get totalCompletedDays =>
      attendanceMap.values.where((e) => e == 1).length;

  int get consecutiveAbsentDays {
    if (attendanceMap.isEmpty) return 0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final pastDates =
        attendanceMap.keys.where((d) => !d.isAfter(today)).toList()..sort();

    if (pastDates.isEmpty) return 0;

    var cursor = pastDates.last;
    var streak = 0;

    while (true) {
      final status = attendanceMap[cursor];
      if (status != 0) break;

      streak++;
      final prev = cursor.subtract(const Duration(days: 1));

      if (!attendanceMap.containsKey(prev)) break;
      cursor = prev;
    }

    return streak;
  }

  (DateTime, DateTime)? get absentDateRange {
    if (attendanceMap.isEmpty) return null;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final pastDates =
        attendanceMap.keys.where((d) => !d.isAfter(today)).toList()..sort();

    if (pastDates.isEmpty) return null;

    var cursor =
        pastDates.last; // This is the end date of the range (usually today)
    final endDate = cursor;
    var streak = 0;

    while (true) {
      final status = attendanceMap[cursor];
      if (status != 0)
        break; // Found a present day, streak ends (going backwards)

      streak++;
      final prev = cursor.subtract(const Duration(days: 1));

      if (!attendanceMap.containsKey(prev)) break; // No more data
      cursor = prev; // Move to previous day
    }

    if (streak == 0) return null;

    // cursor is currently the day *before* the streak (if break on status!=0)
    // or the *first* day of the streak (if break on no data, BUT wait...)

    // Let's re-verify the loop logic.
    // If we have days: [P, A, A, A(today)]
    // 1. cursor=today(A). status=0. streak=1. prev=day-1(A). cursor becomes day-1.
    // 2. cursor=day-1(A). status=0. streak=2. prev=day-2(A). cursor becomes day-2.
    // 3. cursor=day-2(A). status=0. streak=3. prev=day-3(P). cursor becomes day-3.
    // 4. cursor=day-3(P). status=1. BREAK.

    // Loop ends. cursor is at P (day-3).
    // The streak started at cursor + 1 day.

    // Case 2: [A, A, A(today)] (No prior history)
    // 1. cursor=today. ... cursor becomes day-1.
    // ...
    // 3. cursor=day-2. ... prev=day-3 (No data). BREAK.
    // Loop ends. cursor is at day-2 (A).
    // In this case, cursor IS the start date.

    DateTime startDate;
    if (attendanceMap[cursor] == 0) {
      // We ended on an absent day (ran out of data)
      startDate = cursor;
    } else {
      // We ended on a present day
      startDate = cursor.add(const Duration(days: 1));
    }

    return (startDate, endDate);
  }

  bool shouldShowAbsentAlert({int threshold = 15}) {
    return consecutiveAbsentDays >= threshold;
  }

  Future<_AuthData?> _getAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt("USER_ID");
    final token = prefs.getString("TOKEN");
    if (userId == null || token == null || token.isEmpty) return null;
    return _AuthData(userId, token);
  }

  Map<String, String> _headers(String token) {
    return {
      "Authorization": "Bearer $token",
      "Accept": "application/json",
    };
  }
}

class _AuthData {
  final int userId;
  final String token;
  _AuthData(this.userId, this.token);
}
