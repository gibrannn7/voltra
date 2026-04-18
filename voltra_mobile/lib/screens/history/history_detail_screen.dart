import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:voltra_mobile/config/app_constants.dart';
import 'package:voltra_mobile/models/transaction_model.dart';
import 'package:voltra_mobile/providers/transaction_provider.dart';
import 'package:voltra_mobile/utils/currency_formatter.dart';
import 'package:voltra_mobile/widgets/common/shimmer_loading.dart';
import 'package:voltra_mobile/widgets/common/status_pill.dart';
import 'package:voltra_mobile/widgets/transactions/printer_setup_sheet.dart';

/// Transaction history detail screen.
/// strictly adheres to AppColors, Decimal precision, Shimmers, and Absolute Imports.
class HistoryDetailScreen extends StatefulWidget {
  const HistoryDetailScreen({super.key});

  @override
  State<HistoryDetailScreen> createState() => _HistoryDetailScreenState();
}

class _HistoryDetailScreenState extends State<HistoryDetailScreen> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is TransactionModel) {
      context.read<TransactionProvider>().setCurrentTransaction(args);
    }
  }

  void _openCsWhatsApp(TransactionModel tx) async {
    final message = Uri.encodeComponent(
      'Halo CS Voltra, saya butuh bantuan untuk transaksi:\n'
      'ID: #${tx.id}\n'
      'Produk: ${tx.productName ?? '-'}\n'
      'Tujuan: ${tx.customerNumber}\n'
      'Status: ${tx.status}\n'
      'Error: Transaksi gagal/bermasalah',
    );
    final url = Uri.parse('https://wa.me/6281234567890?text=$message');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _shareReceipt(TransactionModel tx) {
    final receipt = '''
Voltra App - Bukti Transaksi
${'=' * 30}
ID Transaksi : #${tx.id}
Produk       : ${tx.productName ?? '-'}
Tujuan       : ${tx.customerNumber}
SN/Token     : ${tx.snToken ?? '-'}
Total        : ${CurrencyFormatter.formatIdr(tx.totalAmount)}
Status       : ${tx.status.toUpperCase()}
Waktu        : ${CurrencyFormatter.formatDate(tx.createdAt)}
${'=' * 30}
''';
    Share.share(receipt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Detail Transaksi'),
        actions: [
          IconButton(
            onPressed: () {
              final tx = context.read<TransactionProvider>().currentTransaction;
              if (tx != null) _shareReceipt(tx);
            },
            icon: const Icon(Icons.share_outlined, size: 20),
          ),
        ],
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, provider, _) {
          if (provider.state == TransactionState.loading) {
            return Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: List.generate(
                  4,
                  (_) => const Padding(
                    padding: EdgeInsets.only(bottom: AppSpacing.sm),
                    child: ShimmerCard(),
                  ),
                ),
              ),
            );
          }

          final tx = provider.currentTransaction;
          if (tx == null) {
            return const Center(
              child: Text(
                'Detail tidak ditemukan',
                style: TextStyle(fontFamily: AppFonts.body),
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    children: [
                      // Status + amount card
                      _buildStatusCard(tx),
                      const SizedBox(height: AppSpacing.md),

                      // Transaction detail card
                      _buildDetailCard(tx),
                      const SizedBox(height: AppSpacing.md),

                      // SN/Token card (if success)
                      if (tx.snToken != null && tx.snToken!.isNotEmpty)
                        _buildTokenCard(tx),

                      // CS WhatsApp button (for failed transactions)
                      if (tx.status == 'failed') ...[
                        const SizedBox(height: AppSpacing.md),
                        _buildCsButton(tx),
                      ],
                    ],
                  ),
                ),
              ),

              // Bottom action bar
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
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (ctx) =>
                                  PrinterSetupSheet(transaction: tx),
                            );
                          },
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
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _shareReceipt(tx),
                          icon: const Icon(Icons.share_outlined,
                              size: 18, color: AppColors.white),
                          label: const Text('Bagikan'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(0, 48),
                          ),
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

  Widget _buildStatusCard(TransactionModel tx) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
        border: Border.all(color: AppColors.divider, width: 0.5),
      ),
      child: Column(
        children: [
          StatusPill(status: tx.status),
          const SizedBox(height: AppSpacing.md),
          Text(
            CurrencyFormatter.formatIdr(tx.totalAmount),
            style: const TextStyle(
              fontFamily: AppFonts.heading,
              fontWeight: FontWeight.w700,
              fontSize: 28,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            CurrencyFormatter.formatDate(tx.createdAt),
            style: const TextStyle(
              fontFamily: AppFonts.body,
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(TransactionModel tx) {
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
            'Detail Transaksi',
            style: TextStyle(
              fontFamily: AppFonts.body,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textTertiary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildRow('ID Transaksi', '#${tx.id}'),
          _buildRow('Produk', tx.productName ?? '-'),
          _buildRow('Tujuan', tx.customerNumber),
          if (tx.customerName != null)
            _buildRow('Nama Pelanggan', tx.customerName!),
          _buildRow('Metode Bayar', tx.paymentMethod ?? '-'),
          if (tx.midtransOrderId != null)
            _buildRow('Midtrans ID', tx.midtransOrderId!),
          if (tx.digiflazzRefId != null)
            _buildRow('Digiflazz Ref', tx.digiflazzRefId!),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Divider(height: 1, color: AppColors.divider),
          ),

          _buildRow('Harga Dasar',
              CurrencyFormatter.formatIdr(tx.basePrice ?? '0')),
          _buildRow('Biaya Admin',
              CurrencyFormatter.formatIdr(tx.adminFee ?? '0')),
          if (tx.discount != null && tx.discount != '0' && tx.discount != '0.00')
            _buildRow('Diskon',
                '-${CurrencyFormatter.formatIdr(tx.discount!)}',
                valueColor: AppColors.success),
          _buildRow('Total',
              CurrencyFormatter.formatIdr(tx.totalAmount),
              isBold: true, valueColor: AppColors.electricBlue),
        ],
      ),
    );
  }

  Widget _buildTokenCard(TransactionModel tx) {
    return Container(
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
        borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
        border: Border.all(
          color: AppColors.electricBlue.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
          const SizedBox(height: AppSpacing.sm),
          SelectableText(
            tx.snToken!,
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
    );
  }

  Widget _buildCsButton(TransactionModel tx) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _openCsWhatsApp(tx),
        icon: const Icon(Icons.headset_mic_outlined,
            size: 18, color: AppColors.success),
        label: const Text(
          'Hubungi CS via WhatsApp',
          style: TextStyle(
            fontFamily: AppFonts.body,
            fontWeight: FontWeight.w600,
            color: AppColors.success,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.success),
          minimumSize: const Size(0, 48),
        ),
      ),
    );
  }

  Widget _buildRow(
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: AppFonts.body,
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: isBold ? AppFonts.heading : AppFonts.body,
                fontSize: isBold ? 15 : 13,
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
                color: valueColor ?? AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}