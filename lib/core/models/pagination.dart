class Pagination<T> {
  final List<T> data;

  final int currentPage;

  final int lastPage;

  Pagination({
    required this.data,
    required this.currentPage,
    required this.lastPage,
  });

  factory Pagination.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic json) fromJsonT,
  ) {
    return Pagination<T>(
      data: (json['data'] as List)
          .map((e) => fromJsonT(e))
          .toList(),

      currentPage: json['current_page'] ?? 1,

      lastPage: json['last_page'] ?? 1,
    );
  }
}