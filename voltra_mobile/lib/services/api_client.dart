import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import '../config/app_constants.dart';


/// Singleton Dio HTTP client with Sanctum token interceptor,
/// error normalization, and request/response logging.
class ApiClient {
  static ApiClient? _instance;
  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiClient._() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ));

    _dio.interceptors.addAll([
      _AuthInterceptor(_storage),
      if (kDebugMode) _LoggingInterceptor(),
    ]);
  }

  factory ApiClient() {
    _instance ??= ApiClient._();
    return _instance!;
  }

  Dio get dio => _dio;

  // ─── Convenience Methods ────────────────────────────────

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) {
    return _dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, String>? extraHeaders,
  }) {
    return _dio.post(
      path,
      data: data,
      options: extraHeaders != null ? Options(headers: extraHeaders) : null,
    );
  }

  Future<Response> put(String path, {dynamic data}) {
    return _dio.put(path, data: data);
  }

  Future<Response> patch(String path, {dynamic data}) {
    return _dio.patch(path, data: data);
  }

  Future<Response> delete(String path) {
    return _dio.delete(path);
  }

  /// Save the auth token to secure storage.
  Future<void> setToken(String token) async {
    await _storage.write(key: ApiConfig.tokenKey, value: token);
  }

  /// Clear the auth token from secure storage.
  Future<void> clearToken() async {
    await _storage.delete(key: ApiConfig.tokenKey);
  }

  /// Check if user has a stored auth token.
  Future<bool> hasToken() async {
    final token = await _storage.read(key: ApiConfig.tokenKey);
    return token != null && token.isNotEmpty;
  }
}

/// Interceptor that attaches Bearer token to every request.
class _AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _storage;

  _AuthInterceptor(this._storage);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _storage.read(key: ApiConfig.tokenKey);
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      _storage.delete(key: ApiConfig.tokenKey);
      navigatorKey.currentState?.pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
      scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text('Sesi telah berakhir, silakan login kembali.', style: TextStyle(fontFamily: AppFonts.body)),
          backgroundColor: AppColors.danger,
        ),
      );
    } else if (err.response?.statusCode == 422) {
      final msg = err.response?.data['meta']?['message'] ?? 'Data tidak valid';
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(msg, style: const TextStyle(fontFamily: AppFonts.body)),
          backgroundColor: AppColors.warning,
        ),
      );
    } else if (err.response?.statusCode == 503) {
      navigatorKey.currentState?.pushNamedAndRemoveUntil(AppRoutes.maintenance, (route) => false);
    }
    handler.next(err);
  }
}

/// Debug-only interceptor for request/response logging.
class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    debugPrint('┌── API REQUEST ──────────────────────────────');
    debugPrint('│ ${options.method} ${options.uri}');
    if (options.data != null) {
      debugPrint('│ Body: ${_truncate(jsonEncode(options.data))}');
    }
    debugPrint('└─────────────────────────────────────────────');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    debugPrint('┌── API RESPONSE ─────────────────────────────');
    debugPrint('│ ${response.statusCode} ${response.requestOptions.uri}');
    debugPrint('│ Data: ${_truncate(jsonEncode(response.data))}');
    debugPrint('└─────────────────────────────────────────────');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint('┌── API ERROR ────────────────────────────────');
    debugPrint('│ ${err.response?.statusCode} ${err.requestOptions.uri}');
    debugPrint('│ ${err.message}');
    debugPrint('└─────────────────────────────────────────────');
    handler.next(err);
  }

  String _truncate(String text, [int maxLength = 500]) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}... [truncated]';
  }
}
