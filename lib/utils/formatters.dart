import 'package:intl/intl.dart';

String formatPrice(double value) {
  final formatted = NumberFormat.currency(
    locale: 'es',
    symbol: 'Bs ',
    decimalDigits: 0,
  ).format(value);
  return formatted;
}

String formatCompact(int value) {
  if (value >= 1000) {
    final compact = (value / 1000).toStringAsFixed(value % 1000 == 0 ? 0 : 1);
    return '${compact}k+';
  }
  return '$value';
}
