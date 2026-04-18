import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';
import 'package:provider/provider.dart';
import 'package:voltra_mobile/config/app_constants.dart';
import 'package:voltra_mobile/providers/transaction_provider.dart';

/// PIN validation overlay for transaction security.
/// Implements FLAG_SECURE to block screenshots/screen recording.
/// Auto-submits on 6th digit, resets on failure,
/// and redirects to CS WhatsApp on account suspension.
class PinValidationOverlay extends StatefulWidget {
  final int productId;
  final String customerNumber;
  final String paymentMethod;

  const PinValidationOverlay({
    super.key,
    required this.productId,
    required this.customerNumber,
    required this.paymentMethod,
  });

  /// Show PIN overlay as a modal bottom sheet.
  static Future<void> show(
    BuildContext context, {
    required int productId,
    required String customerNumber,
    required String paymentMethod,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PinValidationOverlay(
        productId: productId,
        customerNumber: customerNumber,
        paymentMethod: paymentMethod,
      ),
    );
  }

  @override
  State<PinValidationOverlay> createState() => _PinValidationOverlayState();
}

class _PinValidationOverlayState extends State<PinValidationOverlay>
    with SingleTickerProviderStateMixin {
  String _pin = '';
  bool _isLoading = false;
  bool _hasError = false;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _secureScreen();

    // Shake animation for error feedback
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 12).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _unsecureScreen();
    super.dispose();
  }

  Future<void> _secureScreen() async {
    try {
      await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
    } catch (_) {
      // Silently fail on platforms that don't support FLAG_SECURE
    }
  }

  Future<void> _unsecureScreen() async {
    try {
      await FlutterWindowManager.clearFlags(FlutterWindowManager.FLAG_SECURE);
    } catch (_) {}
  }

  void _onKeypadTap(String value) {
    if (_pin.length >= 6 || _isLoading) return;

    HapticFeedback.mediumImpact();
    setState(() {
      _pin += value;
      _hasError = false;
    });

    if (_pin.length == 6) {
      _submitPin();
    }
  }

  void _onBackspace() {
    if (_pin.isEmpty || _isLoading) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
      _hasError = false;
    });
  }

  Future<void> _submitPin() async {
    setState(() => _isLoading = true);

    // Generate idempotency key
    final idempotencyKey =
        'trx_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(99999).toString().padLeft(5, '0')}';

    final provider = context.read<TransactionProvider>();
    final success = await provider.createTransaction(
      productId: widget.productId,
      customerNumber: widget.customerNumber,
      paymentMethod: widget.paymentMethod,
      pin: _pin,
      idempotencyKey: idempotencyKey,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      HapticFeedback.mediumImpact();
      Navigator.pop(context); // Close overlay
      Navigator.pushReplacementNamed(context, AppRoutes.success);
    } else {
      final errorMsg =
          provider.errorMessage ?? AppStrings.transactionFailed;

      // Shake animation
      _shakeController.forward(from: 0);
      setState(() {
        _pin = '';
        _hasError = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            errorMsg,
            style: const TextStyle(fontFamily: AppFonts.body),
          ),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSm),
          ),
        ),
      );

      // If account suspended due to 3x wrong PIN
      if (errorMsg.toLowerCase().contains('suspen') ||
          errorMsg.toLowerCase().contains('blokir') ||
          errorMsg.toLowerCase().contains('locked')) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pop(context);
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.login,
              (route) => false,
            );
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.lg,
            horizontal: AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Security lock icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.electricBlue.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_rounded,
                  color: AppColors.electricBlue,
                  size: 28,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              const Text(
                'Masukkan PIN',
                style: TextStyle(
                  fontFamily: AppFonts.heading,
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              const Text(
                'Validasi keamanan untuk melanjutkan transaksi',
                style: TextStyle(
                  fontFamily: AppFonts.body,
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // PIN dots with shake animation
              AnimatedBuilder(
                animation: _shakeAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(
                      _shakeController.isAnimating
                          ? sin(_shakeAnimation.value * pi * 3) * 8
                          : 0,
                      0,
                    ),
                    child: child,
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(6, (index) {
                    final isFilled = index < _pin.length;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      width: isFilled ? 18 : 14,
                      height: isFilled ? 18 : 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _hasError
                            ? AppColors.danger
                            : isFilled
                                ? AppColors.electricBlue
                                : AppColors.divider,
                        boxShadow: isFilled
                            ? [
                                BoxShadow(
                                  color: (_hasError
                                          ? AppColors.danger
                                          : AppColors.electricBlue)
                                      .withValues(alpha: 0.3),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Loading or Keypad
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                  child: Column(
                    children: [
                      SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          color: AppColors.electricBlue,
                          strokeWidth: 3,
                        ),
                      ),
                      SizedBox(height: AppSpacing.md),
                      Text(
                        'Memproses transaksi...',
                        style: TextStyle(
                          fontFamily: AppFonts.body,
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              else
                _buildKeypad(),

              const SizedBox(height: AppSpacing.md),

              // Cancel button
              TextButton(
                onPressed: _isLoading ? null : () => Navigator.pop(context),
                child: const Text(
                  'Batalkan',
                  style: TextStyle(
                    fontFamily: AppFonts.body,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    return Column(
      children: [
        for (final row in [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
          ['', '0', 'backspace'],
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: row.map((key) {
                if (key == '') {
                  return const SizedBox(width: 72, height: 72);
                }
                if (key == 'backspace') {
                  return _buildKeypadButton(
                    child: const Icon(
                      Icons.backspace_outlined,
                      color: AppColors.textSecondary,
                      size: 22,
                    ),
                    onTap: _onBackspace,
                  );
                }
                return _buildKeypadButton(
                  child: Text(
                    key,
                    style: const TextStyle(
                      fontFamily: AppFonts.heading,
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  onTap: () => _onKeypadTap(key),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildKeypadButton({
    required Widget child,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(36),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(36),
        child: SizedBox(
          width: 72,
          height: 72,
          child: Center(child: child),
        ),
      ),
    );
  }
}