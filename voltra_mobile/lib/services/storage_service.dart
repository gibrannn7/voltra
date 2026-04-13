import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_constants.dart';
import '../models/user_model.dart';

/// Unified storage service.
/// - FlutterSecureStorage: for sensitive data (token)
/// - SharedPreferences: for user data, settings, and cached state
class StorageService {
  static StorageService? _instance;
  late final SharedPreferences _prefs;
  final FlutterSecureStorage _secure = const FlutterSecureStorage();

  StorageService._(this._prefs);

  static Future<StorageService> initialize() async {
    if (_instance != null) return _instance!;
    final prefs = await SharedPreferences.getInstance();
    _instance = StorageService._(prefs);
    return _instance!;
  }

  factory StorageService() {
    assert(_instance != null, 'StorageService must be initialized first');
    return _instance!;
  }

  // ─── Auth Token (Secure) ──────────────────────────────

  Future<void> saveToken(String token) async {
    await _secure.write(key: ApiConfig.tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return _secure.read(key: ApiConfig.tokenKey);
  }

  Future<void> clearToken() async {
    await _secure.delete(key: ApiConfig.tokenKey);
  }

  Future<bool> hasToken() async {
    final token = await _secure.read(key: ApiConfig.tokenKey);
    return token != null && token.isNotEmpty;
  }

  // ─── User Data (SharedPreferences) ────────────────────

  Future<void> saveUser(UserModel user) async {
    await _prefs.setString(ApiConfig.userKey, jsonEncode(user.toJson()));
  }

  UserModel? getUser() {
    final jsonStr = _prefs.getString(ApiConfig.userKey);
    if (jsonStr == null) return null;
    return UserModel.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
  }

  Future<void> clearUser() async {
    await _prefs.remove(ApiConfig.userKey);
  }

  // ─── App Settings ─────────────────────────────────────

  bool get isDarkMode => _prefs.getBool('dark_mode') ?? false;
  Future<void> setDarkMode(bool value) => _prefs.setBool('dark_mode', value);

  bool get isFirstLaunch => _prefs.getBool('first_launch') ?? true;
  Future<void> setFirstLaunch(bool value) => _prefs.setBool('first_launch', value);

  // ─── Clear All ────────────────────────────────────────

  Future<void> clearAll() async {
    await _secure.deleteAll();
    await _prefs.clear();
  }
}
