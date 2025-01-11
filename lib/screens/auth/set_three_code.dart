import 'package:flutter/material.dart';
import '../../theme/theme.dart'; // Import your theme file

class SetCodeScreen extends StatefulWidget {
  const SetCodeScreen({Key? key}) : super(key: key);

  @override
  _SetCodeScreenState createState() => _SetCodeScreenState();
}

class _SetCodeScreenState extends State<SetCodeScreen> {
  final int _passcodeLength = 4;
  String _input = "";
  String _confirmedInput = "";
  bool _isConfirming = false;

  void _onNumberPressed(String number) {
    if ((_isConfirming ? _confirmedInput : _input).length < _passcodeLength) {
      setState(() {
        if (_isConfirming) {
          _confirmedInput += number;
        } else {
          _input += number;
        }
      });

      if ((_isConfirming ? _confirmedInput : _input).length ==
          _passcodeLength) {
        if (_isConfirming) {
          _verifyPasscode();
        } else {
          setState(() {
            _isConfirming = true;
          });
        }
      }
    }
  }

  void _onDeletePressed() {
    setState(() {
      if (_isConfirming && _confirmedInput.isNotEmpty) {
        _confirmedInput =
            _confirmedInput.substring(0, _confirmedInput.length - 1);
      } else if (!_isConfirming && _input.isNotEmpty) {
        _input = _input.substring(0, _input.length - 1);
      }
    });
  }

  void _verifyPasscode() {
    if (_input == _confirmedInput) {
      // Passcode setup successful
      print("Passcode set: $_input");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Passcode successfully set!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      // Passcodes do not match
      setState(() {
        _input = "";
        _confirmedInput = "";
        _isConfirming = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Passcodes do not match. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/logo.png', // Your logo image here
            height: 100,
            width: 70,
          ),
          const SizedBox(height: 20),
          Text(
            _isConfirming ? 'Confirm your passcode' : 'Set your passcode',
            style: const TextStyle(
              fontSize: 20,
              color: primaryTwo, // Use primaryTwo color from theme
            ),
          ),
          const SizedBox(height: 40),
          // Display passcode dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _passcodeLength,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 8.0),
                width: 16.0,
                height: 16.0,
                decoration: BoxDecoration(
                  color:
                      index < (_isConfirming ? _confirmedInput : _input).length
                          ? primaryTwo
                          : Colors.grey,
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
                            border: Border.all(color: primaryTwo, width: 0.5),
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

          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
