import 'package:flutter/material.dart';
import '../../theme/theme.dart'; // Import your theme file
import 'login_with_phone.dart';
import 'signup.dart';
import '../home/home.dart';
import 'package:cyanase/helpers/database_helper.dart'; // Import the DatabaseHelper
// For contacts permission
import 'package:cyanase/screens/home/group/hash_numbers.dart'; // Import the file containing fetchAndHashContacts and getRegisteredContacts
import 'package:cyanase/helpers/loader.dart';

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

  Future<void> _verifyPasscode(String passcode) async {
    final dbHelper = DatabaseHelper(); // Get the DatabaseHelper instance

    // Show a loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Loader(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );

    try {
      // Initialize the database
      await dbHelper.database;

      // Fetch and process contacts using the existing function
      List<Map<String, String>> contacts = await fetchAndHashContacts();
      List<Map<String, dynamic>> registeredContacts =
          await getRegisteredContacts(contacts);
      // Dismiss the loading indicator
      Navigator.pop(context);

      // Navigate to HomeScreen with registered contacts
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(),
        ),
      );
    } catch (e) {
      print('Error: $e');
      // Dismiss the loading indicator
      Navigator.pop(context);

      // Show an error dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text('Failed to authenticate or fetch contacts: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/logo.png',
            height: 100,
            width: 70,
          ),
          const SizedBox(height: 20),
          const Text(
            'Enter pass code to login',
            style: TextStyle(
              fontSize: 20,
              color: primaryTwo,
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
          Column(
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
                      return SizedBox(
                        width: 60,
                        height: 60,
                        child: Container(), // Empty space placeholder
                      );
                    } else if (item == "\u232b") {
                      return GestureDetector(
                        onTap: _onDeletePressed,
                        child: Container(
                          width: 60,
                          height: 60,
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
                              fontSize: 20,
                              color: primaryTwo,
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
                color: primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SignupScreen(),
                ),
              );
            },
            child: const Text(
              'Don’t have an account? Sign up!',
              style: TextStyle(
                color: primaryTwo,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
