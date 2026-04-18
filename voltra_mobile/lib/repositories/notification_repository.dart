import 'package:dio/dio.dart';
import '../models/api_response_model.dart';
import '../models/notification_model.dart';
import '../services/api_client.dart';

class NotificationRepository {
  final ApiClient _api = ApiClient();

  Future<ApiResponse<List<NotificationModel>>> getNotifications({int page = 1}) async {
    try {
      final response = await _api.get('/notifications', queryParameters: {'page': page});
      return ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (data) => NotificationModel.fromJsonList(data as List<dynamic>),
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<void>> markAsRead(String id) async {
    try {
      final response = await _api.patch('/notifications/$id/read');
      return ApiResponse.fromJson(response.data as Map<String, dynamic>, (_) {});
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  ApiResponse<T> _handleError<T>(DioException e) {
    return ApiResponse<T>(
      code: e.response?.statusCode ?? 0,
      status: 'error',
      message: 'Gagal memuat notifikasi.',
    );
  }
}