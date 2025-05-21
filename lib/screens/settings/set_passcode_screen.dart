import 'package:cyanase/helpers/database_helper.dart';
import 'package:cyanase/helpers/loader.dart';
import 'package:flutter/material.dart';
import '../../theme/theme.dart';
import 'package:cyanase/helpers/api_helper.dart';

class SetPasscodeScreen extends StatefulWidget {
  const SetPasscodeScreen({Key? key}) : super(key: key);

  @override
  _SetPasscodeScreenState createState() => _SetPasscodeScreenState();
}

class _SetPasscodeScreenState extends State<SetPasscodeScreen> {
  final int _passcodeLength = 4;
  String _input = "";
  String _confirmedInput = "";
  String _oldPasscode = "";
  bool _isConfirming = false;
  bool _isLoading = false;
  bool _isVerifyingOld = true;
  String _email = '';
  String _token = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;
    final userProfile = await db.query('profile', limit: 1);

    setState(() {
      _token = userProfile.first['token'] as String? ?? '';
      _email = userProfile.first['email'] as String? ?? '';
    });
  }

  void _onNumberPressed(String number) {
    if (_isVerifyingOld) {
      if (_oldPasscode.length < _passcodeLength) {
        setState(() {
          _oldPasscode += number;
        });

        if (_oldPasscode.length == _passcodeLength) {
          _verifyOldPasscode();
        }
      }
    } else {
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
            _submitPasscode();
          } else {
            setState(() {
              _isConfirming = true;
            });
          }
        }
      }
    }
  }

  void _onDeletePressed() {
    setState(() {
      if (_isVerifyingOld) {
        if (_oldPasscode.isNotEmpty) {
          _oldPasscode = _oldPasscode.substring(0, _oldPasscode.length - 1);
        }
      } else {
        if (_isConfirming && _confirmedInput.isNotEmpty) {
          _confirmedInput =
              _confirmedInput.substring(0, _confirmedInput.length - 1);
        } else if (!_isConfirming && _input.isNotEmpty) {
          _input = _input.substring(0, _input.length - 1);
        }
      }
    });
  }

  Future<void> _verifyOldPasscode() async {
    setState(() => _isLoading = true);

    try {
      final response = await ApiService.verifyPasscode(
          _token, {"email": _email, "code": _oldPasscode});

      if (response['success'] == true) {
        setState(() {
          _isVerifyingOld = false;
          _isLoading = false;
        });
      } else {
        throw Exception("Invalid passcode");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Invalid passcode"),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _oldPasscode = "";
        _isLoading = false;
      });
    }
  }

  Future<void> _submitPasscode() async {
    if (_input != _confirmedInput) {
      setState(() {
        _input = "";
        _confirmedInput = "";
        _isConfirming = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passcodes do not match. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response =
          await ApiService.Setpasscode({"email": _email, "code": _input});

      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Passcode successfully updated!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        throw Exception(response['message'] ?? "Something went wrong");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Change Passcode"),
        titleTextStyle: const TextStyle(
          color: white,
          fontSize: 24,
        ),
        backgroundColor: primaryTwo,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: white),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
        iconTheme: const IconThemeData(
          color: white,
        ),
      ),
      body: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Center(
                child: Text(
                  _isVerifyingOld
                      ? 'Enter current passcode'
                      : _isConfirming
                          ? 'Confirm new passcode'
                          : 'Enter new passcode',
                  style: const TextStyle(
                    fontSize: 20,
                    color: primaryTwo,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  _isVerifyingOld
                      ? 'Please enter your current passcode'
                      : 'You will use this to login easily next time',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
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
                      color: index <
                              (_isVerifyingOld
                                      ? _oldPasscode
                                      : _isConfirming
                                          ? _confirmedInput
                                          : _input)
                                  .length
                          ? primaryTwo
                          : Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Numeric keypad
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
                                border:
                                    Border.all(color: primaryTwo, width: 0.5),
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
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: Loader(),
              ),
            ),
        ],
      ),
    );
  }
}
