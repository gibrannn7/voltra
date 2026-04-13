import 'package:intl/intl.dart';

/// Currency and number formatting utilities using bcmath-style string precison.
class CurrencyFormatter {
  CurrencyFormatter._();

  static final _idrFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static final _idrFormatDecimal = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 2,
  );

  /// Format a string/num as IDR currency: "Rp 50.000"
  static String formatIdr(dynamic amount) {
    final value = _toDouble(amount);
    return _idrFormat.format(value);
  }

  /// Format with decimals: "Rp 50.000,00"
  static String formatIdrDecimal(dynamic amount) {
    final value = _toDouble(amount);
    return _idrFormatDecimal.format(value);
  }

  /// Compact format for large numbers: "Rp 1,2 jt"
  static String formatCompact(dynamic amount) {
    final value = _toDouble(amount);
    if (value >= 1000000) {
      return 'Rp ${(value / 1000000).toStringAsFixed(1)} jt';
    }
    if (value >= 1000) {
      return 'Rp ${(value / 1000).toStringAsFixed(0)} rb';
    }
    return formatIdr(amount);
  }

  /// Format a date string (ISO8601) to "dd MMM yyyy HH:mm"
  static String formatDate(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return '-';
    try {
      final date = DateTime.parse(isoDate).toLocal();
      return DateFormat('dd MMM yyyy HH:mm', 'id_ID').format(date);
    } catch (_) {
      return isoDate;
    }
  }

  /// Format to relative time: "2 jam lalu", "baru saja"
  static String formatRelative(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return '-';
    try {
      final date = DateTime.parse(isoDate).toLocal();
      final diff = DateTime.now().difference(date);

      if (diff.inSeconds < 60) return 'Baru saja';
      if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
      if (diff.inHours < 24) return '${diff.inHours} jam lalu';
      if (diff.inDays < 7) return '${diff.inDays} hari lalu';

      return DateFormat('dd MMM yyyy', 'id_ID').format(date);
    } catch (_) {
      return isoDate;
    }
  }

  static double _toDouble(dynamic amount) {
    if (amount is double) return amount;
    if (amount is int) return amount.toDouble();
    if (amount is String) return double.tryParse(amount) ?? 0;
    return 0;
  }
}
