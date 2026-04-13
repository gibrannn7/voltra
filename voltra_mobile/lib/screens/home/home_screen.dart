import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../config/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../utils/currency_formatter.dart';
import '../../widgets/common/shimmer_loading.dart';
import '../../widgets/home/promo_carousel.dart';
import '../../widgets/home/quick_action_grid.dart';
import '../../widgets/home/smart_reminder_card.dart';

/// Home dashboard screen.
/// Features: balance header with Voltra Points, promo carousel,
/// quick action grid, and smart reminder cards.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final walletProvider = context.read<WalletProvider>();
    final productProvider = context.read<ProductProvider>();

    await Future.wait([
      walletProvider.fetchBalance(),
      productProvider.fetchCategories(),
    ]);
  }

  Future<void> _onRefresh() async {
    final walletProvider = context.read<WalletProvider>();
    final productProvider = context.read<ProductProvider>();

    await Future.wait([
      walletProvider.fetchBalance(),
      productProvider.refreshCategories(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        body: RefreshIndicator(
          color: AppColors.electricBlue,
          onRefresh: _onRefresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              // ─── Header with Balance ───────────────────
              SliverToBoxAdapter(child: _buildHeader()),

              // ─── Promo Carousel ────────────────────────
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: AppSpacing.md),
                  child: PromoCarousel(),
                ),
              ),

              // ─── Quick Action Grid ─────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Layanan',
                        style: TextStyle(
                          fontFamily: AppFonts.heading,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Consumer<ProductProvider>(
                        builder: (context, provider, _) {
                          if (provider.isCategoriesLoading) {
                            return const ShimmerGrid(itemCount: 8);
                          }
                          return QuickActionGrid(
                            categories: provider.categories,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // ─── Smart Reminder Card ───────────────────
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: SmartReminderCard(),
                ),
              ),

              // ─── Bottom padding ────────────────────────
              const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Consumer2<AuthProvider, WalletProvider>(
      builder: (context, auth, wallet, _) {
        final user = auth.user;

        return Container(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 16,
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            bottom: AppSpacing.lg,
          ),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.electricBlueDark,
                AppColors.electricBlue,
                AppColors.electricBlueLight,
              ],
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(28),
              bottomRight: Radius.circular(28),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: greeting + notification bell
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Halo, ${user?.name.split(' ').first ?? 'User'} 👋',
                        style: const TextStyle(
                          fontFamily: AppFonts.heading,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        AppStrings.appTagline,
                        style: TextStyle(
                          fontFamily: AppFonts.body,
                          fontSize: 13,
                          color: AppColors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                  // Notification bell
                  Material(
                    color: AppColors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () {
                        Navigator.pushNamed(context, AppRoutes.notifications);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.notifications_outlined,
                          color: AppColors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.lg),

              // Balance card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.white.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    // Balance section
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Saldo Dompet',
                            style: TextStyle(
                              fontFamily: AppFonts.body,
                              fontSize: 12,
                              color: AppColors.white.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 4),
                          wallet.isBalanceLoading
                              ? const ShimmerLoading(
                                  height: 28,
                                  width: 120,
                                )
                              : Text(
                                  CurrencyFormatter.formatIdr(wallet.balance),
                                  style: const TextStyle(
                                    fontFamily: AppFonts.heading,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.white,
                                  ),
                                ),
                        ],
                      ),
                    ),

                    // Divider
                    Container(
                      width: 1,
                      height: 40,
                      color: AppColors.white.withValues(alpha: 0.2),
                    ),

                    const SizedBox(width: AppSpacing.md),

                    // Points section
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Voltra Points',
                          style: TextStyle(
                            fontFamily: AppFonts.body,
                            fontSize: 12,
                            color: AppColors.white.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.stars_rounded,
                              size: 20,
                              color: AppColors.energyYellow,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${user?.voltraPoints ?? 0}',
                              style: const TextStyle(
                                fontFamily: AppFonts.heading,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppColors.energyYellow,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
