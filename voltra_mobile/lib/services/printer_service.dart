import 'package:decimal/decimal.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:esc_pos_bluetooth/esc_pos_bluetooth.dart';
import 'package:voltra_mobile/models/transaction_model.dart';
import 'package:voltra_mobile/utils/currency_formatter.dart';

/// Service to handle Bluetooth Thermal Printer functionality.
/// Implements esc_pos_bluetooth and esc_pos_utils.
class PrinterService {
  static final PrinterService _instance = PrinterService._internal();
  factory PrinterService() => _instance;
  PrinterService._internal();

  final PrinterBluetoothManager _printerManager = PrinterBluetoothManager();

  /// Stream of discovered bluetooth printers
  Stream<List<PrinterBluetooth>> get scanResults => _printerManager.scanResults;

  /// Start scanning for devices
  void startScan() {
    _printerManager.startScan(const Duration(seconds: 4));
  }

  /// Stop scanning
  void stopScan() {
    _printerManager.stopScan();
  }

  /// connect and print receipt
  Future<bool> printReceipt(PrinterBluetooth printer, TransactionModel transaction, Decimal markup) async {
    _printerManager.selectPrinter(printer);
    final result = await _printerManager.printTicket(await _generateTicket(transaction, markup));
    return result == PosPrintResult.success;
  }

  /// Generate receipt byte layout
  Future<List<int>> _generateTicket(TransactionModel tx, Decimal markup) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);
    List<int> bytes = [];

    // Header
    bytes += generator.text(
      'VOLTRA APP',
      styles: const PosStyles(
        align: PosAlign.center,
        bold: true,
        width: PosTextSize.size2,
        height: PosTextSize.size2,
      ),
    );
    bytes += generator.text(
      'Smart PPOB & Bill Payment',
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.feed(1);

    // Detail Transaksi
    bytes += generator.text('Tanggal: ${CurrencyFormatter.formatDate(tx.createdAt)}');
    bytes += generator.text('Trx ID : ${tx.id}');
    bytes += generator.hr();

    bytes += generator.text('Produk : ${tx.productName ?? '-'}');
    bytes += generator.text('Tujuan : ${tx.customerNumber}');
    if (tx.customerName != null) {
      bytes += generator.text('Nama   : ${tx.customerName}');
    }
    bytes += generator.text('SN/Token: ${tx.snToken ?? 'Pending'}');
    bytes += generator.hr();

    // Harga & Markup with Decimal precision
    final Decimal baseTotal = Decimal.tryParse(tx.totalAmount) ?? Decimal.zero;
    final Decimal grandTotal = baseTotal + markup;

    bytes += generator.row([
      PosColumn(text: 'Harga', width: 6),
      PosColumn(
        text: CurrencyFormatter.formatIdr(baseTotal.toString()),
        width: 6,
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]);

    if (markup > Decimal.zero) {
      bytes += generator.row([
        PosColumn(text: 'Biaya Jasa', width: 6),
        PosColumn(
          text: CurrencyFormatter.formatIdr(markup.toString()),
          width: 6,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
    }

    bytes += generator.hr();
    bytes += generator.row([
      PosColumn(text: 'TOTAL', width: 6, styles: const PosStyles(bold: true)),
      PosColumn(
        text: CurrencyFormatter.formatIdr(grandTotal.toString()),
        width: 6,
        styles: const PosStyles(align: PosAlign.right, bold: true),
      ),
    ]);
    
    bytes += generator.feed(2);
    bytes += generator.text(
      'Terima Kasih',
      styles: const PosStyles(align: PosAlign.center, bold: true),
    );
    bytes += generator.text(
      'Simpan struk ini sebagai bukti pembayaran.',
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.feed(3);

    return bytes;
  }
}