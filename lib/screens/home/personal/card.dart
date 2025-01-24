// File: cards.dart
import 'package:flutter/material.dart';
import '../../../theme/theme.dart';

class TotalDepositsCard extends StatelessWidget {
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
                SizedBox(height: 10),
                Text.rich(
                  TextSpan(
                    children: [
                      WidgetSpan(
                        child: Transform.translate(
                          offset: Offset(0, -6),
                          child: Text(
                            'UGX',
                            style: TextStyle(
                              fontSize: 16,
                              color: white,
                            ),
                          ),
                        ),
                      ),
                      TextSpan(
                        text: ' 5,000',
                        style: TextStyle(
                          fontSize: 32,
                          color: white,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
          Positioned(
            bottom: 8,
            right: 16,
            child: Text(
              '\$13.50',
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

class NetworthCard extends StatelessWidget {
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
                SizedBox(height: 10),
                Text.rich(
                  TextSpan(
                    children: [
                      WidgetSpan(
                        child: Transform.translate(
                          offset: Offset(0, -6),
                          child: Text(
                            'UGX',
                            style: TextStyle(fontSize: 16, color: primaryTwo),
                          ),
                        ),
                      ),
                      TextSpan(
                        text: ' 5,000',
                        style: TextStyle(
                          fontSize: 32,
                          color: primaryTwo,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
          Positioned(
            bottom: 8,
            right: 16,
            child: Text(
              '\$13.50',
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
