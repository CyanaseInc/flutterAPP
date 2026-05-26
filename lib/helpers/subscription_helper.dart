/// Offline fallback only — live amounts come from GET subscription/status/.
const Map<String, double> subscriptionPricesFallback = {
  "UGX": 20500.0,
};

@Deprecated('Use subscription quote from API (parseSubscriptionQuote)')
const Map<String, double> subscriptionPrices = subscriptionPricesFallback;

class SubscriptionQuote {
  final double amount;
  final String currency;
  final String msisdn;

  const SubscriptionQuote({
    required this.amount,
    required this.currency,
    this.msisdn = '',
  });
}

SubscriptionQuote parseSubscriptionQuote(Map<String, dynamic> resp) {
  // Endpoint should provide amount + currency (derived from user's country).
  final currency =
      (resp['currency'] ?? resp['subscription_currency'] ?? 'UGX').toString();
  final amountRaw = resp['subscription_amount'];

  double amount = subscriptionPricesFallback['UGX']!;
  if (amountRaw is num) {
    amount = amountRaw.toDouble();
  } else if (amountRaw != null) {
    amount = double.tryParse(amountRaw.toString()) ??
        subscriptionPricesFallback['UGX']!;
  }

  final msisdn = (resp['msisdn'] ?? '').toString().trim(); // optional
  return SubscriptionQuote(
    amount: amount,
    currency: currency,
    msisdn: msisdn,
  );
}

String formatSubscriptionPrice(double amount, {int fractionDigits = 0}) {
  if (fractionDigits <= 0) {
    return amount.round().toString();
  }
  return amount.toStringAsFixed(fractionDigits);
}
