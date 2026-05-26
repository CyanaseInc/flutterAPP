import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io';
import '../../theme/theme.dart'; // Import your theme file
import 'login_with_phone.dart';
import 'signup.dart';
import '../home/home.dart';
import 'package:cyanase/helpers/database_helper.dart';
import 'package:cyanase/helpers/loader.dart';
import 'package:cyanase/helpers/api_helper.dart';
import 'package:cyanase/helpers/link_handler.dart';
import 'package:cyanase/screens/home/group/group_invite.dart';
import 'package:provider/provider.dart';
import 'package:cyanase/providers/provider.dart';

class NumericLoginScreen extends StatefulWidget {
  const NumericLoginScreen({Key? key}) : super(key: key);

  @override
  _NumericLoginScreenState createState() => _NumericLoginScreenState();
}

class _NumericLoginScreenState extends State<NumericLoginScreen> {
  final int _passcodeLength = 4;
  String _input = "";
  bool _passcode = false;
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
  final dbHelper = DatabaseHelper();

  if (Platform.isIOS) {
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const CupertinoAlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoActivityIndicator(),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  } else {
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
  }

  try {
    final db = await dbHelper.database;
    final userProfile = await db.query('profile', limit: 1);
    
    if (userProfile.isEmpty) {
      Navigator.pop(context);
      _showErrorSnackBar('No user profile found. Please login with phone number first.');
      return;
    }
    
    final email = userProfile.first['email'] as String?;
    
    if (email == null || email.isEmpty) {
      Navigator.pop(context);
      _showErrorSnackBar('No email found in profile. Please login with phone number first.');
      return;
    }

  final loginResponse = await ApiService.passcodeLogin({
  'username': email,
  'password': passcode,
});

Navigator.pop(context);

// Print the full response
print('Login response: $loginResponse');

// Print the email used
print('Login email: $email');

    if (loginResponse.containsKey('success') && !loginResponse['success']) {
      if (Platform.isIOS) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text(loginResponse['message'] ?? 'Login failed'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loginResponse['message'] ?? 'Login failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (loginResponse.containsKey('token') &&
        loginResponse.containsKey('user_id') &&
        loginResponse.containsKey('user')) {
      
      final token = loginResponse['token'] as String;
      final userId = loginResponse['user_id'];
      final user = loginResponse['user'] as Map<String, dynamic>;

      final email = user['email'] as String? ?? '';
      final firstName = user['first_name'] as String? ?? '';
      final lastName = user['last_name'] as String? ?? '';
      final userName = '$firstName $lastName'.trim();
      
      if (!user.containsKey('profile') || user['profile'] == null) {
        _showErrorSnackBar('Invalid user profile data');
        return;
      }

      final profile = user['profile'] as Map<String, dynamic>;
      
      final picture = profile['profile_picture'] as String? ?? '';
      final userCountry = profile['country'] as String? ?? '';
      final phoneNumber = profile['phoneno'] as String? ?? '';
      final inviteCode = profile['inviteCode'] as String? ?? '';
      final isVerified = profile['is_verified'] as bool? ?? false;
      final mypasscode = profile['passcode'] as String? ?? '';
      
      final financialStats = profile['financial_stats'] as Map<String, dynamic>?;
      
      final currencyCode = loginResponse['currency'] as String? ?? 'UGX';
      final currencySymbol = loginResponse['currency_symbol'] as String? ?? 'UGX';
      
      final profileCurrencyCode = profile['currency'] as String?;
      final profileCurrencySymbol = profile['currency_symbol'] as String?;
      
      final finalCurrencyCode = profileCurrencyCode ?? currencyCode;
      final finalCurrencySymbol = profileCurrencySymbol ?? currencySymbol;

      final autoSave = profile['auto_save'] as bool? ?? false;
      final goalsAlert = profile['goals_alert'] as bool? ?? false;
      
      print('Login successful for: $email');
      print('Username: $userName');
      print('Currency: $finalCurrencyCode, $finalCurrencySymbol');
      print('Invite Code: $inviteCode');

      setState(() {
        _passcode = mypasscode.isNotEmpty;
      });
      
      if (isVerified) {
        final db = await dbHelper.database;
        final existingProfile = await db.query('profile');

        if (existingProfile.isNotEmpty) {
          await db.update(
            'profile',
            {
              'email': email,
              'country': userCountry,
              'phone_number': phoneNumber,
              'token': token,
              'name': userName,
              'profile_pic': picture,
              'created_at': DateTime.now().toIso8601String(),
              'auto_save': autoSave,
              'goals_alert': goalsAlert,
            },
            where: 'id = ?',
            whereArgs: [userId],
          );
        } else {
          await db.insert(
            'profile',
            {
              'id': userId,
              'email': email,
              'country': userCountry,
              'token': token,
              'phone_number': phoneNumber,
              'name': userName,
              'profile_pic': picture,
              'created_at': DateTime.now().toIso8601String(),
              'auto_save': autoSave,
              'goals_alert': goalsAlert,
            },
          );
        }

        final currencyProvider = Provider.of<CurrencyProvider>(context, listen: false);
        
        currencyProvider.setCurrency(finalCurrencyCode, finalCurrencySymbol);
        currencyProvider.setInviteCode(inviteCode);
        
        final financialSummary = loginResponse['financial_summary'] as Map<String, dynamic>?;
        final bonusBreakdown = loginResponse['bonus_breakdown'] as Map<String, dynamic>?;
        final recentActivity = loginResponse['recent_activity'] as Map<String, dynamic>?;
        
        Map<String, dynamic> combinedFinancialSummary = {};
        if (financialSummary != null) {
          combinedFinancialSummary.addAll(financialSummary);
        }
        if (financialStats != null) {
          combinedFinancialSummary.addAll(financialStats);
        }
        
        currencyProvider.setFinancialData(
          financialSummary: combinedFinancialSummary.isNotEmpty ? combinedFinancialSummary : null,
          bonusBreakdown: bonusBreakdown,
          recentActivity: recentActivity,
        );
        
        print('Provider data set successfully');
        
        if (PendingDeepLink.uri != null &&
            PendingDeepLink.uri!.scheme == 'cyanase' &&
            PendingDeepLink.uri!.host == 'join') {
          final groupId = PendingDeepLink.uri!.queryParameters['group_id'];
          if (groupId != null && groupId.isNotEmpty) {
            PendingDeepLink.uri = null;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => GroupInviteScreen(
                  groupId: int.parse(groupId),
                ),
              ),
            );
            return;
          }
        }
        
        await Future.delayed(const Duration(milliseconds: 100));
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(
              passcode: _passcode, 
              name: userName,
              picture: picture,
              email: email,
            ),
          ),
        );
      } else {
        _showVerificationBottomSheet(phoneNumber);
      }
    } else {
      _showErrorSnackBar('Invalid login response: Missing required fields');
    }
  } catch (e) {
    Navigator.pop(context);
    print('Login error: $e');
    
    if (Platform.isIOS) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Error'),
          content: Text('Check your network connection: ${e.toString()}'),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Check your network connection: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
// ADD THIS METHOD IF IT DOESN'T EXIST


void _showErrorSnackBar(String message) {
  if (Platform.isIOS) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
void _showVerificationBottomSheet(String phoneNumber) {
  showModalBottomSheet(
    context: context,
    builder: (context) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Account Verification Required',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text('Please verify your account to continue.'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Add your verification logic here
              },
              child: const Text('Verify Account'),
            ),
          ],
        ),
      );
    },
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
            'assets/images/logo.png',
            height: 100,
            width: 70,
          ),
          const SizedBox(height: 20),
          Text(
            'Enter pass code to login',
            style: TextStyle(
              fontSize: 20,
              color: primaryTwo,
              fontFamily: Platform.isIOS ? '.SF Pro Text' : null,
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
                          child: Icon(
                            Platform.isIOS ? CupertinoIcons.delete : Icons.backspace,
                            size: 28,
                          ),
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
                            style: TextStyle(
                              fontSize: 20,
                              color: primaryTwo,
                              fontFamily: Platform.isIOS ? '.SF Pro Text' : null,
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
            child: Text(
              'Login using Phone number?',
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.bold,
                fontFamily: Platform.isIOS ? '.SF Pro Text' : null,
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
            child: Text(
              "Don't have an account? Sign up!",
              style: TextStyle(
                color: primaryTwo,
                fontWeight: FontWeight.bold,
                fontSize: 18,
                fontFamily: Platform.isIOS ? '.SF Pro Text' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}