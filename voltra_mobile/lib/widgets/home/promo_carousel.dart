import 'package:flutter/material.dart';
import '../../config/app_constants.dart';

/// Dynamic promo carousel on the home screen.
/// Displays promotional banners with auto-scroll.
class PromoCarousel extends StatefulWidget {
  const PromoCarousel({super.key});

  @override
  State<PromoCarousel> createState() => _PromoCarouselState();
}

class _PromoCarouselState extends State<PromoCarousel> {
  final PageController _pageController = PageController(viewportFraction: 0.9);
  int _currentPage = 0;

  // Static promo data (would come from API in production)
  final List<_PromoData> _promos = const [
    _PromoData(
      title: 'Cashback 10%',
      subtitle: 'Bayar tagihan PLN & dapatkan cashback hingga Rp 25.000',
      gradient: [Color(0xFF2563EB), Color(0xFF7C3AED)],
      icon: Icons.bolt_rounded,
    ),
    _PromoData(
      title: 'Promo Pulsa',
      subtitle: 'Isi pulsa semua operator dengan diskon spesial hari ini!',
      gradient: [Color(0xFF059669), Color(0xFF10B981)],
      icon: Icons.phone_android_rounded,
    ),
    _PromoData(
      title: 'Top-Up E-Wallet',
      subtitle: 'GoPay, OVO, ShopeePay — top-up tanpa biaya admin',
      gradient: [Color(0xFFEA580C), Color(0xFFF59E0B)],
      icon: Icons.account_balance_wallet_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    Future.delayed(const Duration(seconds: 4), () {
      if (!mounted) return;
      final nextPage = (_currentPage + 1) % _promos.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
      _startAutoScroll();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 140,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemCount: _promos.length,
            itemBuilder: (context, index) {
              final promo = _promos[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: promo.gradient,
                    ),
                    borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
                    boxShadow: [
                      BoxShadow(
                        color: promo.gradient[0].withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Background icon
                      Positioned(
                        right: -20,
                        bottom: -20,
                        child: Icon(
                          promo.icon,
                          size: 120,
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      // Content
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                promo.title,
                                style: const TextStyle(
                                  fontFamily: AppFonts.heading,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              promo.subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: AppFonts.body,
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.9),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: AppSpacing.sm),

        // Page indicator dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_promos.length, (index) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _currentPage == index ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: _currentPage == index
                    ? AppColors.electricBlue
                    : AppColors.divider,
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _PromoData {
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final IconData icon;

  const _PromoData({
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.icon,
  });
}
