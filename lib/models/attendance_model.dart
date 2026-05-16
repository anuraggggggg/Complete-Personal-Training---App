class AttendanceModel {
  bool? success;
  String? userId;
  String? month;
  String? year;
  Summary? summary;
  List<AttendanceReport>? attendanceReport;

  AttendanceModel({
    this.success,
    this.userId,
    this.month,
    this.year,
    this.summary,
    this.attendanceReport,
  });

  AttendanceModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    userId = json['user_id']?.toString();
    month = json['month']?.toString();
    year = json['year']?.toString();
    summary =
        json['summary'] != null ? Summary.fromJson(json['summary']) : null;
    if (json['attendance_report'] != null) {
      attendanceReport = <AttendanceReport>[];
      json['attendance_report'].forEach((v) {
        attendanceReport!.add(AttendanceReport.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    data['user_id'] = userId;
    data['month'] = month;
    data['year'] = year;
    if (summary != null) {
      data['summary'] = summary!.toJson();
    }
    if (attendanceReport != null) {
      data['attendance_report'] =
          attendanceReport!.map((v) => v.toJson()).toList();
    }
    return data;
  }

  // Backward-compatible helpers used by existing UI/controller.
  String? get monthRange {
    final int? monthNo = _monthToNumber(month);
    final int? yearNo = int.tryParse(year ?? '');
    if (monthNo == null || yearNo == null) return null;
    final start = DateTime(yearNo, monthNo, 1);
    final end = DateTime(yearNo, monthNo + 1, 0);
    return "${start.toIso8601String().split('T').first} to ${end.toIso8601String().split('T').first}";
  }

  int get totalCompletedDays => summary?.totalPresentDays ?? 0;

  int? _monthToNumber(String? monthName) {
    if (monthName == null || monthName.trim().isEmpty) return null;
    const monthMap = {
      'january': 1,
      'february': 2,
      'march': 3,
      'april': 4,
      'may': 5,
      'june': 6,
      'july': 7,
      'august': 8,
      'september': 9,
      'october': 10,
      'november': 11,
      'december': 12,
    };
    return monthMap[monthName.toLowerCase()];
  }
}

class Summary {
  int? totalAssignedDays;
  int? totalPresentDays;
  String? attendancePercentage;

  Summary({
    this.totalAssignedDays,
    this.totalPresentDays,
    this.attendancePercentage,
  });

  Summary.fromJson(Map<String, dynamic> json) {
    totalAssignedDays = _toInt(json['total_assigned_days']);
    totalPresentDays = _toInt(json['total_present_days']);
    attendancePercentage = json['attendance_percentage']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['total_assigned_days'] = totalAssignedDays;
    data['total_present_days'] = totalPresentDays;
    data['attendance_percentage'] = attendancePercentage;
    return data;
  }

  int? _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '');
  }
}

class AttendanceReport {
  String? date;
  String? dayName;
  String? status;
  String? details;
  int? completedCount;
  int? totalAssigned;

  AttendanceReport({
    this.date,
    this.dayName,
    this.status,
    this.details,
    this.completedCount,
    this.totalAssigned,
  });

  AttendanceReport.fromJson(Map<String, dynamic> json) {
    date = json['date']?.toString();
    dayName = json['day_name']?.toString();
    status = json['status']?.toString();
    details = json['details']?.toString();
    completedCount = _toInt(json['completed_count']);
    totalAssigned = _toInt(json['total_assigned']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['date'] = date;
    data['day_name'] = dayName;
    data['status'] = status;
    data['details'] = details;
    data['completed_count'] = completedCount;
    data['total_assigned'] = totalAssigned;
    return data;
  }

  bool get isPresent {
    final raw = status?.toLowerCase() ?? '';
    return raw.contains('present') ||
        raw.contains('completed') ||
        raw.contains('done');
  }

  int? _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '');
  }
}
