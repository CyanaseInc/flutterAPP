import 'package:cyanase/helpers/api_helper.dart';
import 'package:cyanase/helpers/loader.dart';
import 'package:cyanase/screens/payment/cyanase_xcel_checkout_screen.dart';
import 'package:cyanase/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:xcel_paygate_sdk/xcel_paygate_sdk.dart';

/// Brief full-screen feedback while payment steps run (not a blocking “processing” trap).
Future<T> withPaymentStatusOverlay<T>(
  BuildContext context,
  Future<T> Function() action, {
  required String message,
  String? subtitle,
}) async {
  if (!context.mounted) return action();

  final navigator = Navigator.of(context, rootNavigator: true);
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    useRootNavigator: true,
    barrierColor: Colors.white.withValues(alpha: 0.94),
    builder: (ctx) => PopScope(
      canPop: false,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Loader(),
              const SizedBox(height: 20),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: primaryTwo,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: primaryTwo.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );

  try {
    return await action();
  } finally {
    if (navigator.mounted) {
      navigator.pop();
    }
  }
}

class XcelCheckoutResult {
  final bool success;
  final String message;
  final String? reference;

  const XcelCheckoutResult({
    required this.success,
    this.message = '',
    this.reference,
  });
}

bool isXcelPaymentResponse(Map<String, dynamic> requestPayment) {
  if (requestPayment['provider_used'] == 'xcel') return true;
  final pr = requestPayment['payment_response'];
  if (pr is Map &&
      (pr['payment_code'] != null || pr['payment_link'] != null)) {
    return true;
  }
  return false;
}

/// In-app checkout only (XcelPaygate SDK WebView). No external browser — store-safe.
Future<XcelCheckoutResult> completeXcelCheckout(
  BuildContext context,
  Map<String, dynamic>? paymentResponse,
) async {
  final pr = paymentResponse ?? {};
  final code = pr['payment_code']?.toString().trim() ?? '';

  if (code.isNotEmpty) {
    final amount = pr['amount']?.toString();
    final currency = pr['currency']?.toString();
    if (!context.mounted) {
      return const XcelCheckoutResult(
        success: false,
        message: 'Payment screen unavailable',
      );
    }
    final result = await CyanaseXcelCheckoutScreen.open(
      context,
      paymentCode: code,
      amount: amount,
      currency: currency,
    );
    switch (result) {
      case PaymentSuccess(:final reference):
        return XcelCheckoutResult(
          success: true,
          message: 'Payment successful',
          reference: reference,
        );
      case PaymentPending():
        return const XcelCheckoutResult(
          success: true,
          message: 'Payment pending',
        );
      case PaymentFailed(:final reason):
        return XcelCheckoutResult(
          success: false,
          message: reason ?? 'Payment failed',
        );
      case PaymentCancelled():
        return const XcelCheckoutResult(
          success: false,
          message: 'Payment cancelled',
        );
      case null:
        return const XcelCheckoutResult(
          success: false,
          message: 'Payment dismissed',
        );
    }
  }

  return const XcelCheckoutResult(
    success: false,
    message:
        'Payment could not start in-app (missing payment_code from server)',
  );
}

/// Max wall-clock time for post-checkout verification (MoMo + server poll).
const int paymentVerificationMaxSeconds = 38;

/// Body for get/transaction/ — must include internal_reference for subscription activation.
Map<String, dynamic> buildTransactionPollBody(
  Map<String, dynamic> requestPayment,
) {
  final pr = requestPayment['payment_response'];
  Map<String, dynamic>? inner;
  if (pr is Map<String, dynamic>) {
    inner = pr;
  } else if (pr is Map) {
    inner = Map<String, dynamic>.from(pr);
  }
  final nested = inner?['payment_response'];
  if (nested is Map) {
    inner = nested is Map<String, dynamic>
        ? nested
        : Map<String, dynamic>.from(nested);
  }
  final ref = inner?['internal_reference'] ??
      inner?['transaction_id']?.toString() ??
      requestPayment['internal_reference']?.toString();

  return {
    if (requestPayment['transaction_id'] != null)
      'transaction_id': requestPayment['transaction_id'],
    if (ref != null && ref.isNotEmpty) 'internal_reference': ref,
    if (inner != null) 'payment_response': inner,
  };
}

Future<Map<String, dynamic>> _pollTransactionUntilVerified(
  String token,
  Map<String, dynamic> requestPayment,
) async {
  final pollBody = buildTransactionPollBody(requestPayment);
  final deadline = DateTime.now().add(
    const Duration(seconds: paymentVerificationMaxSeconds),
  );
  Map<String, dynamic>? last;
  var delaySec = 2;

  while (DateTime.now().isBefore(deadline)) {
    last = await ApiService.getTransaction(token, pollBody);
    if (last['success'] == true) return last;

    final remaining = deadline.difference(DateTime.now());
    if (remaining <= Duration.zero) break;

    final waitSec = delaySec.clamp(1, remaining.inSeconds);
    await Future.delayed(Duration(seconds: waitSec));
    delaySec = (delaySec + 1).clamp(2, 5);
  }

  return last ?? await ApiService.getTransaction(token, pollBody);
}

/// After checkout: confirm on server, then poll getTransaction with backoff.
Future<Map<String, dynamic>> finalizeMobileMoneyPayment({
  required BuildContext context,
  required String token,
  required Map<String, dynamic> requestPayment,
}) async {
  if (isXcelPaymentResponse(requestPayment)) {
    final pr = requestPayment['payment_response'];
    final checkout = await completeXcelCheckout(
      context,
      pr is Map<String, dynamic>
          ? pr
          : (pr is Map ? Map<String, dynamic>.from(pr) : null),
    );
    if (!checkout.success) {
      return {'success': false, 'message': checkout.message};
    }

    if (!context.mounted) {
      return {'success': false, 'message': 'Payment confirmation unavailable'};
    }

    return withPaymentStatusOverlay(
      context,
      () async {
        final txnId = requestPayment['transaction_id'];
        Map<String, dynamic>? confirmResult;
        if (txnId != null) {
          confirmResult = await ApiService.confirmXcelPayment(
            token,
            transactionId: txnId is int ? txnId : int.tryParse('$txnId'),
          );
          final sub = confirmResult['subscription'];
          if (sub is Map && sub['success'] == true) {
            return {
              'success': true,
              'message': confirmResult['message']?.toString() ??
                  'Subscription activated',
              'transaction': confirmResult['transaction'],
              'subscription': sub,
            };
          }
          final dep = confirmResult['deposit'];
          if (dep is Map && dep['success'] == true) {
            return {
              'success': true,
              'message': confirmResult['message']?.toString() ??
                  'Deposit recorded',
              'transaction': confirmResult['transaction'],
              'deposit': dep,
            };
          }
        }

        return _pollTransactionUntilVerified(token, requestPayment);
      },
      message: 'Confirming your payment…',
      subtitle: 'This usually takes a few seconds.',
    );
  } else {
    await Future.delayed(const Duration(seconds: 15));
  }

  return _pollTransactionUntilVerified(token, requestPayment);
}
