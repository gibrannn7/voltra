import 'package:dio/dio.dart';
import '../models/api_response_model.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';
import '../services/api_client.dart';

class ProductRepository {
  final ApiClient _api = ApiClient();

  /// Fetch all product categories (cached 1h server-side).
  Future<ApiResponse<List<CategoryModel>>> getCategories() async {
    try {
      final response = await _api.get('/products/categories');
      return ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (data) => CategoryModel.fromJsonList(data as List<dynamic>),
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// Fetch products, optionally filtered by category_id.
  Future<ApiResponse<List<ProductModel>>> getProducts({int? categoryId}) async {
    try {
      final Map<String, dynamic> params = {};
      if (categoryId != null) {
        params['category_id'] = categoryId;
      }
      final response = await _api.get('/products', queryParameters: params);
      return ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (data) => ProductModel.fromJsonList(data as List<dynamic>),
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// Inquiry for postpaid products (PLN, BPJS, etc.)
  Future<ApiResponse<Map<String, dynamic>>> inquiry({
    required String skuCode,
    required String customerNumber,
  }) async {
    try {
      final response = await _api.post('/products/inquiry', data: {
        'sku_code': skuCode,
        'customer_number': customerNumber,
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
      message: 'Gagal memuat data produk.',
    );
  }
}
