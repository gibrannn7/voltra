import 'package:flutter/material.dart';
import '../repositories/wallet_repository.dart';
import '../config/app_constants.dart';

enum WalletState { initial, loading, loaded, error }

/// Wallet state management provider.
/// Handles balance, mutation history, top-up, and promo validation.
class WalletProvider extends ChangeNotifier {
  final WalletRepository _repo = WalletRepository();

  WalletState _balanceState = WalletState.initial;
  WalletState _mutationState = WalletState.initial;

  String _balance = '0.00';
  List<Map<String, dynamic>> _mutations = [];
  Map<String, dynamic>? _promoResult;
  String? _errorMessage;

  // ─── Getters ────────────────────────────────────────────
  WalletState get balanceState => _balanceState;
  WalletState get mutationState => _mutationState;
  String get balance => _balance;
  List<Map<String, dynamic>> get mutations => _mutations;
  Map<String, dynamic>? get promoResult => _promoResult;
  String? get errorMessage => _errorMessage;
  bool get isBalanceLoading => _balanceState == WalletState.loading;
  bool get isMutationsLoading => _mutationState == WalletState.loading;

  /// Fetch current wallet balance.
  Future<void> fetchBalance() async {
    _balanceState = WalletState.loading;
    notifyListeners();

    final result = await _repo.getBalance();

    if (result.isSuccess && result.data != null) {
      _balance = result.data!['balance']?.toString() ?? '0.00';
      _balanceState = WalletState.loaded;
    } else {
      _errorMessage = result.message;
      _balanceState = WalletState.error;
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(result.message ?? 'Gagal memuat saldo', style: const TextStyle(fontFamily: AppFonts.body)),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    notifyListeners();
  }

  /// Pull-to-refresh logic that reloads both balance and mutation history.
  Future<void> refreshAll() async {
    await Future.wait([
      fetchBalance(),
      fetchMutations(),
    ]);
  }

  /// Fetch mutation history.
  Future<void> fetchMutations() async {
    _mutationState = WalletState.loading;
    notifyListeners();

    final result = await _repo.getMutations();

    if (result.isSuccess && result.data != null) {
      _mutations = result.data!;
      _mutationState = WalletState.loaded;
    } else {
      _errorMessage = result.message;
      _mutationState = WalletState.error;
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(result.message ?? 'Gagal memuat mutasi', style: const TextStyle(fontFamily: AppFonts.body)),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    notifyListeners();
  }

  /// Validate a promo code.
  Future<bool> validatePromo(String code) async {
    final result = await _repo.validatePromo(code);

    if (result.isSuccess && result.data != null) {
      _promoResult = result.data;
      notifyListeners();
      return true;
    }

    _errorMessage = result.message;
    _promoResult = null;
    notifyListeners();
    return false;
  }

  /// Clear promo result.
  void clearPromo() {
    _promoResult = null;
    notifyListeners();
  }

  /// Update balance locally (after wallet payment) without API call.
  void updateBalanceLocally(String newBalance) {
    _balance = newBalance;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
