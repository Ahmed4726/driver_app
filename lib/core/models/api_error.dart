class ApiError {
  final String message;

  ApiError({
    required this.message,
  });

  factory ApiError.fromJson(Map<String, dynamic> json) {
    return ApiError(
      message: json['message'] ?? 'Something went wrong.',
    );
  }
}