import 'package:dio/dio.dart';
import '../models/api_response_model.dart';
import '../services/api_client.dart';

class SystemRepository {
  final ApiClient _api = ApiClient();

  /// Check if the current app version requires a force update.
  Future<ApiResponse<Map<String, dynamic>>> checkVersion(String currentVersion) async {
    try {
      final response = await _api.post('/system/check-version', data: {
        'current_version': currentVersion,
      });

      return ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (data) => data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// Get public system settings (maintenance mode, CS number).
  Future<ApiResponse<Map<String, dynamic>>> getSettings() async {
    try {
      final response = await _api.get('/system/settings');

      return ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (data) => data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  ApiResponse<T> _handleError<T>(DioException e) {
    if (e.response?.data != null && e.response!.data is Map<String, dynamic>) {
      return ApiResponse.fromJson(e.response!.data as Map<String, dynamic>, null);
    }
    return ApiResponse<T>(
      code: e.response?.statusCode ?? 0,
      status: 'error',
      message: 'Gagal menghubungi server.',
    );
  }
}
