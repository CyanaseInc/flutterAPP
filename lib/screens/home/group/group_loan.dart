import 'package:flutter/material.dart';
// Install this package for network requests in Flutter (or use your own method).

class LoanSection extends StatefulWidget {
  final double loanBalance;
  final int daysLeft;
  final double totalBalance;

  LoanSection({
    required this.loanBalance,
    required this.daysLeft,
    required this.totalBalance,
  });

  @override
  _LoanSectionState createState() => _LoanSectionState();
}

class _LoanSectionState extends State<LoanSection> {
  bool isModalOpen = false;
  bool isTransactionModalOpen = false;
  bool isPayModalOpen = false;
  int currentStep = 1;
  double? loanAmount;
  int loanPeriod = 30;
  bool isLoading = false;
  String? formError;

  // Simulating user data
  double totalLoan = 10000;
  double maxLoanAmount = 30000;

  void openModal() {
    if (widget.totalBalance == 0) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content:
              Text('You need to start saving before you can request a loan.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close'),
            ),
          ],
        ),
      );
    } else {
      setState(() {
        isModalOpen = true;
      });
    }
  }

  void closeModal() {
    setState(() {
      isModalOpen = false;
      currentStep = 1;
      formError = null;
    });
  }

  void openPayModal() {
    setState(() {
      isPayModalOpen = true;
    });
  }

  void closePayModal() {
    setState(() {
      isPayModalOpen = false;
      currentStep = 1;
      formError = null;
    });
  }

  void openTransactionModal() {
    setState(() {
      isTransactionModalOpen = true;
    });
  }

  void closeTransactionModal() {
    setState(() {
      isTransactionModalOpen = false;
    });
  }

  void nextStep() {
    setState(() {
      currentStep++;
    });
  }

  void prevStep() {
    setState(() {
      currentStep--;
    });
  }

  double calculateTotalPaybackForPeriod(int period) {
    if (loanAmount == null) return 0;
    final interestRate = getInterestRateForPeriod(period);
    final totalInterest = loanAmount! * interestRate;
    return loanAmount! + totalInterest;
  }

  double getInterestRateForPeriod(int period) {
    switch (period) {
      case 30:
        return 0.04;
      case 90:
        return 0.10;
      case 180:
        return 0.15;
      default:
        return 0.04;
    }
  }

  Future<void> handleSubmit() async {
    if (loanAmount == null || loanAmount! <= 0) {
      setState(() {
        formError = 'Loan amount must be greater than zero.';
      });
      return;
    }
    if (loanAmount! > maxLoanAmount) {
      setState(() {
        formError =
            'The maximum loan amount you can request is Ugx ${maxLoanAmount.toStringAsFixed(2)}.';
      });
      return;
    }

    // Assuming network request for loan submission
    setState(() {
      isLoading = true;
    });

    /* try {
      final response =
          await axios.post('https://zillioncapital.app/server/getLoan.php', {
        'amount': loanAmount,
        'period': loanPeriod,
        'payback': calculateTotalPaybackForPeriod(loanPeriod),
        'id': 'userId', // Replace with actual userId
      });

      if (response.data['status'] == 'success') {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Success'),
            content: Text('Loan Requested Successfully!'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  closeModal();
                },
                child: Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        formError = 'Network error. Please try again.';
      });
    }***/
  }

  Widget renderStep() {
    switch (currentStep) {
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('Step 1: Enter Loan Amount'),
            TextField(
              keyboardType: TextInputType.number,
              onChanged: (value) {
                setState(() {
                  loanAmount = double.tryParse(value);
                });
              },
              decoration: InputDecoration(hintText: 'Loan Amount'),
            ),
            if (loanAmount != null && loanAmount! > 0) ...[
              Text('Estimated Payback:'),
              Text(
                  '30 Days (4% Interest): ${calculateTotalPaybackForPeriod(30)} UGX'),
              Text(
                  '90 Days (10% Interest): ${calculateTotalPaybackForPeriod(90)} UGX'),
              Text(
                  '180 Days (15% Interest): ${calculateTotalPaybackForPeriod(180)} UGX'),
            ],
            ElevatedButton(
              onPressed: nextStep,
              child: Text('Next'),
            ),
          ],
        );
      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('Step 2: Choose Repayment Plan'),
            DropdownButton<int>(
              value: loanPeriod,
              onChanged: (value) {
                setState(() {
                  loanPeriod = value!;
                });
              },
              items: [
                DropdownMenuItem(
                    child: Text('30 Days (4% Interest)'), value: 30),
                DropdownMenuItem(
                    child: Text('90 Days (10% Interest)'), value: 90),
                DropdownMenuItem(
                    child: Text('180 Days (15% Interest)'), value: 180),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: prevStep,
                  child: Text('Previous'),
                ),
                ElevatedButton(
                  onPressed: nextStep,
                  child: Text('Next'),
                ),
              ],
            ),
          ],
        );
      case 3:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('Step 3: Review & Submit'),
            if (formError != null) ...[
              Text(formError!, style: TextStyle(color: Colors.red)),
            ],
            Text('Amount: Ugx ${loanAmount?.toStringAsFixed(2)}'),
            Text('Loan Period: $loanPeriod Days'),
            Text(
                'Interest Rate: ${getInterestRateForPeriod(loanPeriod) * 100}%'),
            Text(
                'Total Payback: Ugx ${calculateTotalPaybackForPeriod(loanPeriod).toStringAsFixed(2)}'),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: prevStep,
                  child: Text('Previous'),
                ),
                ElevatedButton(
                  onPressed: handleSubmit,
                  child:
                      isLoading ? CircularProgressIndicator() : Text('Submit'),
                ),
              ],
            ),
          ],
        );
      default:
        return Container();
    }
  }

  Widget payLoanStep() {
    return Column(
      children: [
        Text('Pay Loan'),
        Text(
            'Kindly send your money to the admin. Your loan status will be updated.'),
      ],
    );
  }

  Widget renderTransactionList() {
    return Column(
      children: [
        Text('Transaction History'),
        // Simulate fetching transaction history
        Text('No transaction found'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Loan Section')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Card(
              color: Colors.pink.shade100,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text('Loan Balance: Ugx ${widget.loanBalance}'),
                    Text('Days Left: ${widget.daysLeft}'),
                    if (widget.loanBalance == 0)
                      ElevatedButton(
                        onPressed: openModal,
                        child: Text('Get Loan'),
                      )
                    else
                      ElevatedButton(
                        onPressed: openPayModal,
                        child: Text('Pay Loan'),
                      ),
                  ],
                ),
              ),
            ),
            if (isModalOpen)
              Dialog(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      IconButton(
                        icon: Icon(Icons.close),
                        onPressed: closeModal,
                      ),
                      renderStep(),
                    ],
                  ),
                ),
              ),
            if (isPayModalOpen)
              Dialog(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      IconButton(
                        icon: Icon(Icons.close),
                        onPressed: closePayModal,
                      ),
                      payLoanStep(),
                    ],
                  ),
                ),
              ),
            if (isTransactionModalOpen)
              Dialog(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      IconButton(
                        icon: Icon(Icons.close),
                        onPressed: closeTransactionModal,
                      ),
                      renderTransactionList(),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: LoanSection(
      loanBalance: 0,
      daysLeft: 30,
      totalBalance: 50000,
    ),
  ));
}
