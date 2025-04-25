import 'package:flutter/material.dart';
import 'investment_tab.dart';
import 'loan_tab.dart';
import 'package:cyanase/theme/theme.dart';

class GroupFinancePage extends StatelessWidget {
  final int groupId;

  const GroupFinancePage({Key? key, required this.groupId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
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
          bottom: TabBar(
            labelColor: white,
            unselectedLabelColor: Colors.grey[300],
            indicatorColor: white,
            tabs: [
              Tab(text: 'Investments'),
              Tab(text: 'Loans'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            InvestmentsTab(),
            LoansTab(),
          ],
        ),
      ),
    );
  }
}
