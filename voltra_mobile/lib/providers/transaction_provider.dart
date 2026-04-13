import 'package:flutter/foundation.dart';
import '../models/api_response_model.dart';
import '../models/transaction_model.dart';
import '../repositories/transaction_repository.dart';

enum TransactionState { initial, loading, loaded, creating, success, error }

/// Transaction state management provider.
/// Handles transaction creation, history, and detail views.
class TransactionProvider extends ChangeNotifier {
  final TransactionRepository _repo = TransactionRepository();

  TransactionState _state = TransactionState.initial;
  TransactionState _historyState = TransactionState.initial;

  List<TransactionModel> _transactions = [];
  TransactionModel? _currentTransaction;
  PaginationMeta? _pagination;
  String? _errorMessage;

  // ─── Getters ────────────────────────────────────────────
  TransactionState get state => _state;
  TransactionState get historyState => _historyState;
  List<TransactionModel> get transactions => _transactions;
  TransactionModel? get currentTransaction => _currentTransaction;
  PaginationMeta? get pagination => _pagination;
  String? get errorMessage => _errorMessage;
  bool get isCreating => _state == TransactionState.creating;
  bool get isLoading => _historyState == TransactionState.loading;
  bool get hasMore => _pagination?.hasMore ?? false;

  /// Create a new transaction with PIN verification.
  Future<bool> createTransaction({
    required int productId,
    required String customerNumber,
    required String paymentMethod,
    required String pin,
    required String idempotencyKey,
    String? promoCode,
  }) async {
    _state = TransactionState.creating;
    _errorMessage = null;
    notifyListeners();

    final result = await _repo.createTransaction(
      productId: productId,
      customerNumber: customerNumber,
      paymentMethod: paymentMethod,
      pin: pin,
      idempotencyKey: idempotencyKey,
      promoCode: promoCode,
    );

    if (result.isSuccess && result.data != null) {
      _currentTransaction = result.data;
      _state = TransactionState.success;
      notifyListeners();
      return true;
    }

    _errorMessage = result.message;
    _state = TransactionState.error;
    notifyListeners();
    return false;
  }

  /// Fetch first page of transaction history.
  Future<void> fetchTransactions({String? status}) async {
    _historyState = TransactionState.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await _repo.getTransactions(page: 1, status: status);

    if (result.isSuccess && result.data != null) {
      _transactions = result.data!;
      _pagination = result.pagination;
      _historyState = TransactionState.loaded;
    } else {
      _errorMessage = result.message;
      _historyState = TransactionState.error;
    }

    notifyListeners();
  }

  /// Load next page for infinite scrolling.
  Future<void> fetchNextPage({String? status}) async {
    if (!hasMore || _historyState == TransactionState.loading) return;

    final nextPage = (_pagination?.currentPage ?? 0) + 1;

    final result = await _repo.getTransactions(page: nextPage, status: status);

    if (result.isSuccess && result.data != null) {
      _transactions.addAll(result.data!);
      _pagination = result.pagination;
    }

    notifyListeners();
  }

  /// Get transaction detail by ID.
  Future<void> fetchTransactionDetail(int id) async {
    _state = TransactionState.loading;
    notifyListeners();

    final result = await _repo.getTransactionDetail(id);

    if (result.isSuccess && result.data != null) {
      _currentTransaction = result.data;
      _state = TransactionState.loaded;
    } else {
      _errorMessage = result.message;
      _state = TransactionState.error;
    }

    notifyListeners();
  }

  /// Set current transaction (from list tap).
  void setCurrentTransaction(TransactionModel transaction) {
    _currentTransaction = transaction;
    notifyListeners();
  }

  /// Clear state when navigating away.
  void clearState() {
    _state = TransactionState.initial;
    _currentTransaction = null;
    _errorMessage = null;
    notifyListeners();
  }
}
