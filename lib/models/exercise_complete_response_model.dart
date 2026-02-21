

class ExerciseCompleteResponse {
  bool? success;
  String? message;
  Data? data;

  ExerciseCompleteResponse({this.success, this.message, this.data});

  ExerciseCompleteResponse.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
    data = json['data'] != null ? Data.fromJson(json['data']) : null;
  }
}

class Data {
  int? userId;
  int? exerciseId;
  int? workoutId;
  String? completedAt;

  Data({this.userId, this.exerciseId, this.workoutId, this.completedAt});

  Data.fromJson(Map<String, dynamic> json) {
    userId = int.tryParse(json['user_id'].toString());
    exerciseId = int.tryParse(json['exercise_id'].toString());
    workoutId = json['workout_id'] != null ? int.tryParse(json['workout_id'].toString()) : null;
    completedAt = json['completed_at'];
  }
}
