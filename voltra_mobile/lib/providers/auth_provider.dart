import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';
import '../services/api_client.dart';
import '../services/storage_service.dart';

enum AuthState { initial, loading, authenticated, unauthenticated, error }

/// Authentication state management provider.
/// Handles login, register, session persistence, and logout.
class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepo = AuthRepository();
  final StorageService _storage = StorageService();
  final ApiClient _apiClient = ApiClient();

  AuthState _state = AuthState.initial;
  UserModel? _user;
  String? _errorMessage;

  AuthState get state => _state;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _state == AuthState.authenticated && _user != null;
  bool get isLoading => _state == AuthState.loading;

  /// Check if user has an existing session token on app launch.
  Future<void> checkAuthStatus() async {
    _state = AuthState.loading;
    notifyListeners();

    try {
      final hasToken = await _storage.hasToken();

      if (!hasToken) {
        _state = AuthState.unauthenticated;
        notifyListeners();
        return;
      }

      // Token exists — validate by fetching profile
      final result = await _authRepo.getProfile();

      if (result.isSuccess && result.data != null) {
        _user = result.data;
        await _storage.saveUser(_user!);
        _state = AuthState.authenticated;
      } else {
        // Token expired or invalid
        await _clearSession();
        _state = AuthState.unauthenticated;
      }
    } catch (e) {
      // Network error - try to use cached user
      final cachedUser = _storage.getUser();
      if (cachedUser != null) {
        _user = cachedUser;
        _state = AuthState.authenticated;
      } else {
        _state = AuthState.unauthenticated;
      }
    }

    notifyListeners();
  }

  /// Login with phone number and password.
  Future<bool> login(String phoneNumber, String password) async {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await _authRepo.login(
      phoneNumber: phoneNumber,
      password: password,
    );

    if (result.isSuccess && result.data != null) {
      final data = result.data!;
      final token = data['token'] as String;
      final userData = data['user'] as Map<String, dynamic>;

      _user = UserModel.fromJson(userData);
      await _storage.saveToken(token);
      await _apiClient.setToken(token);
      await _storage.saveUser(_user!);

      _state = AuthState.authenticated;
      notifyListeners();
      return true;
    }

    _errorMessage = result.message;
    _state = AuthState.error;
    notifyListeners();
    return false;
  }

  /// Register a new account.
  Future<bool> register({
    required String name,
    required String phoneNumber,
    required String password,
    required String passwordConfirmation,
    required String pin,
    String? email,
  }) async {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await _authRepo.register(
      name: name,
      phoneNumber: phoneNumber,
      password: password,
      passwordConfirmation: passwordConfirmation,
      pin: pin,
      email: email,
    );

    if (result.isSuccess && result.data != null) {
      final data = result.data!;
      final token = data['token'] as String;
      final userData = data['user'] as Map<String, dynamic>;

      _user = UserModel.fromJson(userData);
      await _storage.saveToken(token);
      await _apiClient.setToken(token);
      await _storage.saveUser(_user!);

      _state = AuthState.authenticated;
      notifyListeners();
      return true;
    }

    _errorMessage = result.message;
    _state = AuthState.error;
    notifyListeners();
    return false;
  }

  /// Refresh user profile data from the server.
  Future<void> refreshProfile() async {
    final result = await _authRepo.getProfile();
    if (result.isSuccess && result.data != null) {
      _user = result.data;
      await _storage.saveUser(_user!);
      notifyListeners();
    }
  }

  /// Logout and clear session.
  Future<void> logout() async {
    try {
      await _authRepo.logout();
    } catch (_) {
      // Ignore network errors during logout
    }
    await _clearSession();
    _state = AuthState.unauthenticated;
    _user = null;
    notifyListeners();
  }

  /// Update the user's FCM token.
  Future<void> updateFcmToken(String token) async {
    await _authRepo.updateFcmToken(token);
  }

  /// Clear stored session data.
  Future<void> _clearSession() async {
    await _storage.clearToken();
    await _storage.clearUser();
    await _apiClient.clearToken();
  }

  /// Clear error state.
  void clearError() {
    _errorMessage = null;
    if (_state == AuthState.error) {
      _state = AuthState.unauthenticated;
    }
    notifyListeners();
  }
}
