class AttendanceModel {
  bool? status;
  String? monthRange;
  int? totalCompletedDays;
  List<String>? completedDates;
  List<Data>? data;

  AttendanceModel(
      {this.status,
      this.monthRange,
      this.totalCompletedDays,
      this.completedDates,
      this.data});

  AttendanceModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    monthRange = json['month_range'];
    totalCompletedDays = json['total_completed_days'];
    completedDates = json['completed_dates'].cast<String>();
    if (json['data'] != null) {
      data = <Data>[];
      json['data'].forEach((v) {
        data!.add(new Data.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['status'] = this.status;
    data['month_range'] = this.monthRange;
    data['total_completed_days'] = this.totalCompletedDays;
    data['completed_dates'] = this.completedDates;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Data {
  int? id;
  int? userId;
  int? workoutId;
  int? status;
  int? disable;
  String? createdAt;
  String? updatedAt;

  Data(
      {this.id,
      this.userId,
      this.workoutId,
      this.status,
      this.disable,
      this.createdAt,
      this.updatedAt});

  Data.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    userId = json['user_id'];
    workoutId = json['workout_id'];
    status = json['status'];
    disable = json['disable'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['user_id'] = this.userId;
    data['workout_id'] = this.workoutId;
    data['status'] = this.status;
    data['disable'] = this.disable;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    return data;
  }
}
