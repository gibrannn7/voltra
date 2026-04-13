import 'package:flutter/foundation.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';
import '../repositories/product_repository.dart';

enum ProductState { initial, loading, loaded, error }

/// Product state management provider.
/// Handles categories, products, and inquiry flow.
class ProductProvider extends ChangeNotifier {
  final ProductRepository _repo = ProductRepository();

  ProductState _categoryState = ProductState.initial;
  ProductState _productState = ProductState.initial;
  ProductState _inquiryState = ProductState.initial;

  List<CategoryModel> _categories = [];
  List<ProductModel> _products = [];
  Map<String, dynamic>? _inquiryResult;
  String? _errorMessage;

  // ─── Getters ────────────────────────────────────────────
  ProductState get categoryState => _categoryState;
  ProductState get productState => _productState;
  ProductState get inquiryState => _inquiryState;
  List<CategoryModel> get categories => _categories;
  List<ProductModel> get products => _products;
  Map<String, dynamic>? get inquiryResult => _inquiryResult;
  String? get errorMessage => _errorMessage;
  bool get isCategoriesLoading => _categoryState == ProductState.loading;
  bool get isProductsLoading => _productState == ProductState.loading;
  bool get isInquiryLoading => _inquiryState == ProductState.loading;

  /// Fetch all categories. Called once on home screen init.
  Future<void> fetchCategories() async {
    if (_categories.isNotEmpty) return; // Already loaded

    _categoryState = ProductState.loading;
    notifyListeners();

    final result = await _repo.getCategories();

    if (result.isSuccess && result.data != null) {
      _categories = result.data!;
      _categoryState = ProductState.loaded;
    } else {
      _errorMessage = result.message;
      _categoryState = ProductState.error;
    }

    notifyListeners();
  }

  /// Fetch products for a specific category.
  Future<void> fetchProducts({int? categoryId}) async {
    _productState = ProductState.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await _repo.getProducts(categoryId: categoryId);

    if (result.isSuccess && result.data != null) {
      _products = result.data!;
      _productState = ProductState.loaded;
    } else {
      _errorMessage = result.message;
      _productState = ProductState.error;
    }

    notifyListeners();
  }

  /// Perform inquiry for postpaid/PLN products.
  Future<bool> performInquiry({
    required String skuCode,
    required String customerNumber,
  }) async {
    _inquiryState = ProductState.loading;
    _inquiryResult = null;
    _errorMessage = null;
    notifyListeners();

    final result = await _repo.inquiry(
      skuCode: skuCode,
      customerNumber: customerNumber,
    );

    if (result.isSuccess && result.data != null) {
      _inquiryResult = result.data!;
      _inquiryState = ProductState.loaded;
      notifyListeners();
      return true;
    }

    _errorMessage = result.message;
    _inquiryState = ProductState.error;
    notifyListeners();
    return false;
  }

  /// Clear inquiry result when navigating away.
  void clearInquiry() {
    _inquiryResult = null;
    _inquiryState = ProductState.initial;
    notifyListeners();
  }

  /// Force refresh categories (pull-to-refresh).
  Future<void> refreshCategories() async {
    _categories = [];
    _categoryState = ProductState.initial;
    await fetchCategories();
  }

  /// Clear error state.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
