import 'package:cyanase/theme/theme.dart';
import 'package:flutter/material.dart';

class GroupHeader extends StatelessWidget {
  final String groupName;
  final String profilePic;
  const GroupHeader(
      {Key? key, required this.groupName, required this.profilePic})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity, // Ensures the container takes full width
      color: white,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Profile Picture
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: primaryTwo, // Light border color
                width: 1, // Border width
              ),
            ),
            child: CircleAvatar(
              backgroundImage: AssetImage(profilePic),
              radius: 50,
            ),
          ),

          const SizedBox(height: 16),

          // Group Name
          Text(
            groupName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Group Description
          const Text(
            'This is a family saving group for us all',
            style: TextStyle(
              color: primaryTwo,
              fontSize: 15,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildDepositButton(context),
              _buildRequestLoanButton(),
              _buildWithdrawButton(),
            ],
          ),
        ],
      ),
    );
  }

  // Deposit Button: ElevatedButton style
  Widget _buildDepositButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryTwo, // Background color
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10), // Rounded corners
        ),
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 12), // Padding
      ),
      child: const Text(
        'Deposit', // Button label
        style: TextStyle(
            color: white, // Text color
            fontSize: 12,
            fontWeight: FontWeight.bold),
      ),
    );
  }

  // Request Loan Button: ElevatedButton style
  Widget _buildRequestLoanButton() {
    return ElevatedButton(
      onPressed: () {
        // Implement action for requesting a loan
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
      child: const Text(
        'Get Loan',
        style:
            TextStyle(color: white, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  // Withdraw Button: OutlinedButton style with border
  Widget _buildWithdrawButton() {
    return OutlinedButton(
      onPressed: () {
        // Implement action for withdrawing
      },
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: primaryTwo), // Border color (red for emphasis)
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10), // Rounded corners
        ),
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 12), // Padding
      ),
      child: const Text(
        'Withdraw', // Button label
        style: const TextStyle(
            color: primaryTwo, // Text color matches the border
            fontSize: 12,
            fontWeight: FontWeight.bold),
      ),
    );
  }
}
