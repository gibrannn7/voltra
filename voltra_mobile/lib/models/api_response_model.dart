/// Standardized API response envelope matching the Laravel backend.
class ApiResponse<T> {
  final int code;
  final String status;
  final String message;
  final T? data;
  final Map<String, dynamic>? errors;
  final PaginationMeta? pagination;

  const ApiResponse({
    required this.code,
    required this.status,
    required this.message,
    this.data,
    this.errors,
    this.pagination,
  });

  bool get isSuccess => status == 'success';
  bool get isError => status == 'error';

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    final meta = json['meta'] as Map<String, dynamic>? ?? {};

    return ApiResponse<T>(
      code: meta['code'] as int? ?? 0,
      status: meta['status'] as String? ?? 'error',
      message: meta['message'] as String? ?? '',
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : json['data'] as T?,
      errors: json['errors'] as Map<String, dynamic>?,
      pagination: json['pagination'] != null
          ? PaginationMeta.fromJson(json['pagination'] as Map<String, dynamic>)
          : null,
    );
  }
}

class PaginationMeta {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  const PaginationMeta({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  bool get hasMore => currentPage < lastPage;

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    return PaginationMeta(
      currentPage: json['current_page'] as int? ?? 1,
      lastPage: json['last_page'] as int? ?? 1,
      perPage: json['per_page'] as int? ?? 15,
      total: json['total'] as int? ?? 0,
    );
  }
}
