import 'package:flutter/material.dart';
import '../../theme/theme.dart';

class EmailBirthSlide extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController birthDateController;

  const EmailBirthSlide({
    Key? key,
    required this.emailController,
    required this.birthDateController,
  }) : super(key: key);

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
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'One more step to go!',
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
            child: Text("Enter your email and date of birth to proceed."),
          ),
          TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          TextField(
            controller: birthDateController,
            keyboardType: TextInputType.datetime,
            decoration:
                const InputDecoration(labelText: 'Birth Date (YYYY-MM-DD)'),
          ),
        ],
      ),
    );
  }
}
