import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/transaction_provider.dart';
import '../../utils/currency_formatter.dart';
import '../../widgets/common/status_pill.dart';
import '../../widgets/transactions/printer_setup_sheet.dart';
import '../../config/app_constants.dart';

class HistoryDetailScreen extends StatelessWidget {
  const HistoryDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final transaction = context.watch<TransactionProvider>().currentTransaction;

    if (transaction == null) {
      return Scaffold(
        appBar: AppBar(backgroundColor: Colors.white, elevation: 0, iconTheme: const IconThemeData(color: Colors.black)),
        body: const Center(child: Text('Detail tidak ditemukan')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Detail Transaksi', style: TextStyle(fontFamily: 'Inter', color: Colors.black, fontSize: 16)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
              child: Column(
                children: [
                  StatusPill(status: transaction.status),
                  const SizedBox(height: 16),
                  Text(CurrencyFormatter.formatIdr(transaction.totalAmount), style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 24)),
                  const SizedBox(height: 24),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 16),
                  _buildDetailRow('ID Transaksi', transaction.id.toString()),
                  const SizedBox(height: 12),
                  _buildDetailRow('Tujuan', transaction.customerNumber),
                  const SizedBox(height: 12),
                  _buildDetailRow('Metode', transaction.paymentMethod ?? '-'),
                  const SizedBox(height: 12),
                  _buildDetailRow('Waktu', transaction.createdAt ?? '-'),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                // Tombol Cetak Struk (Outline Style)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (ctx) => PrinterSetupSheet(transaction: transaction),
                      );
                    },
                    icon: const Icon(Icons.print_outlined, color: AppColors.electricBlue, size: 20),
                    label: const Text('Cetak Struk', style: TextStyle(fontFamily: AppFonts.body, fontWeight: FontWeight.w600, color: AppColors.electricBlue)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.electricBlue),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSm)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Tombol Bagikan Struk (Solid Style)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Share.share('Struk Voltra App\nTujuan: ${transaction.customerNumber}\nSN: ${transaction.snToken ?? "-"}');
                    },
                    icon: const Icon(Icons.share_outlined, color: Colors.white, size: 20),
                    label: const Text('Bagikan Struk', style: TextStyle(fontFamily: AppFonts.body, fontWeight: FontWeight.w600, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.electricBlue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSm)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 2, child: Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF64748B)))),
        Expanded(flex: 3, child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500, fontSize: 12))),
      ],
    );
  }
}