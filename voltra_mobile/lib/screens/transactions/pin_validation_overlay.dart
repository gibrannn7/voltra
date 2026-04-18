import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';
import 'dart:math';
import '../../providers/transaction_provider.dart';

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

  static Future<void> show(BuildContext context, {
    required int productId,
    required String customerNumber,
    required String paymentMethod,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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

class _PinValidationOverlayState extends State<PinValidationOverlay> {
  String _pin = '';
  bool _isLoading = false;

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

  void _onKeypadTap(String value) {
    if (_pin.length < 6) {
      setState(() {
        _pin += value;
      });
      if (_pin.length == 6) {
        _submitPin();
      }
    }
  }

  void _onBackspace() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
      });
    }
  }

  Future<void> _submitPin() async {
    setState(() => _isLoading = true);
    
    // Generate Idempotency Key
    final idempotencyKey = 'trx_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}';

    final success = await context.read<TransactionProvider>().createTransaction(
      productId: widget.productId,
      customerNumber: widget.customerNumber,
      paymentMethod: widget.paymentMethod,
      pin: _pin,
      idempotencyKey: idempotencyKey,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      Navigator.pop(context); // Tutup overlay
      Navigator.pushReplacementNamed(context, '/success');
    } else {
      final errorMsg = context.read<TransactionProvider>().errorMessage ?? 'Transaksi Gagal';
      setState(() => _pin = ''); // Reset PIN
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg, style: const TextStyle(fontFamily: 'Inter')),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );

      // Jika akun disuspensi karena 3x salah PIN
      if (errorMsg.toLowerCase().contains('suspensi') || errorMsg.toLowerCase().contains('terblokir')) {
        Navigator.pop(context); // Tutup overlay
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Masukkan PIN', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 18)),
              const SizedBox(height: 8),
              const Text('Validasi keamanan transaksi', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF64748B))),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index < _pin.length ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 40),
              if (_isLoading)
                const CircularProgressIndicator(color: Color(0xFF2563EB))
              else
                _buildKeypad(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['1', '2', '3'].map((e) => _keypadButton(e)).toList(),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['4', '5', '6'].map((e) => _keypadButton(e)).toList(),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['7', '8', '9'].map((e) => _keypadButton(e)).toList(),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const SizedBox(width: 64, height: 64),
            _keypadButton('0'),
            GestureDetector(
              onTap: _onBackspace,
              child: Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                child: const Icon(Icons.backspace_outlined, color: Color(0xFF64748B)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _keypadButton(String number) {
    return GestureDetector(
      onTap: () => _onKeypadTap(number),
      child: Container(
        width: 64,
        height: 64,
        alignment: Alignment.center,
        decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFF8FAFC)),
        child: Text(number, style: const TextStyle(fontFamily: 'Inter', fontSize: 24, fontWeight: FontWeight.w600)),
      ),
    );
  }
}