import 'dart:async';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:mighty_fitness/core/mvvm/base_view_model.dart';
import 'package:mighty_fitness/features/attendance/data/attendance_repository.dart';
import 'package:mighty_fitness/models/attendance_model.dart';

class AttendanceViewModel extends BaseViewModel {
  AttendanceViewModel({AttendanceRepository? repository})
      : _repository = repository ?? AttendanceRepository();

  final AttendanceRepository _repository;

  final RxBool isSyncing = false.obs;
  final RxBool hasError = false.obs;
  final RxString errorMessage = ''.obs;

  AttendanceModel? attendanceModel;
  final RxMap<DateTime, int> attendanceMap = <DateTime, int>{}.obs;

  Future<void>? _inflightFetch;
  DateTime? _activeStartDate;
  DateTime? _activeEndDate;

  @override
  void onInit() {
    super.onInit();
    Future.microtask(() async {
      final auth = await _repository.getAuthData();
      if (auth != null) {
        await _loadCachedAttendance(auth.userId);
      }
      unawaited(fetchAttendance());
    });
  }

  Future<void> fetchAttendance({
    bool force = false,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (!force && _inflightFetch != null) return _inflightFetch!;
    _inflightFetch = _fetchAttendanceInternal(
      startDate: startDate,
      endDate: endDate,
    );
    try {
      await _inflightFetch;
    } finally {
      _inflightFetch = null;
    }
  }

  Future<void> _fetchAttendanceInternal({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    isSyncing.value = true;
    hasError.value = false;
    errorMessage.value = '';
    setLoading();

    try {
      final auth = await _repository.getAuthData();
      if (auth == null) return;

      final now = DateTime.now();
      final DateTime rangeStart = startDate != null && endDate != null
          ? DateTime(startDate.year, startDate.month, startDate.day)
          : DateTime(now.year, now.month, 1);
      final DateTime rangeEnd = startDate != null && endDate != null
          ? DateTime(endDate.year, endDate.month, endDate.day)
          : DateTime(now.year, now.month + 1, 0);

      _activeStartDate = rangeStart;
      _activeEndDate = rangeEnd;

      final List<AttendanceReport> mergedReports = <AttendanceReport>[];
      int totalAssignedDays = 0;
      int totalPresentDays = 0;

      DateTime cursor = DateTime(rangeStart.year, rangeStart.month, 1);
      final DateTime lastMonth = DateTime(rangeEnd.year, rangeEnd.month, 1);

      while (!cursor.isAfter(lastMonth)) {
        final decoded = await _repository.fetchMonthlyAttendance(
          auth: auth,
          month: cursor.month,
          year: cursor.year,
        );

        final model = AttendanceModel.fromJson(decoded);
        if (model.success != true) {
          throw Exception(
              decoded['message']?.toString() ?? 'Invalid attendance response');
        }

        if (model.attendanceReport != null) {
          mergedReports.addAll(model.attendanceReport!);
        }
        totalAssignedDays += model.summary?.totalAssignedDays ?? 0;
        totalPresentDays += model.summary?.totalPresentDays ?? 0;

        cursor = DateTime(cursor.year, cursor.month + 1, 1);
      }

      final double percent = totalAssignedDays == 0
          ? 0
          : (totalPresentDays * 100 / totalAssignedDays);

      attendanceModel = AttendanceModel(
        success: true,
        userId: auth.userId.toString(),
        month: null,
        year: null,
        summary: Summary(
          totalAssignedDays: totalAssignedDays,
          totalPresentDays: totalPresentDays,
          attendancePercentage: "${percent.toStringAsFixed(2)}%",
        ),
        attendanceReport: mergedReports,
      );

      _buildAttendanceMap();
      if (startDate == null || endDate == null) {
        await _repository.cacheAttendance(
          auth.userId,
          jsonEncode(attendanceModel!.toJson()),
        );
      }
      setSuccess();
    } on TimeoutException {
      hasError.value = true;
      errorMessage.value = "Attendance sync timed out";
      setError(errorMessage.value);
    } catch (e) {
      hasError.value = true;
      errorMessage.value = e.toString();
      setError(errorMessage.value);
    } finally {
      isSyncing.value = false;
    }
  }

  Future<void> _loadCachedAttendance(int userId) async {
    final cached = await _repository.loadCachedAttendance(userId);
    if (cached == null || cached.trim().isEmpty) return;

    try {
      attendanceModel = AttendanceModel.fromJson(jsonDecode(cached));
      _buildAttendanceMap();
    } catch (_) {}
  }

  void _buildAttendanceMap() {
    attendanceMap.clear();
    if (attendanceModel == null) return;

    final Set<DateTime> presentDates = {};
    if (attendanceModel!.attendanceReport != null) {
      for (final item in attendanceModel!.attendanceReport!) {
        if (!item.isPresent || item.date == null) continue;
        final parsed = DateTime.tryParse(item.date!);
        if (parsed == null) continue;
        presentDates.add(DateTime(parsed.year, parsed.month, parsed.day));
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

  void markTodayPresentInstant() {
    final now = DateTime.now();
    final key = DateTime(now.year, now.month, now.day);
    attendanceMap[key] = 1;
    attendanceMap.refresh();
  }

  (DateTime, DateTime) _resolveMonthRange() {
    if (_activeStartDate != null && _activeEndDate != null) {
      return (_activeStartDate!, _activeEndDate!);
    }

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

  AttendanceReport? attendanceDetailsFor(DateTime date) {
    final reports = attendanceModel?.attendanceReport;
    if (reports == null || reports.isEmpty) return null;
    for (final item in reports) {
      if (item.date == null) continue;
      final parsed = DateTime.tryParse(item.date!);
      if (parsed == null) continue;
      final key = DateTime(parsed.year, parsed.month, parsed.day);
      final target = DateTime(date.year, date.month, date.day);
      if (key == target) return item;
    }
    return null;
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

    var cursor = pastDates.last;
    final endDate = cursor;
    var streak = 0;
    while (true) {
      final status = attendanceMap[cursor];
      if (status != 0) {
        break;
      }
      streak++;
      final prev = cursor.subtract(const Duration(days: 1));
      if (!attendanceMap.containsKey(prev)) break;
      cursor = prev;
    }
    if (streak == 0) return null;

    DateTime startDate;
    if (attendanceMap[cursor] == 0) {
      startDate = cursor;
    } else {
      startDate = cursor.add(const Duration(days: 1));
    }
    return (startDate, endDate);
  }

  bool shouldShowAbsentAlert({int threshold = 15}) {
    return consecutiveAbsentDays >= threshold;
  }
}
