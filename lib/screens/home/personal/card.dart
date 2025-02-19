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
                Text(
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
                            style: TextStyle(
                              fontSize: 16,
                              color: white,
                            ),
                          ),
                        ),
                      ),
                      TextSpan(
                        text: widget.depositLocal,
                        style: TextStyle(
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
              '\$${widget.depositForeign}',
              style: TextStyle(
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
  final String NetworthLocal;
  final String NetworthForeign;
  final String currency;

  const NetworthCard({
    Key? key,
    required this.NetworthLocal,
    required this.NetworthForeign,
    required this.currency,
  }) : super(key: key);

  @override
  _NetworthCardState createState() => _NetworthCardState();
}

class _NetworthCardState extends State<NetworthCard> {
  @override
  Widget build(BuildContext context) {
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
                Text(
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
                            style: TextStyle(
                              fontSize: 16,
                              color: primaryTwo,
                            ),
                          ),
                        ),
                      ),
                      TextSpan(
                        text: widget.NetworthLocal,
                        style: TextStyle(
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
              '\$${widget.NetworthForeign}',
              style: TextStyle(
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
