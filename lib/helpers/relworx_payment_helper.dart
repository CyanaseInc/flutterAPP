import 'package:cyanase/helpers/api_helper.dart';

/// Relworx v2: MoMo prompt on phone; server polls check-request-status via get/transaction/.
Future<Map<String, dynamic>> finalizeRelworxPayment({
  required String token,
  required Map<String, dynamic> requestPayment,
}) async {
  final pollBody = <String, dynamic>{
    if (requestPayment['transaction_id'] != null)
      'transaction_id': requestPayment['transaction_id'],
    if (requestPayment['payment_response'] != null)
      'payment_response': requestPayment['payment_response'],
  };

  const pollSeconds = [3, 5, 5, 8, 10];
  Map<String, dynamic>? last;
  for (final sec in pollSeconds) {
    last = await ApiService.getTransaction(token, pollBody);
    if (last['success'] == true) {
      final txn = last['transaction'];
      return {
        'success': true,
        'message': last['message']?.toString() ?? 'Payment successful',
        'transaction': txn,
      };
    }
    await Future.delayed(Duration(seconds: sec));
  }

  last ??= await ApiService.getTransaction(token, pollBody);
  return {
    'success': false,
    'message': last['message']?.toString() ??
        'Payment not completed. Approve the MoMo prompt on your phone, then try again.',
    'transaction': last['transaction'],
  };
}
