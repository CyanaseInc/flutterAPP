import 'package:flutter/material.dart';
import '../../../theme/theme.dart';

class GroupFinancePage extends StatelessWidget {
  final int groupId;

  const GroupFinancePage({Key? key, required this.groupId}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Group Summary',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: white,
          ),
        ),
        backgroundColor: primaryTwo,
        iconTheme: IconThemeData(color: white),
      ),
      body: Column(
        children: [
          SizedBox(height: 46),
          Row(
            children: [
              Expanded(
                child: Center(
                  child: Text(
                    'MY CONTRIBUTIONS',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ),
              // Menu icon on the right
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '\$12,900,345.',
            style: TextStyle(
              fontSize: 35,
              fontWeight: FontWeight.bold,
              color: Colors.grey, // Using your primaryColor
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'INTREST EARNED',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Text(
            '\$1,234.56',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: primaryColor, // Using your primaryTwo
            ),
          ),
          const SizedBox(width: 8), // Top padding
          SizedBox(
            width: double.infinity,
            child: Padding(
              padding:
                  EdgeInsets.symmetric(horizontal: 8), // Small margin on sides
              child: TotalDepositsCard(),
            ),
          ),
          SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: NetworthCard(),
            ),
          ),
          SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: LoanCard(),
            ),
          ),
          SizedBox(height: 16), // Bottom padding
        ],
      ),
    );
  }
}

class TotalDepositsCard extends StatelessWidget {
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
                const Text(
                  'Total group interest',
                  style: TextStyle(
                      fontSize: 12,
                      color: primaryTwo,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Total interest earned by the group',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 10),
                Text.rich(
                  TextSpan(
                    children: [
                      WidgetSpan(
                        child: Transform.translate(
                          offset: const Offset(0, -6),
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
                const SizedBox(height: 10),
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
                      fontSize: 10, color: white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Total investments made by the group',
                  style: TextStyle(
                    fontSize: 10,
                    color: white,
                  ),
                ),
                const SizedBox(height: 5),
                Text.rich(
                  TextSpan(
                    children: [
                      WidgetSpan(
                        child: Transform.translate(
                          offset: const Offset(0, -6),
                          child: const Text(
                            'UGX',
                            style: TextStyle(
                                fontSize: 14,
                                color: white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const TextSpan(
                        text: ' 3,005,000',
                        style: TextStyle(
                            fontSize: 20,
                            color: white,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 5),
              ],
            ),
          ),
          const Positioned(
            bottom: 8,
            right: 16,
            child: Text(
              '\$13.50',
              style: TextStyle(
                  fontSize: 14, color: white, fontWeight: FontWeight.bold),
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
                  'Ongoing Loans',
                  style: TextStyle(
                      fontSize: 14,
                      color: primaryTwo,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Total loans currently being repaid',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 10),
                Text.rich(
                  TextSpan(
                    children: [
                      WidgetSpan(
                        child: Transform.translate(
                          offset: const Offset(0, -6),
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
                const SizedBox(height: 10),
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
