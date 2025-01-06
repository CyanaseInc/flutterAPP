import 'package:flutter/material.dart';
import '../../theme/theme.dart'; // Import your theme file
import 'login_first.dart';
import 'signup.dart';
import '../home/home.dart';

class NumericLoginScreen extends StatefulWidget {
  const NumericLoginScreen({Key? key}) : super(key: key);

  @override
  _NumericLoginScreenState createState() => _NumericLoginScreenState();
}

class _NumericLoginScreenState extends State<NumericLoginScreen> {
  final int _passcodeLength = 4;
  String _input = "";

  void _onNumberPressed(String number) {
    if (_input.length < _passcodeLength) {
      setState(() {
        _input += number;
      });

      if (_input.length == _passcodeLength) {
        // Handle passcode submission
        _verifyPasscode(_input);
      }
    }
  }

  void _onDeletePressed() {
    if (_input.isNotEmpty) {
      setState(() {
        _input = _input.substring(0, _input.length - 1);
      });
    }
  }

  void _verifyPasscode(String passcode) {
    // Add logic to verify the passcode
    print("Entered Passcode: $passcode");
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HomeScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/logo.png', // Your logo image here
            height: 100,
            width: 70,
          ),
          const SizedBox(height: 20),
//Display passcode dots
          const Text(
            'Enter pass code to login',
            style: TextStyle(
              fontSize: 20,

              color: primaryTwo, // Use primaryTwo color from theme
            ),
          ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _passcodeLength,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 8.0),
                width: 16.0,
                height: 16.0,
                decoration: BoxDecoration(
                  color: index < _input.length ? primaryTwo : Colors.grey,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
          // Numeric keypad with your initial design
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var row in [
                ["1", "2", "3"],
                ["4", "5", "6"],
                ["7", "8", "9"],
                ["", "0", "\u232b"]
              ])
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: row.map((item) {
                    if (item == "") {
                      return const SizedBox(width: 60, height: 60);
                    } else if (item == "\u232b") {
                      return GestureDetector(
                        onTap: _onDeletePressed,
                        child: Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          child: const Icon(Icons.backspace, size: 28),
                        ),
                      );
                    } else {
                      return GestureDetector(
                        onTap: () => _onNumberPressed(item),
                        child: Container(
                          margin: const EdgeInsets.all(8.0),
                          width: 60,
                          height: 60,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(30.0),
                            border: Border.all(color: primaryTwo, width: 1),
                          ),
                          child: Text(
                            item,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    }
                  }).toList(),
                ),
            ],
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () {
              // Navigate to the Passcode Login screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LoginScreen(),
                ),
              );
            },
            child: const Text(
              'Login using Phone number?',
              style: TextStyle(
                color: primaryColor, // Use primaryColor from theme
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () {
              // Navigate to the Passcode Login screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SignupScreen(),
                ),
              );
            },
            child: const Text(
              'Dont have an account signup?',
              style: TextStyle(
                  // Use primaryColor from theme
                  fontWeight: FontWeight.bold,
                  fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }
}
