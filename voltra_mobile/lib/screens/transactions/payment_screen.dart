import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:voltra_mobile/config/app_constants.dart';
import 'package:voltra_mobile/providers/wallet_provider.dart';
import 'package:voltra_mobile/models/product_model.dart';
import 'package:voltra_mobile/utils/currency_formatter.dart';
import 'package:voltra_mobile/widgets/common/shimmer_loading.dart';
import 'package:voltra_mobile/screens/transactions/pin_validation_overlay.dart';

/// Payment confirmation screen.
/// Displays full cost breakdown (base + admin + PG fee - promo),
/// payment method selection (Wallet / Midtrans), and triggers PIN validation.
/// Uses strict Decimal logic for financial precision.
class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _selectedMethod = 'wallet';
  Map<String, dynamic>? _args;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _args ??= ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
  }

  ProductModel get _product => _args!['product'] as ProductModel;
  String get _customerNumber => _args!['customer_number'] as String;
  Map<String, dynamic>? get _inquiryResult =>
      _args!['inquiry_result'] as Map<String, dynamic>?;

  String get _basePrice =>
      _inquiryResult?['amount']?.toString() ?? _product.sellingPrice;
  String get _adminFee =>
      _inquiryResult?['admin_fee']?.toString() ?? '0';
  String get _totalAmount =>
      _inquiryResult?['total']?.toString() ?? _product.sellingPrice;

  void _processPayment(bool canAfford) {
    if (!canAfford && _selectedMethod == 'wallet') {
      _showTopUpSheet();
      return;
    }

    PinValidationOverlay.show(
      context,
      productId: _product.id,
      customerNumber: _customerNumber,
      paymentMethod: _selectedMethod,
    );
  }

  void _showTopUpSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.borderRadiusXl)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: AppSpacing.lg),
              const Icon(Icons.account_balance_wallet_outlined, size: 48, color: AppColors.warning),
              const SizedBox(height: AppSpacing.md),
              const Text('Saldo Tidak Mencukupi', style: TextStyle(fontFamily: AppFonts.heading, fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: AppSpacing.sm),
              const Text('Silakan isi ulang saldo Anda atau gunakan metode pembayaran lain (QRIS/Virtual Account).', textAlign: TextAlign.center, style: TextStyle(fontFamily: AppFonts.body, fontSize: 14, color: AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pushNamed(context, AppRoutes.wallet);
                  },
                  child: const Text('Isi Saldo Sekarang'),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    setState(() => _selectedMethod = 'midtrans');
                  },
                  child: const Text('Ganti Metode', style: TextStyle(fontFamily: AppFonts.body, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_args == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pembayaran')),
        body: const Center(child: Text('Data pembayaran tidak ditemukan.')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Konfirmasi Pembayaran'),
      ),
      body: Consumer<WalletProvider>(
        builder: (context, wallet, _) {
          if (wallet.isBalanceLoading) {
            return Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: List.generate(
                    3,
                    (_) => const Padding(
                          padding: EdgeInsets.only(bottom: AppSpacing.sm),
                          child: ShimmerCard(),
                        )),
              ),
            );
          }

          // Strict financial precision using Decimal
          final Decimal walletBalance =
              Decimal.tryParse(wallet.balance) ?? Decimal.zero;
          final Decimal totalAmount =
              Decimal.tryParse(_totalAmount) ?? Decimal.zero;
          final bool canAfford = walletBalance >= totalAmount;

          if (!canAfford && _selectedMethod == 'wallet') {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _selectedMethod = 'midtrans');
            });
          }

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Order detail card
                      _buildOrderCard(),
                      const SizedBox(height: AppSpacing.md),

                      // Cost breakdown card
                      _buildCostBreakdown(),
                      const SizedBox(height: AppSpacing.lg),

                      // Payment method section
                      const Text(
                        'Metode Pembayaran',
                        style: TextStyle(
                          fontFamily: AppFonts.heading,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      _buildPaymentOption(
                        id: 'wallet',
                        title: 'Saldo Voltra',
                        subtitle:
                            'Saldo: ${CurrencyFormatter.formatIdr(wallet.balance)}',
                        icon: Icons.account_balance_wallet_rounded,
                        isDisabled: !canAfford,
                        disabledReason:
                            canAfford ? null : 'Saldo tidak mencukupi',
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      _buildPaymentOption(
                        id: 'midtrans',
                        title: 'QRIS / Virtual Account',
                        subtitle: 'Bayar via Midtrans (termasuk fee PG)',
                        icon: Icons.qr_code_rounded,
                        isDisabled: false,
                      ),
                    ],
                  ),
                ),
              ),

              // Fixed bottom CTA
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.textPrimary.withValues(alpha: 0.06),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Bayar',
                            style: TextStyle(
                              fontFamily: AppFonts.body,
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            CurrencyFormatter.formatIdr(_totalAmount),
                            style: const TextStyle(
                              fontFamily: AppFonts.heading,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: AppColors.electricBlue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () => _processPayment(canAfford),
                          child: const Text('Bayar Sekarang'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOrderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
        border: Border.all(color: AppColors.divider, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detail Pesanan',
            style: TextStyle(
              fontFamily: AppFonts.body,
              fontSize: 12,
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.electricBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.bolt_rounded,
                  color: AppColors.electricBlue,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _product.name,
                      style: const TextStyle(
                        fontFamily: AppFonts.heading,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _customerNumber,
                      style: const TextStyle(
                        fontFamily: AppFonts.body,
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_inquiryResult?['customer_name'] != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.successBg,
                borderRadius:
                    BorderRadius.circular(AppSpacing.borderRadiusSm),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person_outlined,
                      size: 16, color: AppColors.success),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    _inquiryResult!['customer_name'].toString(),
                    style: const TextStyle(
                      fontFamily: AppFonts.body,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCostBreakdown() {
    final Decimal adminFee = Decimal.tryParse(_adminFee) ?? Decimal.zero;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
        border: Border.all(color: AppColors.divider, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rincian Biaya',
            style: TextStyle(
              fontFamily: AppFonts.body,
              fontSize: 12,
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildCostRow(
              'Harga Produk', CurrencyFormatter.formatIdr(_basePrice)),
          if (adminFee > Decimal.zero)
            _buildCostRow(
                'Biaya Admin', CurrencyFormatter.formatIdr(_adminFee)),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Divider(height: 1, color: AppColors.divider),
          ),
          _buildCostRow(
            'Total',
            CurrencyFormatter.formatIdr(_totalAmount),
            isBold: true,
            valueColor: AppColors.electricBlue,
          ),
        ],
      ),
    );
  }

  Widget _buildCostRow(
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: AppFonts.body,
              fontSize: 13,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
              color: isBold ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: AppFonts.heading,
              fontSize: isBold ? 16 : 14,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption({
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isDisabled,
    String? disabledReason,
  }) {
    final isSelected = _selectedMethod == id;

    return GestureDetector(
      onTap: isDisabled ? null : () => setState(() => _selectedMethod = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isDisabled ? AppColors.surface : AppColors.white,
          borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
          border: Border.all(
            color: isSelected ? AppColors.electricBlue : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.electricBlue.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDisabled
                    ? AppColors.divider
                    : AppColors.electricBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 22,
                color: isDisabled
                    ? AppColors.textTertiary
                    : AppColors.electricBlue,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: AppFonts.heading,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDisabled
                          ? AppColors.textTertiary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    disabledReason ?? subtitle,
                    style: TextStyle(
                      fontFamily: AppFonts.body,
                      fontSize: 12,
                      color: disabledReason != null
                          ? AppColors.danger
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isDisabled
                  ? AppColors.textTertiary
                  : AppColors.electricBlue,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
