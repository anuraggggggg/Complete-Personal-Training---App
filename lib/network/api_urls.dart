class ApiEndpoints {
  static const String _baseUrl =
      "https://fitness.completepersonaltraining.com/api";

  /// Attendance month wise
  static String attendanceByMonth(int userId) {
    return "$_baseUrl/assign-workouts/user/$userId/workout/month";
  }
}
