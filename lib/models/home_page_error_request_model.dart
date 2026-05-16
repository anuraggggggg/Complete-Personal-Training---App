class HomePageErrorRequest {
  bool success;
  String message;

  HomePageErrorRequest({
    required this.success,
    required this.message,
  });

  factory HomePageErrorRequest.fromJson(Map<String, dynamic> json) {
    return HomePageErrorRequest(
      success: json['success'] ?? false,
      message: json['message'] ?? "Something went wrong",
    );
  }
}
