import 'package:cyanase/helpers/web_db.dart';
import 'package:cyanase/screens/auth/verification.dart';
import 'package:flutter/material.dart';
import 'package:country_picker/country_picker.dart';
import 'package:flutter/services.dart';
import '../../theme/theme.dart';
import 'first_name_slide.dart';
import 'phone_country_slide.dart';
import 'email_birth_slide.dart';
import 'password_slide.dart';
import 'package:cyanase/helpers/api_helper.dart';
import 'package:cyanase/helpers/database_helper.dart';
import 'package:cyanase/helpers/loader.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isCheckingUser = false;
  bool _isLoading = false;
  final Map<String, String> _errorMessages = {};
  
  String? _inviteCode;

  // Form fields
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  String _selectedCountryCode = '+256'; // Default to Uganda
  String _phoneNumber = ''; // Store clean phone number
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _monthController = TextEditingController();
  final TextEditingController _dayController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  String? _selectedGender;

  @override
  void initState() {
    super.initState();
    _setupValidationListeners();
    _loadInviteCode();
    _countryController.text = 'Uganda';
    
    // Listen to phone number changes
    _phoneNumberController.addListener(() {
      setState(() {
        _phoneNumber = _phoneNumberController.text;
      });
      print("[DEBUG] Phone number updated: $_phoneNumber");
    });
  }

  void _setupValidationListeners() {
    _firstNameController.addListener(() => setState(() {}));
    _lastNameController.addListener(() => setState(() {}));
    _emailController.addListener(() => setState(() {}));
    _yearController.addListener(() => setState(() {}));
    _monthController.addListener(() => setState(() {}));
    _dayController.addListener(() => setState(() {}));
    _passwordController.addListener(() => setState(() {}));
    _confirmPasswordController.addListener(() => setState(() {}));
  }

  Future<void> _loadInviteCode() async {
    try {
      final code = await DatabaseHelper().getInviteCode();
      print("[DEBUG] Loaded invite code: $_inviteCode");
      setState(() {
        _inviteCode = code ?? "";
      });

    } catch (e) {
      print('[ERROR] Loading invite code: $e');
      setState(() {
        _inviteCode = "";
      });
    }
  }

  void _selectCountry() {
    print("[DEBUG] Opening country picker");
    showCountryPicker(
      context: context,
      showPhoneCode: true,
      onSelect: (Country country) {
        print("[DEBUG] Country selected: ${country.name}, Code: +${country.phoneCode}");
        setState(() {
          _selectedCountryCode = "+${country.phoneCode}";
          _countryController.text = country.name;
        });
      },
    );
  }

  bool _isCurrentSlideValid() {
    switch (_currentPage) {
      case 0:
        return _firstNameController.text.trim().isNotEmpty &&
            _lastNameController.text.trim().isNotEmpty;
      case 1:
        return _phoneNumberController.text.trim().isNotEmpty &&
            _countryController.text.trim().isNotEmpty &&
            _emailController.text.trim().isNotEmpty &&
            _isValidEmail(_emailController.text.trim());
      case 2:
        return _yearController.text.trim().isNotEmpty &&
            _monthController.text.trim().isNotEmpty &&
            _dayController.text.trim().isNotEmpty &&
            _selectedGender != null;
      case 3:
        return _passwordController.text.trim().isNotEmpty &&
            _confirmPasswordController.text.trim().isNotEmpty &&
            _passwordController.text == _confirmPasswordController.text &&
            _passwordController.text.length >= 6;
      default:
        return false;
    }
  }

  void _nextPage() {
    print("[DEBUG] Next page clicked, current page: $_currentPage");
    if (_isCurrentSlideValid()) {
      if (_currentPage == 1) {
        _checkUserExistence();
      } else if (_currentPage < 3) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        _submitForm();
      }
    } else {
      String errorMessage = '';
      switch (_currentPage) {
        case 0:
          errorMessage = 'Please enter first and last name';
          break;
        case 1:
          if (!_isValidEmail(_emailController.text.trim())) {
            errorMessage = 'Please enter a valid email address';
          } else if (_phoneNumberController.text.trim().isEmpty) {
            errorMessage = 'Please enter a phone number';
          } else {
            errorMessage = 'Please fill out all required fields';
          }
          break;
        case 2:
          if (_selectedGender == null) {
            errorMessage = 'Please select a gender';
          } else {
            errorMessage = 'Please enter a valid birth date';
          }
          break;
        case 3:
          if (_passwordController.text.length < 6) {
            errorMessage = 'Password must be at least 6 characters';
          } else if (_passwordController.text != _confirmPasswordController.text) {
            errorMessage = 'Passwords do not match';
          } else {
            errorMessage = 'Please fill out all required fields';
          }
          break;
      }
      
      _showSnackBar(errorMessage);
    }
  }

  void _previousPage() {
    print("[DEBUG] Previous page clicked");
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // Helper method to get clean phone number
  String _getCleanPhoneNumber() {
    // Remove any non-numeric characters
    String fullPhone = _phoneNumber;
   

   
    
    return fullPhone;
  }

  void _submitForm() async {
    
    setState(() {
      _errorMessages.clear();
    });

    if (!_validateInputs()) return;

    setState(() {
      _isLoading = true;
    });

    final birthDate =
        '${_yearController.text}-${_monthController.text.padLeft(2, '0')}-${_dayController.text.padLeft(2, '0')}';

    // Get clean phone number
    String fullPhoneNumber = _getCleanPhoneNumber();
    


    final Map<String, dynamic> userData = {
      'username': _emailController.text.trim(),
      'email': _emailController.text.trim(),
      'first_name': _firstNameController.text.trim(),
      'last_name': _lastNameController.text.trim(),
      'password': _passwordController.text,
      'confirmpassword': _confirmPasswordController.text,
      'pkg_id': 1,
      'invite_code': _inviteCode,
      'profile': {
        'created': DateTime.now().toIso8601String(),
        'is_verified': false,
        'gender': _selectedGender,
        'birth_date': birthDate,
        'country': _countryController.text.trim(),
        'phone_no': fullPhoneNumber,
      }
    };

    print("[API] Sending signup request...");
    
    try {
      final response = await ApiService.signup(userData);
    
      
      if (response['success'] == true) {
        print("[SUCCESS] User created successfully");
        // Save user to local database
        await _saveUserToDatabase(response, fullPhoneNumber);
        
        // Navigate to verification screen
        print("[NAVIGATION] Moving to verification screen");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => VerificationScreen(email: _emailController.text.trim()),
          ),
        );
      } else {
        print("[ERROR] API returned success: false");
        _handleApiErrors(response['errors']);
      }
    } catch (e) {
      print('[ERROR] Signup failed: $e');
      _showErrorPopup('Signup failed: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message) {
    print("[SNACKBAR] Showing: $message");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  bool _validateInputs() {
    print("[VALIDATION] Validating inputs...");
    bool isValid = true;

    if (_firstNameController.text.trim().isEmpty) {
      _showSnackBar('First name is required.');
      isValid = false;
    }

    if (_lastNameController.text.trim().isEmpty) {
      _showSnackBar('Last name is required.');
      isValid = false;
    }

    if (!_isValidEmail(_emailController.text.trim())) {
      _showSnackBar('Enter a valid email address.');
      isValid = false;
    }

    if (_passwordController.text.length < 6) {
      _showSnackBar('Password must be at least 6 characters.');
      isValid = false;
    }

    // Validate phone number
    String rawPhone = _phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    print("[VALIDATION] Phone validation - Raw: $rawPhone, Length: ${rawPhone.length}");
    if (rawPhone.isEmpty) {
      _showSnackBar('Phone number is required.');
      isValid = false;
    } else if (rawPhone.length < 9) {
      _showSnackBar('Enter a valid phone number (at least 9 digits).');
      isValid = false;
    }

    if (_countryController.text.trim().isEmpty) {
      _showSnackBar('Country is required.');
      isValid = false;
    }

    if (!_isValidDate(
        _yearController.text, _monthController.text, _dayController.text)) {
      _showSnackBar('Enter a valid birthdate.');
      isValid = false;
    }

    if (_selectedGender == null) {
      _showSnackBar('Select a gender.');
      isValid = false;
    }

    print("[VALIDATION] Is valid: $isValid");
    return isValid;
  }

  void _setError(String field, String message) {
    _errorMessages[field] = message;
  }

  bool _isValidEmail(String email) {
    final emailRegex =
        RegExp(r'^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$');
    return emailRegex.hasMatch(email);
  }

  bool _isValidDate(String year, String month, String day) {
    try {
      final parsedYear = int.tryParse(year);
      final parsedMonth = int.tryParse(month);
      final parsedDay = int.tryParse(day);
      
      if (parsedYear == null || parsedMonth == null || parsedDay == null) {
        return false;
      }
      
      final parsedDate = DateTime(parsedYear, parsedMonth, parsedDay);
      return parsedDate.isBefore(DateTime.now());
    } catch (e) {
      return false;
    }
  }

  void _handleApiErrors(Map<String, dynamic>? errors) {
    if (errors == null) {
      _showErrorPopup('Phone number or email already exists.');
      return;
    }

    print("[API ERRORS] Received: $errors");
    errors.forEach((field, message) {
      _setError(field, message.toString());
    });

    setState(() {});
  }

  Future<void> _saveUserToDatabase(Map<String, dynamic> response, String phoneNumber) async {
    try {
      print("[DATABASE] Saving user to database...");
      print("[DATABASE] Response: $response");
      
      // Extract user data with null safety
      final userData = response['user'] as Map<String, dynamic>?;
      if (userData == null) {
        throw Exception('User data is null in response');
      }

      // Safely extract values with proper type casting
      final String userId = (userData['user_id']?.toString() ?? '0');
      final String token = (userData['token'] as String?) ?? '';
      final String email = (userData['email'] as String?) ?? _emailController.text.trim();
      final String firstName = (userData['first_name'] as String?) ?? _firstNameController.text.trim();
      final String lastName = (userData['last_name'] as String?) ?? _lastNameController.text.trim();

      // Validate critical fields
      if (userId == '0') {
        throw Exception('User ID is missing from response');
      }
      if (token.isEmpty) {
        throw Exception('Authentication token is missing from response');
      }

      // Prepare profile data
      final profileData = {
        'id': userId,
        'token': token,
        'name': '$firstName $lastName',
        'phone_number': phoneNumber,
        'email': email,
        'country': _countryController.text.trim(),
        'created_at': DateTime.now().toIso8601String(),
        'auto_save': false,
        'goals_alert': false,
      };

      print("[DATABASE] Profile data to save: $profileData");

      final dbHelper = DatabaseHelper();
      await dbHelper.insertUser(profileData);
      
      // Also save to web storage
      await setStorage(response, phoneNumber);
      
      print("[DATABASE] User data saved successfully!");
      
    } catch (e) {
      print('[DATABASE ERROR] Error saving user: $e');
      rethrow;
    }
  }

  Future<void> setStorage(Map<String, dynamic> response, String phoneNumber) async {
    try {
      print("[WEB STORAGE] Saving to web storage...");
      await WebSharedStorage.init();
      final webshare = WebSharedStorage();
      
      // Extract user data with null safety
      final userData = response['user'] as Map<String, dynamic>?;
      if (userData == null) {
        throw Exception('User data is null for web storage');
      }

      // Safely extract values
      final String userId = (userData['user_id']?.toString() ?? '0');
      final String token = (userData['token'] as String?) ?? '';
      final String email = (userData['email'] as String?) ?? _emailController.text.trim();
      final String firstName = (userData['first_name'] as String?) ?? _firstNameController.text.trim();
      final String lastName = (userData['last_name'] as String?) ?? _lastNameController.text.trim();

      // Save to web storage with proper values
      webshare.setCommon('id', userId);
      webshare.setCommon('token', token);
      webshare.setCommon('name', '$firstName $lastName');
      webshare.setCommon('phone_number', phoneNumber);
      webshare.setCommon('email', email);
      webshare.setCommon('country', _countryController.text.trim());
      webshare.setCommon('created_at', DateTime.now().toIso8601String());
      
      print("[WEB STORAGE] Data saved successfully!");
      
    } catch (e) {
      print('[WEB STORAGE ERROR] Error: $e');
      rethrow;
    }
  }

  void _checkUserExistence() async {
    print("[CHECK USER] Checking user existence...");
    setState(() {
      _isCheckingUser = true;
    });
    
    String phoneno = _getCleanPhoneNumber();
    
    print("  Email: ${_emailController.text.trim()}");
    print("  Phone: $phoneno");
    
    try {
      final response = await ApiService.checkup({
        'email': _emailController.text.trim(),
        'phone': phoneno,
      });

   
      if (response['email_exists'] == false &&
          response['phone_exists'] == false) {
        print("[CHECK USER] User doesn't exist, moving to next page");
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        String message = response['message']?.toString() ?? '';
        if (message.isEmpty) {
          message = response['email_exists'] == true
              ? 'Email already exists.'
              : 'Phone number already exists.';
        }
        _showSnackBar(message);
      }
    } catch (e) {
      print('[CHECK USER ERROR] $e');
      _showSnackBar('Check your internet connection: ${e.toString()}');
    } finally {
      setState(() {
        _isCheckingUser = false;
      });
    }
  }

  void _showErrorPopup(String message) {
    print("[ERROR POPUP] Showing: $message");
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    print("[BUILD] Building SignupScreen, current page: $_currentPage");
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Signup',
          style: TextStyle(
            color: white,
          ),
        ),
        backgroundColor: primaryTwo,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: primaryTwo,
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                    print("[PAGE CHANGE] Switched to page: $index");
                  },
                  children: [
                    FirstNameSlide(
                      firstNameController: _firstNameController,
                      lastNameController: _lastNameController,
                    ),
                    PhoneCountrySlide(
                      phoneNumberController: _phoneNumberController,
                      countryController: _countryController,
                      emailController: _emailController,
                      onPhoneChanged: (phone) {
                        print("[PHONE SLIDE] Phone changed: $phone");
                        setState(() {
                          _phoneNumber = phone;
                        });
                      },
                      selectCountry: _selectCountry,
                      isLoading: _isCheckingUser,
                    ),
                    EmailBirthSlide(
                      yearController: _yearController,
                      monthController: _monthController,
                      dayController: _dayController,
                      selectedGender: _selectedGender,
                      onGenderSelected: (gender) {
                        print("[GENDER] Selected: $gender");
                        setState(() {
                          _selectedGender = gender;
                        });
                      },
                    ),
                    PasswordSlide(
                      passwordController: _passwordController,
                      confirmPasswordController: _confirmPasswordController,
                    ),
                  ],
                ),
              ),
              _buildNavigationButtons(),
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

  Widget _buildNavigationButtons() {
    bool isValid = _isCurrentSlideValid();
    print("[BUTTONS] Is current slide valid: $isValid");
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentPage > 0)
            ElevatedButton(
              onPressed: _isLoading ? null : _previousPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: white,
                minimumSize: const Size(120, 50),
              ),
              child: const Text('Previous'),
            ),
          ElevatedButton(
            onPressed: _isLoading ? null : _nextPage,
            style: ElevatedButton.styleFrom(
              backgroundColor: isValid ? primaryColor : Colors.grey,
              foregroundColor: white,
              minimumSize: const Size(120, 50),
            ),
            child: Text(_currentPage < 3 ? 'Next' : 'Submit'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    print("[DISPOSE] Cleaning up SignupScreen");
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneNumberController.dispose();
    _countryController.dispose();
    _emailController.dispose();
    _yearController.dispose();
    _monthController.dispose();
    _dayController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _pageController.dispose();
    super.dispose();
  }
}