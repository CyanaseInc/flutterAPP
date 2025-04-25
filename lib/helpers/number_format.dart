// lib/utils/number_formatter.dart
import 'package:intl/intl.dart';

class NumberFormatter {
  /// Formats a number as a whole number with commas and optional currency symbol (e.g., 120000 -> UGX120,000)
  static String formatNumber(double amount, {String? currencySymbol}) {
    final formatter = NumberFormat('#,##0', 'en_US');
    final formattedAmount = formatter.format(amount.round());
    return currencySymbol != null
        ? '$currencySymbol$formattedAmount'
        : formattedAmount;
  }

  /// Formats a number with decimals, commas, and optional currency symbol (e.g., 120000.50 -> UGX120,000.50)
  static String formatNumberWithDecimals(double amount,
      {String? currencySymbol, int decimalPlaces = 2}) {
    final formatter = NumberFormat.currency(
      locale: 'en_US',
      symbol: '',
      decimalDigits: decimalPlaces,
      customPattern: '#,##0.##',
    );
    final formattedAmount = formatter.format(amount);
    return currencySymbol != null
        ? '$currencySymbol$formattedAmount'
        : formattedAmount;
  }
}
