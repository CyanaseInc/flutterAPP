import 'package:cyanase/screens/home/personal/conversion.dart';
import 'package:flutter/material.dart';
import '../../../theme/theme.dart'; // Your custom theme file

class TotalDepositsCard extends StatefulWidget {
  final String depositLocal;
  final String depositForeign;
  final String currency;

  const TotalDepositsCard({
    Key? key,
    required this.depositLocal,
    required this.depositForeign,
    required this.currency,
  }) : super(key: key);

  @override
  _TotalDepositsCardState createState() => _TotalDepositsCardState();
}

class _TotalDepositsCardState extends State<TotalDepositsCard> {
  @override
  Widget build(BuildContext context) {
    final depositForeign = widget.depositForeign;
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      color: primaryTwo,
      elevation: 4,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Deposits',
                  style: TextStyle(
                    fontSize: 16,
                    color: white,
                  ),
                ),
                const SizedBox(height: 10),
                Text.rich(
                  TextSpan(
                    children: [
                      WidgetSpan(
                        child: Transform.translate(
                          offset: const Offset(0, -6),
                          child: Text(
                            widget.currency,
                            style: const TextStyle(
                              fontSize: 16,
                              color: white,
                            ),
                          ),
                        ),
                      ),
                      TextSpan(
                        text: widget.depositLocal,
                        style: const TextStyle(
                          fontSize: 32,
                          color: white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          Positioned(
            bottom: 8,
            right: 16,
            child: Text(
              '\$ ${widget.depositForeign}',
              style: const TextStyle(
                fontSize: 12,
                color: white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class NetworthCard extends StatefulWidget {
  final String networthLocal;
  final String networthForeign;
  final String currency;

  const NetworthCard({
    Key? key,
    required this.networthLocal,
    required this.networthForeign,
    required this.currency,
  }) : super(key: key);

  @override
  _NetworthCardState createState() => _NetworthCardState();
}

class _NetworthCardState extends State<NetworthCard> {
  String networth = '';
  String currency = '';
  String networthLocal = '';
  String networthForeign = '';
  String result = '';
  @override
  void initState() {
    super.initState();
    print(
        "InitState: currency = ${widget.currency}, networthLocal = ${widget.networthLocal}");
    currency = widget.currency;
    networthLocal = widget.networthLocal;
    networthForeign = widget.networthForeign;
    convert();
  }

  convert() async {
    print('$currency $networthForeign');
    var conversion = Conversion(currency, double.parse(networthForeign), 'usd');
    var result = await conversion.executeConversion();
    setState(() {
      networth = result;
    });
    print(result);
  }

  @override
  Widget build(BuildContext context) {
    final netForeign = widget.networthForeign;
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      color: white,
      elevation: 4,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Networth',
                  style: TextStyle(
                    fontSize: 16,
                    color: primaryTwo,
                  ),
                ),
                const SizedBox(height: 10),
                Text.rich(
                  TextSpan(
                    children: [
                      WidgetSpan(
                        child: Transform.translate(
                          offset: const Offset(0, -6),
                          child: Text(
                            widget.currency,
                            style: const TextStyle(
                              fontSize: 16,
                              color: primaryTwo,
                            ),
                          ),
                        ),
                      ),
                      TextSpan(
                        text: widget.networthLocal,
                        style: const TextStyle(
                          fontSize: 32,
                          color: primaryTwo,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          Positioned(
            bottom: 8,
            right: 16,
            child: Text(
              // '\$${widget.networthForeign}',
              '\$ $netForeign',
              style: const TextStyle(
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
