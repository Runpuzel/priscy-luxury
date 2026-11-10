import 'package:intl/intl.dart';

class CurrencyFormatter {
  const CurrencyFormatter._();

  static final NumberFormat _ghsFormatter = NumberFormat.currency(
    locale: 'en_GH',
    symbol: 'GHS ',
    decimalDigits: 2,
  );

  static final DateFormat _shortDate = DateFormat('d MMM yyyy');
  static final DateFormat _dateTime = DateFormat('d MMM yyyy, HH:mm');

  /// Formats an amount in Ghana Cedis, e.g. `GHS 185.00`.
  static String formatGhs(num amount) => _ghsFormatter.format(amount);

  /// Converts Ghana Cedis to Paystack pesewas (integer minor units).
  static int toPesewas(double ghsAmount) => (ghsAmount * 100).round();

  static String formatDate(DateTime date) => _shortDate.format(date.toLocal());

  static String formatDateTime(DateTime date) =>
      _dateTime.format(date.toLocal());
}
