import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../config/app_constants.dart';
import '../../models/product_model.dart';
import '../../providers/product_provider.dart';
import '../../utils/currency_formatter.dart';
import '../../widgets/common/shimmer_loading.dart';

/// Bottom sheet for entering customer number and performing inquiry.
/// For postpaid: calls /inquiry API and displays customer confirmation.
/// For prepaid: skips inquiry and goes directly to payment.
class InquiryBottomSheet extends StatefulWidget {
  final ProductModel product;

  const InquiryBottomSheet({super.key, required this.product});

  @override
  State<InquiryBottomSheet> createState() => _InquiryBottomSheetState();
}

class _InquiryBottomSheetState extends State<InquiryBottomSheet> {
  final _customerNumberController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _showInquiryResult = false;

  @override
  void dispose() {
    _customerNumberController.dispose();
    super.dispose();
  }

  Future<void> _handleInquiry() async {
    if (!_formKey.currentState!.validate()) return;

    if (widget.product.isPrepaid) {
      // Prepaid: skip inquiry, go directly to payment
      _navigateToPayment();
      return;
    }

    // Postpaid: perform inquiry first
    final provider = context.read<ProductProvider>();
    final success = await provider.performInquiry(
      skuCode: widget.product.skuCode,
      customerNumber: _customerNumberController.text.trim(),
    );

    if (success && mounted) {
      setState(() => _showInquiryResult = true);
    }
  }

  void _navigateToPayment() {
    Navigator.pop(context); // Close bottom sheet
    Navigator.pushNamed(
      context,
      AppRoutes.payment,
      arguments: {
        'product': widget.product,
        'customer_number': _customerNumberController.text.trim(),
        'inquiry_result': _showInquiryResult
            ? context.read<ProductProvider>().inquiryResult
            : null,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.md,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // ─── Product Info Header ───────────────
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.electricBlue.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
                  border: Border.all(
                    color: AppColors.electricBlue.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.electricBlue.withValues(alpha: 0.1),
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
                            widget.product.name,
                            style: const TextStyle(
                              fontFamily: AppFonts.heading,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.product.isPostpaid
                                ? 'Tagihan Pascabayar'
                                : 'Isi Ulang Prabayar',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      CurrencyFormatter.formatIdr(widget.product.sellingPrice),
                      style: const TextStyle(
                        fontFamily: AppFonts.heading,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.electricBlue,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // ─── Customer Number Input ─────────────
              if (!_showInquiryResult) ...[
                Form(
                  key: _formKey,
                  child: TextFormField(
                    controller: _customerNumberController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: InputDecoration(
                      labelText: widget.product.isPostpaid
                          ? 'Nomor Pelanggan / ID Pelanggan'
                          : 'Nomor HP Tujuan',
                      hintText: widget.product.isPostpaid
                          ? 'Masukkan nomor pelanggan'
                          : 'Contoh: 08xxxxxxxxxx',
                      prefixIcon: Icon(
                        widget.product.isPostpaid
                            ? Icons.badge_outlined
                            : Icons.phone_outlined,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Nomor wajib diisi';
                      }
                      if (value.length < 8) {
                        return 'Nomor terlalu pendek';
                      }
                      return null;
                    },
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Action button
                Consumer<ProductProvider>(
                  builder: (context, provider, _) {
                    return ElevatedButton(
                      onPressed: provider.isInquiryLoading ? null : _handleInquiry,
                      child: provider.isInquiryLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: AppColors.white,
                              ),
                            )
                          : Text(
                              widget.product.isPostpaid
                                  ? 'Cek Tagihan'
                                  : 'Lanjut Bayar',
                            ),
                    );
                  },
                ),

                // Error display
                Consumer<ProductProvider>(
                  builder: (context, provider, _) {
                    if (provider.inquiryState == ProductState.error &&
                        provider.errorMessage != null) {
                      return Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.md),
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.dangerBg,
                            borderRadius:
                                BorderRadius.circular(AppSpacing.borderRadiusSm),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline,
                                  color: AppColors.danger, size: 20),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  provider.errorMessage!,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.danger,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],

              // ─── Inquiry Result (Postpaid Confirmation) ──
              if (_showInquiryResult)
                Consumer<ProductProvider>(
                  builder: (context, provider, _) {
                    if (provider.isInquiryLoading) {
                      return Column(
                        children: List.generate(
                          4,
                          (_) => Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: ShimmerLoading(
                              height: 20,
                              width: MediaQuery.of(context).size.width * 0.8,
                            ),
                          ),
                        ),
                      );
                    }

                    final result = provider.inquiryResult;
                    if (result == null) return const SizedBox.shrink();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Confirmation header
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.successBg,
                            borderRadius:
                                BorderRadius.circular(AppSpacing.borderRadius),
                            border: Border.all(
                              color: AppColors.success.withValues(alpha: 0.3),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.check_circle,
                                  color: AppColors.success, size: 24),
                              SizedBox(width: AppSpacing.sm),
                              Text(
                                'Data Pelanggan Ditemukan',
                                style: TextStyle(
                                  fontFamily: AppFonts.heading,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.success,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: AppSpacing.md),

                        // Customer details
                        _buildDetailRow('Nama Pelanggan',
                            result['customer_name']?.toString() ?? '-'),
                        _buildDetailRow('Nomor Pelanggan',
                            result['customer_number']?.toString() ?? '-'),
                        _buildDetailRow(
                            'Tagihan',
                            CurrencyFormatter.formatIdr(
                                result['amount']?.toString() ?? '0')),
                        if (result['admin_fee'] != null)
                          _buildDetailRow(
                              'Admin',
                              CurrencyFormatter.formatIdr(
                                  result['admin_fee']?.toString() ?? '0')),

                        const Divider(height: AppSpacing.lg),

                        // Total
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Bayar',
                              style: TextStyle(
                                fontFamily: AppFonts.heading,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              CurrencyFormatter.formatIdr(
                                  result['total']?.toString() ??
                                      result['amount']?.toString() ??
                                      '0'),
                              style: const TextStyle(
                                fontFamily: AppFonts.heading,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppColors.electricBlue,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: AppSpacing.lg),

                        // Action buttons
                        ElevatedButton(
                          onPressed: _navigateToPayment,
                          child: const Text('Bayar Sekarang'),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        OutlinedButton(
                          onPressed: () {
                            setState(() => _showInquiryResult = false);
                            context.read<ProductProvider>().clearInquiry();
                          },
                          child: const Text('Ubah Nomor'),
                        ),
                      ],
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontFamily: AppFonts.body,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
