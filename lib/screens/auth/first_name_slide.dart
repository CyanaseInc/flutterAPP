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
    return Scaffold(
      body: SingleChildScrollView(
        // Wrap the Column in a SingleChildScrollView
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Center(
                child: Image.asset(
                  'assets/images/logo.png',
                  height: 100,
                  width: 70,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Welcome to Cyanase!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: primaryTwo,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                "Enter your first and last name to continue.",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 50),
              // First Name TextField with bottom border only
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: TextField(
                  controller: firstNameController,
                  keyboardType: TextInputType.name,
                  decoration: InputDecoration(
                    labelText: 'First Name',
                    labelStyle: TextStyle(color: primaryTwo),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: primaryTwo),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: primaryTwo),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Last Name TextField with bottom border only
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: TextField(
                  controller: lastNameController,
                  keyboardType: TextInputType.name,
                  decoration: InputDecoration(
                    labelText: 'Last Name',
                    labelStyle: TextStyle(color: primaryTwo),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: primaryTwo),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: primaryTwo),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
