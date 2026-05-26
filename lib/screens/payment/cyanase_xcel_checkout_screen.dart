import 'dart:async';

import 'package:cyanase/helpers/loader.dart';
import 'package:cyanase/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:xcel_paygate_sdk/xcel_paygate_sdk.dart';

/// Branded in-app XCEL checkout (WebView + Cyanase chrome).
class CyanaseXcelCheckoutScreen extends StatefulWidget {
  const CyanaseXcelCheckoutScreen({
    super.key,
    required this.paymentCode,
    this.amount,
    this.currency,
  });

  final String paymentCode;
  final String? amount;
  final String? currency;

  static String paymentUrl(String code) =>
      'https://paygate.xcelapp.com/v1/main/xcel?code=${Uri.encodeComponent(code)}';

  static Future<XcelPaymentResult?> open(
    BuildContext context, {
    required String paymentCode,
    String? amount,
    String? currency,
  }) {
    return Navigator.of(context).push<XcelPaymentResult>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => CyanaseXcelCheckoutScreen(
          paymentCode: paymentCode,
          amount: amount,
          currency: currency,
        ),
      ),
    );
  }

  @override
  State<CyanaseXcelCheckoutScreen> createState() =>
      _CyanaseXcelCheckoutScreenState();
}

class _CyanaseXcelCheckoutScreenState extends State<CyanaseXcelCheckoutScreen> {
  late final WebViewController _controller;
  bool _loading = true;
  int _progress = 0;
  bool _finished = false;
  Timer? _timeoutTimer;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() {
              _loading = true;
              _progress = 0;
            });
          },
          onPageFinished: (url) {
            _timeoutTimer?.cancel();
            if (mounted) setState(() => _loading = false);
            final result = detectResult(url);
            if (result != null) _complete(result);
          },
          onProgress: (p) {
            if (mounted) setState(() => _progress = p);
          },
          onWebResourceError: (_) {
            _timeoutTimer?.cancel();
            if (mounted) setState(() => _loading = false);
          },
          onNavigationRequest: (request) {
            final result = detectResult(request.url);
            if (result != null) {
              _complete(result);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _finished) return;
      _controller.loadRequest(
        Uri.parse(CyanaseXcelCheckoutScreen.paymentUrl(widget.paymentCode)),
      );
    });

    _timeoutTimer = Timer(const Duration(minutes: 3), () {
      _complete(const PaymentFailed('Payment timed out. Please try again.'));
    });
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    super.dispose();
  }

  void _complete(XcelPaymentResult result) {
    if (_finished || !mounted) return;
    _finished = true;
    _timeoutTimer?.cancel();
    Navigator.of(context).pop(result);
  }

  String? get _amountLabel {
    final a = widget.amount?.toString().trim();
    final c = widget.currency?.toString().trim();
    if (a == null || a.isEmpty) return null;
    if (c != null && c.isNotEmpty) return '$c $a';
    return a;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: white,
      body: Column(
        children: [
          _CheckoutHeader(
            amountLabel: _amountLabel,
            onClose: () => _complete(const PaymentCancelled()),
          ),
          if (_loading)
            LinearProgressIndicator(
              value: _progress > 0 ? (_progress / 100).clamp(0.0, 1.0) : null,
              minHeight: 2,
              backgroundColor: surfaceMutedBorder,
              valueColor: const AlwaysStoppedAnimation<Color>(primaryColor),
            ),
          Expanded(
            child: ColoredBox(
              color: white,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  WebViewWidget(controller: _controller),
                  if (_loading) const _CheckoutLoadingPane(),
                ],
              ),
            ),
          ),
          const _CheckoutFooter(),
        ],
      ),
    );
  }
}

/// Covers the WebView while the payment page loads (avoids a blank/black screen).
class _CheckoutLoadingPane extends StatelessWidget {
  const _CheckoutLoadingPane();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: white,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Loader(),
              const SizedBox(height: 20),
              Text(
                'Loading secure checkout…',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: primaryTwo.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please wait while we connect to mobile money.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: primaryTwo.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckoutHeader extends StatelessWidget {
  const _CheckoutHeader({
    required this.onClose,
    this.amountLabel,
  });

  final VoidCallback onClose;
  final String? amountLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryTwo, primaryTwoDark],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Color(0x331A1E3A),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: onClose,
                    icon: const Icon(Icons.close_rounded, color: white),
                    tooltip: 'Close',
                  ),
                  const Expanded(
                    child: Text(
                      'Complete payment',
                      style: TextStyle(
                        color: white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: primaryColor.withValues(alpha: 0.55),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bolt_rounded, color: primaryColor, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'Xcel',
                          style: TextStyle(
                            color: primaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Text(
                  'Secure mobile money checkout',
                  style: TextStyle(
                    color: white.withValues(alpha: 0.78),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (amountLabel != null) ...[
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: white.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet_outlined,
                            color: primaryColor,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Amount to pay',
                                style: TextStyle(
                                  color: white.withValues(alpha: 0.7),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                amountLabel!,
                                style: const TextStyle(
                                  color: white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckoutFooter extends StatelessWidget {
  const _CheckoutFooter();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: const BoxDecoration(
          color: surfaceMuted,
          border: Border(top: BorderSide(color: surfaceMutedBorder)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline_rounded,
              size: 16,
              color: primaryTwo.withValues(alpha: 0.65),
            ),
            const SizedBox(width: 8),
            Text(
              'Encrypted · Powered by Xcel PayGate',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: primaryTwo.withValues(alpha: 0.75),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
