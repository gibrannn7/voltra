import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';
import '../../config/app_constants.dart';

/// PIN entry screen used for transaction confirmation.
/// Security hardened: screenshot blocked, FLAG_SECURE enabled.
class PinScreen extends StatefulWidget {
  final String title;
  final String subtitle;
  final Future<bool> Function(String pin) onPinEntered;

  const PinScreen({
    super.key,
    this.title = 'Verifikasi PIN',
    this.subtitle = 'Masukkan 6 digit PIN Anda',
    required this.onPinEntered,
  });

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen>
    with SingleTickerProviderStateMixin {
  String _pin = '';
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _enableScreenSecurity();

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  Future<void> _enableScreenSecurity() async {
    try {
      await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
    } catch (_) {}
  }

  Future<void> _disableScreenSecurity() async {
    try {
      await FlutterWindowManager.clearFlags(FlutterWindowManager.FLAG_SECURE);
    } catch (_) {}
  }

  @override
  void dispose() {
    _disableScreenSecurity();
    _shakeController.dispose();
    super.dispose();
  }

  void _onKeyPressed(String key) {
    if (_isLoading) return;

    HapticFeedback.lightImpact();

    if (key == 'delete') {
      if (_pin.isNotEmpty) {
        setState(() {
          _pin = _pin.substring(0, _pin.length - 1);
          _hasError = false;
          _errorMessage = null;
        });
      }
      return;
    }

    if (_pin.length >= 6) return;

    setState(() {
      _pin += key;
      _hasError = false;
      _errorMessage = null;
    });

    if (_pin.length == 6) {
      _submitPin();
    }
  }

  Future<void> _submitPin() async {
    setState(() => _isLoading = true);

    final success = await widget.onPinEntered(_pin);

    if (!mounted) return;

    if (!success) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'PIN salah';
        _pin = '';
      });
      _shakeController.forward(from: 0);
      HapticFeedback.heavyImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.electricBlueDark,
              AppColors.electricBlue,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Back button
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: AppColors.white),
                ),
              ),

              const Spacer(flex: 1),

              // Lock icon
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_outline,
                  size: 36,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Title
              Text(
                widget.title,
                style: const TextStyle(
                  fontFamily: AppFonts.heading,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                widget.subtitle,
                style: TextStyle(
                  fontFamily: AppFonts.body,
                  fontSize: 14,
                  color: AppColors.white.withValues(alpha: 0.7),
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // PIN dots
              AnimatedBuilder(
                animation: _shakeAnimation,
                builder: (context, child) {
                  final shakeDx =
                      _shakeAnimation.value * 10 * (1 - _shakeAnimation.value);
                  return Transform.translate(
                    offset: Offset(
                      shakeDx * ((_shakeController.value * 10).toInt().isEven ? 1 : -1),
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
                      width: isFilled ? 18 : 16,
                      height: isFilled ? 18 : 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _hasError
                            ? AppColors.danger
                            : isFilled
                                ? AppColors.energyYellow
                                : AppColors.white.withValues(alpha: 0.3),
                        border: Border.all(
                          color: _hasError
                              ? AppColors.danger
                              : isFilled
                                  ? AppColors.energyYellow
                                  : AppColors.white.withValues(alpha: 0.5),
                          width: 2,
                        ),
                      ),
                    );
                  }),
                ),
              ),

              // Error message
              if (_hasError && _errorMessage != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: AppColors.energyYellow,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],

              // Loading
              if (_isLoading) ...[
                const SizedBox(height: AppSpacing.md),
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.white,
                  ),
                ),
              ],

              const Spacer(flex: 1),

              // Numpad
              _buildNumpad(),

              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumpad() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Column(
        children: [
          _buildNumRow(['1', '2', '3']),
          _buildNumRow(['4', '5', '6']),
          _buildNumRow(['7', '8', '9']),
          _buildNumRow(['', '0', 'delete']),
        ],
      ),
    );
  }

  Widget _buildNumRow(List<String> keys) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: keys.map((key) {
          if (key.isEmpty) {
            return const SizedBox(width: 72, height: 56);
          }

          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _onKeyPressed(key),
              borderRadius: BorderRadius.circular(36),
              splashColor: AppColors.white.withValues(alpha: 0.1),
              child: Container(
                width: 72,
                height: 56,
                alignment: Alignment.center,
                child: key == 'delete'
                    ? const Icon(
                        Icons.backspace_outlined,
                        color: AppColors.white,
                        size: 24,
                      )
                    : Text(
                        key,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w500,
                          color: AppColors.white,
                          fontFamily: AppFonts.heading,
                        ),
                      ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
