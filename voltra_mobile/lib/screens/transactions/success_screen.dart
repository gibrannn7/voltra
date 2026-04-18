import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/transaction_provider.dart';
import '../../utils/currency_formatter.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';
import '../../widgets/transactions/printer_setup_sheet.dart';

class SuccessScreen extends StatefulWidget {
  const SuccessScreen({super.key});

  @override
  State<SuccessScreen> createState() => _SuccessScreenState();
}

class _SuccessScreenState extends State<SuccessScreen> {
  @override
  void initState() {
    super.initState();
    _secureScreen();
  }

  @override
  void dispose() {
    _unsecureScreen();
    super.dispose();
  }

  Future<void> _secureScreen() async {
    await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
  }

  Future<void> _unsecureScreen() async {
    await FlutterWindowManager.clearFlags(FlutterWindowManager.FLAG_SECURE);
  }

  void _showPrinterSheet(BuildContext context, dynamic transaction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PrinterSetupSheet(transaction: transaction),
    );
  }

  @override
  Widget build(BuildContext context) {
    final transaction = context.read<TransactionProvider>().currentTransaction;

    if (transaction == null) {
      return const Scaffold(body: Center(child: Text('Data transaksi tidak ditemukan.')));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 80),
              const SizedBox(height: 24),
              const Text('Transaksi Berhasil', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 20)),
              const SizedBox(height: 32),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
                child: Column(
                  children: [
                    Text(CurrencyFormatter.formatIdr(transaction.totalAmount), style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 24, color: Color(0xFF2563EB))),
                    const SizedBox(height: 24),
                    _buildRow('Tujuan', transaction.customerNumber),
                    const SizedBox(height: 12),
                    _buildRow('SN / Token', transaction.snToken ?? 'Dalam Proses'),
                    const SizedBox(height: 12),
                    _buildRow('Waktu', transaction.createdAt ?? '-'),
                    const SizedBox(height: 12),
                    _buildRow('ID Trx', transaction.id.toString()),
                  ],
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _showPrinterSheet(context, transaction),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF2563EB)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Cetak Struk', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, color: Color(0xFF2563EB))),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        context.read<TransactionProvider>().clearState();
                        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                      ),
                      child: const Text('Beranda', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF64748B))),
        Text(value, style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500, fontSize: 12)),
      ],
    );
  }
}