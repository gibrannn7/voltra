import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/transaction_provider.dart';
import '../../config/app_constants.dart';
import '../common/shimmer_loading.dart';

class SmartReminderCard extends StatefulWidget {
  const SmartReminderCard({super.key});

  @override
  State<SmartReminderCard> createState() => _SmartReminderCardState();
}

class _SmartReminderCardState extends State<SmartReminderCard> {
  bool _isLoading = true;
  bool _hasUnpaidPln = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPlnStatus();
    });
  }

  Future<void> _checkPlnStatus() async {
    final now = DateTime.now();
    
    // Logika: Jika tanggal masih <= 20, tidak perlu tampilkan pengingat
    if (now.day <= 20) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasUnpaidPln = false;
        });
      }
      return;
    }

    final provider = context.read<TransactionProvider>();
    
    // Pastikan transaksi sudah termuat
    if (provider.transactions.isEmpty && !provider.isLoading) {
      await provider.fetchTransactions();
    }

    bool foundPaidPlnThisMonth = false;

    // Memeriksa riwayat transaksi bulan ini
    for (var trx in provider.transactions) {
      if (trx.status == 'success' || trx.status == 'processing') {
        final productName = trx.productName?.toLowerCase() ?? '';
        final customerNumber = trx.customerNumber;

        if (productName.contains('pln') || productName.contains('listrik') || customerNumber.isNotEmpty) {
          DateTime? trxDate;
          if (trx.createdAt != null) {
            try {
              trxDate = DateTime.parse(trx.createdAt!);
            } catch (_) {}
          }

          if (trxDate != null && trxDate.month == now.month && trxDate.year == now.year) {
            foundPaidPlnThisMonth = true;
            break;
          }
        }
      }
    }

    if (mounted) {
      setState(() {
        _hasUnpaidPln = !foundPaidPlnThisMonth;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: ShimmerLoading(width: double.infinity, height: 80, borderRadius: 12),
      );
    }

    if (!_hasUnpaidPln) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2), // Soft Red
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEF4444)), // Solid Red
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Tagihan Listrik Belum Dibayar',
                  style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, color: Color(0xFF991B1B)),
                ),
                SizedBox(height: 4),
                Text(
                  'Batas pembayaran tanggal 20. Segera lunasi untuk menghindari denda.',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFFB91C1C)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.categoryProducts);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Bayar', style: TextStyle(fontFamily: 'Inter', color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
          )
        ],
      ),
    );
  }
}