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