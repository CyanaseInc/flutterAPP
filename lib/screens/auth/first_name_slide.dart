import 'package:flutter/material.dart';
import '../../theme/theme.dart';

class FirstNameSlide extends StatelessWidget {
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;

  const FirstNameSlide({
    Key? key,
    required this.firstNameController,
    required this.lastNameController,
  }) : super(key: key);

  bool validateInputs(BuildContext context) {
    if (firstNameController.text.trim().isEmpty) {
      showErrorDialog(context, 'First name is required.');
      return false;
    }
    if (lastNameController.text.trim().isEmpty) {
      showErrorDialog(context, 'Last name is required.');
      return false;
    }
    return true;
  }

  void showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Validation Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Image.asset(
              'assets/logo.png',
              height: 100,
              width: 70,
            ),
          ),
          const SizedBox(height: 16),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Welcome to Cyanase!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: primaryTwo,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text("Enter your first and last name to continue."),
          ),
          const SizedBox(height: 50),
          TextField(
            controller: firstNameController,
            keyboardType: TextInputType.name,
            decoration: const InputDecoration(labelText: 'First Name'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: lastNameController,
            keyboardType: TextInputType.name,
            decoration: const InputDecoration(labelText: 'Last Name'),
          ),
        ],
      ),
    );
  }
}
