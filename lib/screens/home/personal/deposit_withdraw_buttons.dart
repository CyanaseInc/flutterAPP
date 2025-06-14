import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io';
import '../../../theme/theme.dart';
import '../componets/investment_deposit.dart'; // Import the Deposit widget
import '../componets/investment_withdraw.dart'; // Import the Withdraw widget

class DepositWithdrawButtons extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Platform.isIOS
            ? CupertinoButton.filled(
                onPressed: () {
                  if (Platform.isIOS) {
                    showCupertinoModalPopup(
                      context: context,
                      builder: (BuildContext context) {
                        return Deposit();
                      },
                    );
                  } else {
                    showModalBottomSheet(
                      context: context,
                      builder: (BuildContext context) {
                        return Deposit();
                      },
                    );
                  }
                },
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CupertinoIcons.add,
                      size: 18,
                      color: primaryColor,
                    ),
                    SizedBox(width: 5),
                    Text('Invest'),
                  ],
                ),
              )
            : ElevatedButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (BuildContext context) {
                      return Deposit();
                    },
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: white,
                  foregroundColor: primaryTwo,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(color: primaryTwo, width: 1),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add,
                      size: 18,
                      color: primaryTwo,
                    ),
                    SizedBox(width: 5),
                    Text('Invest'),
                  ],
                ),
              ),
        Platform.isIOS
            ? CupertinoButton.filled(
                onPressed: () {
                  if (Platform.isIOS) {
                    showCupertinoModalPopup(
                      context: context,
                      builder: (BuildContext context) {
                        return Withdraw();
                      },
                    );
                  } else {
                    showModalBottomSheet(
                      context: context,
                      builder: (BuildContext context) {
                        return Withdraw();
                      },
                    );
                  }
                },
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CupertinoIcons.minus,
                      size: 18,
                      color: primaryColor,
                    ),
                    SizedBox(width: 5),
                    Text('Withdraw'),
                  ],
                ),
              )
            : ElevatedButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (BuildContext context) {
                      return Withdraw();
                    },
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: white,
                  foregroundColor: primaryTwo,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(color: primaryTwo, width: 1),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.remove,
                      size: 18,
                      color: primaryTwo,
                    ),
                    SizedBox(width: 5),
                    Text('Withdraw'),
                  ],
                ),
              ),
      ],
    );
  }
}
