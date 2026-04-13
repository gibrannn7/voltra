class ProductModel {
  final int id;
  final String skuCode;
  final String name;
  final String? category;
  final String? categoryIcon;
  final String basePrice;
  final String adminFee;
  final String sellingPrice;
  final String type;

  const ProductModel({
    required this.id,
    required this.skuCode,
    required this.name,
    this.category,
    this.categoryIcon,
    required this.basePrice,
    required this.adminFee,
    required this.sellingPrice,
    this.type = 'prepaid',
  });

  bool get isPrepaid => type == 'prepaid';
  bool get isPostpaid => type == 'postpaid';

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as int,
      skuCode: json['sku_code'] as String,
      name: json['name'] as String,
      category: json['category'] as String?,
      categoryIcon: json['category_icon'] as String?,
      basePrice: json['base_price']?.toString() ?? '0.00',
      adminFee: json['admin_fee']?.toString() ?? '0.00',
      sellingPrice: json['selling_price']?.toString() ?? '0.00',
      type: json['type'] as String? ?? 'prepaid',
    );
  }

  static List<ProductModel> fromJsonList(List<dynamic> jsonList) {
    return jsonList
        .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
