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
      color: Colors.white,
      elevation: 4,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total group Deposits',
                  style: TextStyle(
                      fontSize: 12,
                      color: primaryTwo,
                      fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Text.rich(
                  TextSpan(
                    children: [
                      WidgetSpan(
                        child: Transform.translate(
                          offset: Offset(0, -6),
                          child: const Text(
                            'UGX',
                            style: TextStyle(
                                fontSize: 14,
                                color: primaryTwo,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const TextSpan(
                        text: ' 25,000,000,000',
                        style: TextStyle(
                            fontSize: 20,
                            color: primaryTwo,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10),
              ],
            ),
          ),
          const Positioned(
            bottom: 8,
            right: 16,
            child: Text(
              '\$130.50',
              style: TextStyle(
                  fontSize: 14, color: primaryTwo, fontWeight: FontWeight.bold),
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
                  'Group investments',
                  style: TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Text.rich(
                  TextSpan(
                    children: [
                      WidgetSpan(
                        child: Transform.translate(
                          offset: Offset(0, -6),
                          child: const Text(
                            'UGX',
                            style: TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const TextSpan(
                        text: ' 3,005,000',
                        style: TextStyle(
                            fontSize: 20,
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10),
              ],
            ),
          ),
          const Positioned(
            bottom: 8,
            right: 16,
            child: Text(
              '\$13.50',
              style: TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class LoanCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      color: Colors.white,
      elevation: 4,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ongoing Loans',
                  style: TextStyle(
                      fontSize: 14,
                      color: primaryTwo,
                      fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Text.rich(
                  TextSpan(
                    children: [
                      WidgetSpan(
                        child: Transform.translate(
                          offset: Offset(0, -6),
                          child: const Text(
                            'UGX',
                            style: TextStyle(
                                fontSize: 14,
                                color: primaryTwo,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const TextSpan(
                        text: ' 5,000',
                        style: TextStyle(
                            fontSize: 20,
                            color: primaryTwo,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10),
              ],
            ),
          ),
          const Positioned(
            bottom: 8,
            right: 16,
            child: Text(
              '\$130.50',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
