import 'package:flutter/material.dart';
import '../../theme/theme.dart';

class PasswordSlide extends StatelessWidget {
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;

  const PasswordSlide({
    Key? key,
    required this.passwordController,
    required this.confirmPasswordController,
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
              'assets/images/logo.png',
              height: 100,
              width: 70,
            ),
          ),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Secure your account!',
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
            child: Text("Add your password to continue."),
          ),
          TextField(
            controller: passwordController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Password'),
          ),
          TextField(
            controller: confirmPasswordController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Confirm Password'),
          ),
        ],
      ),
    );
  }
}
