import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:esc_pos_bluetooth/esc_pos_bluetooth.dart';
import 'package:voltra_mobile/config/app_constants.dart';
import 'package:voltra_mobile/models/transaction_model.dart';
import 'package:voltra_mobile/services/printer_service.dart';

/// Bottom sheet for connecting to Bluetooth printers and printing receipts.
class PrinterSetupSheet extends StatefulWidget {
  final TransactionModel transaction;

  const PrinterSetupSheet({super.key, required this.transaction});

  @override
  State<PrinterSetupSheet> createState() => _PrinterSetupSheetState();
}

class _PrinterSetupSheetState extends State<PrinterSetupSheet> {
  final PrinterService _printerService = PrinterService();
  final TextEditingController _markupController = TextEditingController(text: '0');
  PrinterBluetooth? _selectedPrinter;
  bool _isPrinting = false;

  @override
  void initState() {
    super.initState();
    _printerService.startScan();
  }

  @override
  void dispose() {
    _printerService.stopScan();
    _markupController.dispose();
    super.dispose();
  }

  void _print() async {
    if (_selectedPrinter == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Pilih printer terlebih dahulu',
            style: TextStyle(fontFamily: AppFonts.body),
          ),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isPrinting = true);
    
    // Process markup with Decimal
    final cleanMarkupStr = _markupController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final markup = Decimal.tryParse(cleanMarkupStr.isEmpty ? '0' : cleanMarkupStr) ?? Decimal.zero;
    
    final success = await _printerService.printReceipt(_selectedPrinter!, widget.transaction, markup);
    
    if (!mounted) return;
    setState(() => _isPrinting = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Cetak berhasil',
            style: TextStyle(fontFamily: AppFonts.body),
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Gagal mencetak struk',
            style: TextStyle(fontFamily: AppFonts.body),
          ),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.borderRadiusXl)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              const Text(
                'Cetak Struk',
                style: TextStyle(
                  fontFamily: AppFonts.heading,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              
              const Text(
                'Biaya Jasa (Markup) - Opsional',
                style: TextStyle(
                  fontFamily: AppFonts.body,
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _markupController,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontFamily: AppFonts.body),
                decoration: InputDecoration(
                  prefixText: 'Rp ',
                  prefixStyle: const TextStyle(
                    fontFamily: AppFonts.body,
                    color: AppColors.textPrimary,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
                    borderSide: const BorderSide(color: AppColors.divider),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
                    borderSide: const BorderSide(color: AppColors.divider),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
                    borderSide: const BorderSide(color: AppColors.electricBlue),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: 14,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              
              const Text(
                'Pilih Printer Bluetooth',
                style: TextStyle(
                  fontFamily: AppFonts.body,
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              
              Container(
                height: 180,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.divider),
                  borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
                  color: AppColors.surface,
                ),
                child: StreamBuilder<List<PrinterBluetooth>>(
                  stream: _printerService.scanResults,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.electricBlue,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'Mencari printer terdekat...',
                              style: TextStyle(
                                fontFamily: AppFonts.body,
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return ListView.separated(
                      itemCount: snapshot.data!.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final device = snapshot.data![index];
                        final isSelected = _selectedPrinter?.address == device.address;
                        return ListTile(
                          title: Text(
                            device.name ?? 'Unknown Device',
                            style: TextStyle(
                              fontFamily: AppFonts.body,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                          subtitle: Text(
                            device.address ?? '',
                            style: const TextStyle(
                              fontFamily: AppFonts.body,
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          leading: Icon(
                            Icons.print_outlined,
                            color: isSelected ? AppColors.electricBlue : AppColors.textTertiary,
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.check_circle, color: AppColors.success)
                              : null,
                          onTap: () => setState(() => _selectedPrinter = device),
                          tileColor: isSelected ? AppColors.electricBlue.withValues(alpha: 0.05) : null,
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isPrinting ? null : _print,
                  child: _isPrinting 
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: AppColors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Cetak Sekarang'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}