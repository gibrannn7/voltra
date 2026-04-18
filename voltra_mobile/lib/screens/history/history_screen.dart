import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_constants.dart';
import '../../providers/transaction_provider.dart';
import '../../utils/currency_formatter.dart';
import '../../widgets/common/shimmer_loading.dart';
import '../../widgets/common/status_pill.dart';

/// Transaction history screen with status filter tabs.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _filters = const [null, 'success', 'processing', 'pending', 'failed'];
  final _filterLabels = const ['Semua', 'Berhasil', 'Proses', 'Pending', 'Gagal'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _filters.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadTransactions();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    final provider = context.read<TransactionProvider>();
    await provider.fetchTransactions(status: _filters[_tabController.index]);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Transaksi'),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.electricBlue,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.electricBlue,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontFamily: AppFonts.body,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          tabAlignment: TabAlignment.start,
          tabs: _filterLabels.map((l) => Tab(text: l)).toList(),
        ),
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: 6,
              itemBuilder: (context, index) => const Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.sm),
                child: ShimmerCard(),
              ),
            );
          }

          if (provider.transactions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 64,
                    color: AppColors.textTertiary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Text(
                    'Belum ada transaksi',
                    style: TextStyle(
                      fontFamily: AppFonts.heading,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: AppColors.electricBlue,
            onRefresh: _loadTransactions,
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: provider.transactions.length,
              itemBuilder: (context, index) {
                final tx = provider.transactions[index];
                return _buildTransactionCard(tx);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildTransactionCard(dynamic tx) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.historyDetail,
            arguments: tx,
          );
        },
        borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              // Category icon
              Container(
                width: 44,
                height: 44,
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

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx.productName ?? 'Produk',
                      style: const TextStyle(
                        fontFamily: AppFonts.body,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tx.customerNumber,
                      style: const TextStyle(
                        fontFamily: AppFonts.body,
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      CurrencyFormatter.formatRelative(tx.createdAt),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),

              // Amount + Status
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyFormatter.formatIdr(tx.totalAmount),
                    style: const TextStyle(
                      fontFamily: AppFonts.heading,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  StatusPill(status: tx.status),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
