import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/wallet_provider.dart';
import '../../utils/currency_formatter.dart';
import 'pin_validation_overlay.dart';

class PaymentScreen extends StatefulWidget {
  final int productId;
  final String productName;
  final String customerNumber;
  final double price;

  const PaymentScreen({
    super.key,
    required this.productId,
    required this.productName,
    required this.customerNumber,
    required this.price,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _selectedMethod = 'wallet';

  void _processPayment() {
    PinValidationOverlay.show(
      context,
      productId: widget.productId,
      customerNumber: widget.customerNumber,
      paymentMethod: _selectedMethod,
    );
  }

  @override
  Widget build(BuildContext context) {
    final balanceStr = context.watch<WalletProvider>().balance;
    final double walletBalance = double.tryParse(balanceStr) ?? 0.0;
    final bool canAfford = walletBalance >= widget.price;

    if (!canAfford && _selectedMethod == 'wallet') {
      _selectedMethod = 'midtrans';
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Pembayaran',
          style: TextStyle(
            fontFamily: 'Inter',
            color: Colors.black,
            fontSize: 16,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Detail Pesanan',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.productName,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.customerNumber,
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 14),
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Harga',
                        style: TextStyle(fontFamily: 'Inter', fontSize: 14),
                      ),
                      Text(
                        CurrencyFormatter.formatIdr(widget.price),
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Metode Pembayaran',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            _buildPaymentOption(
              id: 'wallet',
              title: 'Saldo Voltra',
              subtitle: 'Saldo: ${CurrencyFormatter.formatIdr(walletBalance)}',
              isDisabled: !canAfford,
            ),
            const SizedBox(height: 12),
            _buildPaymentOption(
              id: 'midtrans',
              title: 'QRIS / Virtual Account',
              subtitle: 'Proses otomatis (Midtrans)',
              isDisabled: false,
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _processPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Bayar Sekarang',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption({
    required String id,
    required String title,
    required String subtitle,
    required bool isDisabled,
  }) {
    final isSelected = _selectedMethod == id;
    return GestureDetector(
      onTap: isDisabled ? null : () => setState(() => _selectedMethod = id),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDisabled ? const Color(0xFFF1F5F9) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF2563EB)
                : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isDisabled
                  ? const Color(0xFF94A3B8)
                  : const Color(0xFF2563EB),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    color: isDisabled ? const Color(0xFF94A3B8) : Colors.black,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
