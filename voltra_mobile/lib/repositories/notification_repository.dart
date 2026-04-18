import 'package:dio/dio.dart';
import 'package:voltra_mobile/models/api_response_model.dart';
import 'package:voltra_mobile/models/notification_model.dart';
import 'package:voltra_mobile/services/api_client.dart';

/// Repository for handling notification API calls.
class NotificationRepository {
  final ApiClient _apiClient = ApiClient();

  /// Retrieve paginated notifications from the server.
  Future<List<NotificationModel>> getNotifications({int page = 1}) async {
    try {
      final response = await _apiClient.dio.get(
        '/notifications',
        queryParameters: {'page': page},
      );
      
      final apiResponse = ApiResponseModel.fromJson(response.data);
      if (apiResponse.meta['status'] == 'success') {
        final List<dynamic> data = apiResponse.data['data'] ?? [];
        return data.map((json) => NotificationModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      if (e is DioException) {
        throw Exception(e.response?.data['meta']?['message'] ?? 'Gagal mengambil notifikasi');
      }
      throw Exception('Terjadi kesalahan jaringan');
    }
  }

  /// Mark a specific notification as read.
  Future<bool> markAsRead(int notificationId) async {
    try {
      final response = await _apiClient.dio.post(
        '/notifications/$notificationId/read',
      );
      
      final apiResponse = ApiResponseModel.fromJson(response.data);
      return apiResponse.meta['status'] == 'success';
    } catch (e) {
      return false;
    }
  }

  /// Mark all notifications for the user as read.
  Future<bool> markAllAsRead() async {
    try {
      final response = await _apiClient.dio.post(
        '/notifications/read-all',
      );
      
      final apiResponse = ApiResponseModel.fromJson(response.data);
      return apiResponse.meta['status'] == 'success';
    } catch (e) {
      return false;
    }
  }
}