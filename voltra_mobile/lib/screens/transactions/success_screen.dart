import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:voltra_mobile/config/app_constants.dart';
import 'package:voltra_mobile/providers/transaction_provider.dart';
import 'package:voltra_mobile/utils/currency_formatter.dart';
import 'package:voltra_mobile/widgets/transactions/printer_setup_sheet.dart';

/// Transaction success screen.
/// Displays Lottie animation, SN/Token from Digiflazz,
/// full receipt details, and print/share actions.
class SuccessScreen extends StatefulWidget {
  const SuccessScreen({super.key});

  @override
  State<SuccessScreen> createState() => _SuccessScreenState();
}

class _SuccessScreenState extends State<SuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _lottieController;

  @override
  void initState() {
    super.initState();
    _secureScreen();
    _lottieController = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _lottieController.dispose();
    _unsecureScreen();
    super.dispose();
  }

  Future<void> _secureScreen() async {
    try {
      await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
    } catch (_) {}
  }

  Future<void> _unsecureScreen() async {
    try {
      await FlutterWindowManager.clearFlags(FlutterWindowManager.FLAG_SECURE);
    } catch (_) {}
  }

  void _showPrinterSheet(dynamic transaction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PrinterSetupSheet(transaction: transaction),
    );
  }

  void _shareReceipt(dynamic tx) {
    final receipt = '''
Voltra App - Bukti Transaksi
${'=' * 30}
ID Transaksi : #${tx.id}
Produk       : ${tx.productName ?? '-'}
Tujuan       : ${tx.customerNumber}
SN/Token     : ${tx.snToken ?? 'Dalam Proses'}
Total        : ${CurrencyFormatter.formatIdr(tx.totalAmount)}
Waktu        : ${CurrencyFormatter.formatDate(tx.createdAt)}
${'=' * 30}
Terima kasih telah menggunakan Voltra App.
''';
    Share.share(receipt);
  }

  void _copyToken(String token) {
    Clipboard.setData(ClipboardData(text: token));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Token berhasil disalin',
          style: TextStyle(fontFamily: AppFonts.body),
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSm),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final transaction =
        context.read<TransactionProvider>().currentTransaction;

    if (transaction == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Transaksi')),
        body: const Center(
          child: Text(
            'Data transaksi tidak ditemukan.',
            style: TextStyle(fontFamily: AppFonts.body),
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    children: [
                      const SizedBox(height: AppSpacing.lg),

                      // Lottie success animation
                      SizedBox(
                        width: 120,
                        height: 120,
                        child: Lottie.asset(
                          AppAssets.lottieSuccess,
                          controller: _lottieController,
                          onLoaded: (composition) {
                            _lottieController
                              ..duration = composition.duration
                              ..forward();
                          },
                          errorBuilder: (context, error, stackTrace) {
                            // Fallback if Lottie file not found
                            return Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.success,
                                size: 64,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      const Text(
                        'Transaksi Berhasil',
                        style: TextStyle(
                          fontFamily: AppFonts.heading,
                          fontWeight: FontWeight.w700,
                          fontSize: 22,
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      const Text(
                        'Pembayaran telah diproses dengan sukses',
                        style: TextStyle(
                          fontFamily: AppFonts.body,
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Amount display
                      Text(
                        CurrencyFormatter.formatIdr(transaction.totalAmount),
                        style: const TextStyle(
                          fontFamily: AppFonts.heading,
                          fontWeight: FontWeight.w700,
                          fontSize: 28,
                          color: AppColors.electricBlue,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // SN/Token card (if available)
                      if (transaction.snToken != null &&
                          transaction.snToken!.isNotEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSpacing.md),
                          margin: const EdgeInsets.only(bottom: AppSpacing.md),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.electricBlue.withValues(alpha: 0.05),
                                AppColors.electricBlue.withValues(alpha: 0.02),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(
                                AppSpacing.borderRadius),
                            border: Border.all(
                              color:
                                  AppColors.electricBlue.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'SN / Token',
                                    style: TextStyle(
                                      fontFamily: AppFonts.body,
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () =>
                                        _copyToken(transaction.snToken!),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.sm,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.electricBlue
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.copy_rounded,
                                              size: 14,
                                              color: AppColors.electricBlue),
                                          SizedBox(width: 4),
                                          Text(
                                            'Salin',
                                            style: TextStyle(
                                              fontFamily: AppFonts.body,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.electricBlue,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                transaction.snToken!,
                                style: const TextStyle(
                                  fontFamily: AppFonts.heading,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.electricBlue,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Receipt detail card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.borderRadius),
                          border:
                              Border.all(color: AppColors.divider, width: 0.5),
                        ),
                        child: Column(
                          children: [
                            _buildReceiptRow('ID Transaksi',
                                '#${transaction.id}'),
                            _buildReceiptRow('Produk',
                                transaction.productName ?? '-'),
                            _buildReceiptRow(
                                'Tujuan', transaction.customerNumber),
                            _buildReceiptRow('Metode Bayar',
                                transaction.paymentMethod ?? '-'),
                            _buildReceiptRow('Waktu',
                                CurrencyFormatter.formatDate(
                                    transaction.createdAt)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom action buttons
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  boxShadow: [
                    BoxShadow(
                      color:
                          AppColors.textPrimary.withValues(alpha: 0.06),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      // Print button
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              _showPrinterSheet(transaction),
                          icon: const Icon(Icons.print_outlined,
                              size: 18, color: AppColors.electricBlue),
                          label: const Text('Cetak Struk'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.electricBlue,
                            side: const BorderSide(
                                color: AppColors.electricBlue),
                            minimumSize: const Size(0, 48),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),

                      // Share button
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              _shareReceipt(transaction),
                          icon: const Icon(Icons.share_outlined,
                              size: 18, color: AppColors.electricBlue),
                          label: const Text('Bagikan'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.electricBlue,
                            side: const BorderSide(
                                color: AppColors.electricBlue),
                            minimumSize: const Size(0, 48),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),

                      // Home button
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            context
                                .read<TransactionProvider>()
                                .clearState();
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              AppRoutes.home,
                              (route) => false,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(0, 48),
                          ),
                          child: const Text('Beranda'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: AppFonts.body,
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontFamily: AppFonts.body,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}