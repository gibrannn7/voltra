import 'package:dio/dio.dart';
import '../models/api_response_model.dart';
import '../models/transaction_model.dart';
import '../services/api_client.dart';

class TransactionRepository {
  final ApiClient _api = ApiClient();

  /// Create a new transaction. Requires X-Pin and X-Idempotency-Key headers.
  Future<ApiResponse<TransactionModel>> createTransaction({
    required int productId,
    required String customerNumber,
    required String paymentMethod,
    required String pin,
    required String idempotencyKey,
    String? promoCode,
  }) async {
    try {
      final response = await _api.post(
        '/transactions',
        data: {
          'product_id': productId,
          'customer_number': customerNumber,
          'payment_method': paymentMethod,
          if (promoCode != null) 'promo_code': promoCode,
        },
        extraHeaders: {
          'X-Pin': pin,
          'X-Idempotency-Key': idempotencyKey,
        },
      );
      return ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (data) => TransactionModel.fromJson(data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// Fetch paginated transaction history.
  Future<ApiResponse<List<TransactionModel>>> getTransactions({
    int page = 1,
    String? status,
  }) async {
    try {
      final response = await _api.get('/transactions', queryParameters: {
        'page': page,
        if (status != null) 'status': status,
      });
      return ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (data) => TransactionModel.fromJsonList(data as List<dynamic>),
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// Fetch single transaction detail.
  Future<ApiResponse<TransactionModel>> getTransactionDetail(int id) async {
    try {
      final response = await _api.get('/transactions/$id');
      return ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (data) => TransactionModel.fromJson(data as Map<String, dynamic>),
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
      message: 'Gagal memproses transaksi.',
    );
  }
}
