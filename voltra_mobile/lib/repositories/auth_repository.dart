import 'package:dio/dio.dart';
import '../models/api_response_model.dart';
import '../models/user_model.dart';
import '../services/api_client.dart';

class AuthRepository {
  final ApiClient _api = ApiClient();

  /// Register a new user account.
  Future<ApiResponse<Map<String, dynamic>>> register({
    required String name,
    required String phoneNumber,
    required String password,
    required String passwordConfirmation,
    required String pin,
    String? email,
  }) async {
    try {
      final response = await _api.post('/auth/register', data: {
        'name': name,
        'phone_number': phoneNumber,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
        'pin': pin,
      });

      return ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (data) => data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  /// Login with phone number and password.
  Future<ApiResponse<Map<String, dynamic>>> login({
    required String phoneNumber,
    required String password,
  }) async {
    try {
      final response = await _api.post('/auth/login', data: {
        'phone_number': phoneNumber,
        'password': password,
      });

      return ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (data) => data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  /// Verify PIN for transaction confirmation.
  Future<ApiResponse<void>> verifyPin(String pin) async {
    try {
      final response = await _api.post('/auth/verify-pin', data: {
        'pin': pin,
      });

      return ApiResponse.fromJson(response.data as Map<String, dynamic>, null);
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  /// Get the authenticated user's profile.
  Future<ApiResponse<UserModel>> getProfile() async {
    try {
      final response = await _api.get('/auth/profile');

      return ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (data) => UserModel.fromJson(data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  /// Update FCM token for push notifications.
  Future<ApiResponse<void>> updateFcmToken(String fcmToken) async {
    try {
      final response = await _api.put('/auth/fcm-token', data: {
        'fcm_token': fcmToken,
      });

      return ApiResponse.fromJson(response.data as Map<String, dynamic>, null);
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  /// Logout and revoke token.
  Future<ApiResponse<void>> logout() async {
    try {
      final response = await _api.post('/auth/logout');
      return ApiResponse.fromJson(response.data as Map<String, dynamic>, null);
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  /// Delete account (soft delete).
  Future<ApiResponse<void>> deleteAccount() async {
    try {
      final response = await _api.delete('/auth/account');
      return ApiResponse.fromJson(response.data as Map<String, dynamic>, null);
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  /// Generic Dio error handler.
  ApiResponse<T> _handleDioError<T>(DioException e) {
    if (e.response?.data != null && e.response!.data is Map<String, dynamic>) {
      return ApiResponse.fromJson(e.response!.data as Map<String, dynamic>, null);
    }

    String message;
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        message = 'Koneksi timeout. Periksa jaringan Anda.';
        break;
      case DioExceptionType.connectionError:
        message = 'Tidak dapat terhubung ke server.';
        break;
      default:
        message = 'Terjadi kesalahan. Silakan coba lagi.';
    }

    return ApiResponse<T>(
      code: e.response?.statusCode ?? 0,
      status: 'error',
      message: message,
    );
  }
}
