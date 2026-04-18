import 'package:flutter/material.dart';
import 'package:esc_pos_bluetooth/esc_pos_bluetooth.dart';
import '../../models/transaction_model.dart';
import '../../services/printer_service.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih printer terlebih dahulu')));
      return;
    }

    setState(() => _isPrinting = true);
    final markup = double.tryParse(_markupController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0.0;
    
    final success = await _printerService.printReceipt(_selectedPrinter!, widget.transaction, markup);
    
    if (!mounted) return;
    setState(() => _isPrinting = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cetak berhasil', style: TextStyle(fontFamily: 'Inter'))));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal mencetak struk', style: TextStyle(fontFamily: 'Inter')), backgroundColor: Color(0xFFEF4444)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Cetak Struk', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 18)),
              const SizedBox(height: 24),
              const Text('Biaya Jasa (Markup) - Opsional', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF64748B))),
              const SizedBox(height: 8),
              TextField(
                controller: _markupController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  prefixText: 'Rp ',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Pilih Printer Bluetooth', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF64748B))),
              const SizedBox(height: 8),
              SizedBox(
                height: 150,
                child: StreamBuilder<List<PrinterBluetooth>>(
                  stream: _printerService.scanResults,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text('Mencari printer...', style: TextStyle(fontFamily: 'Inter', color: Color(0xFF94A3B8))));
                    }
                    return ListView.builder(
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        final device = snapshot.data![index];
                        final isSelected = _selectedPrinter?.address == device.address;
                        return ListTile(
                          title: Text(device.name ?? 'Unknown Device', style: const TextStyle(fontFamily: 'Inter')),
                          subtitle: Text(device.address ?? '', style: const TextStyle(fontFamily: 'Inter', fontSize: 12)),
                          trailing: isSelected ? const Icon(Icons.check_circle, color: Color(0xFF2563EB)) : null,
                          onTap: () => setState(() => _selectedPrinter = device),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isPrinting ? null : _print,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), elevation: 0),
                  child: _isPrinting 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Cetak Sekarang', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}