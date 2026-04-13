class TransactionModel {
  final int id;
  final String? productName;
  final String? productSku;
  final String customerNumber;
  final String? customerName;
  final String totalAmount;
  final String status;
  final String? paymentMethod;
  final String? snToken;
  final String? createdAt;

  // Detail fields
  final String? basePrice;
  final String? adminFee;
  final String? discount;
  final String? pgFee;
  final String? profitMargin;
  final String? midtransOrderId;
  final String? digiflazzRefId;
  final String? categoryName;
  final String? promoCode;
  final String? promoDiscount;
  final String? updatedAt;

  const TransactionModel({
    required this.id,
    this.productName,
    this.productSku,
    required this.customerNumber,
    this.customerName,
    required this.totalAmount,
    required this.status,
    this.paymentMethod,
    this.snToken,
    this.createdAt,
    this.basePrice,
    this.adminFee,
    this.discount,
    this.pgFee,
    this.profitMargin,
    this.midtransOrderId,
    this.digiflazzRefId,
    this.categoryName,
    this.promoCode,
    this.promoDiscount,
    this.updatedAt,
  });

  bool get isSuccess => status == 'success';
  bool get isFailed => status == 'failed';
  bool get isPending => status == 'pending';
  bool get isProcessing => status == 'processing';

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as int,
      productName: json['product_name'] as String?,
      productSku: json['product_sku'] as String?,
      customerNumber: json['customer_number'] as String? ?? '',
      customerName: json['customer_name'] as String?,
      totalAmount: json['total_amount']?.toString() ?? '0.00',
      status: json['status'] as String? ?? 'pending',
      paymentMethod: json['payment_method'] as String?,
      snToken: json['sn_token'] as String?,
      createdAt: json['created_at'] as String?,
      basePrice: json['base_price']?.toString(),
      adminFee: json['admin_fee']?.toString(),
      discount: json['discount']?.toString(),
      pgFee: json['pg_fee']?.toString(),
      profitMargin: json['profit_margin']?.toString(),
      midtransOrderId: json['midtrans_order_id'] as String?,
      digiflazzRefId: json['digiflazz_ref_id'] as String?,
      categoryName: json['category'] as String?,
      promoCode: json['promo_code'] as String?,
      promoDiscount: json['promo_discount']?.toString(),
      updatedAt: json['updated_at'] as String?,
    );
  }

  static List<TransactionModel> fromJsonList(List<dynamic> jsonList) {
    return jsonList
        .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
