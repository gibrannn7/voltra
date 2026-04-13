import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_constants.dart';
import '../../providers/wallet_provider.dart';
import '../../utils/currency_formatter.dart';
import '../../widgets/common/shimmer_loading.dart';

/// Wallet screen: balance display, top-up, and mutation history.
class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  @override
  void initState() {
    super.initState();
    context.read<WalletProvider>().fetchBalance();
    context.read<WalletProvider>().fetchMutations();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dompet Voltra'),
        automaticallyImplyLeading: false,
      ),
      body: Consumer<WalletProvider>(
        builder: (context, wallet, _) {
          return RefreshIndicator(
            color: AppColors.electricBlue,
            onRefresh: () async {
              await wallet.fetchBalance();
              await wallet.fetchMutations();
            },
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                // ─── Balance Card ────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.electricBlueDark,
                        AppColors.electricBlue,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.electricBlue.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Saldo Tersedia',
                        style: TextStyle(
                          fontFamily: AppFonts.body,
                          fontSize: 13,
                          color: AppColors.white.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      wallet.isBalanceLoading
                          ? const ShimmerLoading(height: 32, width: 160)
                          : Text(
                              CurrencyFormatter.formatIdr(wallet.balance),
                              style: const TextStyle(
                                fontFamily: AppFonts.heading,
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                                color: AppColors.white,
                              ),
                            ),
                      const SizedBox(height: AppSpacing.md),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // TODO: Top-Up flow
                          },
                          icon: const Icon(Icons.add, color: AppColors.electricBlue),
                          label: const Text(
                            'Top-Up Saldo',
                            style: TextStyle(color: AppColors.electricBlue),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppSpacing.borderRadius,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // ─── Mutation History ─────────────────
                const Text(
                  'Riwayat Mutasi',
                  style: TextStyle(
                    fontFamily: AppFonts.heading,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                if (wallet.isMutationsLoading)
                  ...List.generate(
                    5,
                    (_) => const Padding(
                      padding: EdgeInsets.only(bottom: AppSpacing.sm),
                      child: ShimmerCard(),
                    ),
                  ),

                if (!wallet.isMutationsLoading && wallet.mutations.isEmpty)
                  _buildEmptyState(),

                if (!wallet.isMutationsLoading)
                  ...wallet.mutations.map((m) => _buildMutationItem(m)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
        child: Column(
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 56,
              color: AppColors.textTertiary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'Belum ada mutasi',
              style: TextStyle(
                fontFamily: AppFonts.heading,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMutationItem(Map<String, dynamic> mutation) {
    final isCredit = mutation['type'] == 'credit';
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (isCredit ? AppColors.success : AppColors.danger)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                color: isCredit ? AppColors.success : AppColors.danger,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mutation['description'] ?? (isCredit ? 'Top-Up' : 'Pembayaran'),
                    style: const TextStyle(
                      fontFamily: AppFonts.body,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    CurrencyFormatter.formatRelative(
                        mutation['created_at'] as String?),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${isCredit ? '+' : '-'}${CurrencyFormatter.formatIdr(mutation['amount'])}',
              style: TextStyle(
                fontFamily: AppFonts.heading,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isCredit ? AppColors.success : AppColors.danger,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
