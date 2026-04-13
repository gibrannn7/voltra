import 'package:dio/dio.dart';
import '../models/api_response_model.dart';
import '../services/api_client.dart';

class WalletRepository {
  final ApiClient _api = ApiClient();

  /// Get current wallet balance.
  Future<ApiResponse<Map<String, dynamic>>> getBalance() async {
    try {
      final response = await _api.get('/wallet/balance');
      return ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (data) => data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// Get paginated wallet mutation history.
  Future<ApiResponse<List<Map<String, dynamic>>>> getMutations({int page = 1}) async {
    try {
      final response = await _api.get('/wallet/mutations', queryParameters: {
        'page': page,
      });
      return ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (data) => (data as List<dynamic>)
            .map((e) => e as Map<String, dynamic>)
            .toList(),
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// Initiate wallet top-up via Midtrans.
  Future<ApiResponse<Map<String, dynamic>>> topUp({
    required String amount,
    required String pin,
  }) async {
    try {
      final response = await _api.post(
        '/wallet/top-up',
        data: {'amount': amount},
        extraHeaders: {'X-Pin': pin},
      );
      return ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (data) => data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// Validate a promo code.
  Future<ApiResponse<Map<String, dynamic>>> validatePromo(String promoCode) async {
    try {
      final response = await _api.post('/promos/validate', data: {
        'promo_code': promoCode,
      });
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
      message: 'Gagal memuat data dompet.',
    );
  }
}
