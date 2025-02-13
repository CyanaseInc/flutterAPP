import 'package:cyanase/screens/auth/verification.dart';
import 'package:flutter/material.dart';
import 'package:country_picker/country_picker.dart';
import '../../theme/theme.dart';
import 'first_name_slide.dart';
import 'phone_country_slide.dart';
import 'email_birth_slide.dart';
import 'password_slide.dart';
import 'package:cyanase/helpers/api_helper.dart';
import 'package:cyanase/helpers/database_helper.dart';
import 'package:cyanase/helpers/loader.dart'; // Import the Loader
import 'dart:convert'; // Add this import

class SignupScreen extends StatefulWidget {
  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isCheckingUser = false;
  bool _isLoading = false; // Track loading state
  Map<String, String> _errorMessages = {}; // Store specific validation errors

  // Form fields
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  String _selectedCountryCode = ''; // No default value needed
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _monthController = TextEditingController();
  final TextEditingController _dayController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  String? _selectedGender; // Added for gender selection

  @override
  void initState() {
    super.initState();
    _setupValidationListeners();
  }

  void _setupValidationListeners() {
    _firstNameController.addListener(() => setState(() {}));
    _lastNameController.addListener(() => setState(() {}));
    _phoneNumberController.addListener(() => setState(() {}));
    _emailController.addListener(() => setState(() {}));
    _yearController.addListener(() => setState(() {}));
    _monthController.addListener(() => setState(() {}));
    _dayController.addListener(() => setState(() {}));
    _passwordController.addListener(() => setState(() {}));
    _confirmPasswordController.addListener(() => setState(() {}));
  }

  void _selectCountry() {
    showCountryPicker(
      context: context,
      showPhoneCode: true,
      onSelect: (Country country) {
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
            _emailController.text.trim().isNotEmpty;
      case 2:
        return _yearController.text.trim().isNotEmpty &&
            _monthController.text.trim().isNotEmpty &&
            _dayController.text.trim().isNotEmpty &&
            _selectedGender != null;
      case 3:
        return _passwordController.text.trim().isNotEmpty &&
            _confirmPasswordController.text.trim().isNotEmpty &&
            _passwordController.text == _confirmPasswordController.text;
      default:
        return false;
    }
  }

  void _nextPage() {
    if (_isCurrentSlideValid()) {
      if (_currentPage == 1) {
        // This is the phone country slide
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please fill out all required fields correctly.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _submitForm() async {
    // Clear previous errors
    setState(() {
      _errorMessages.clear();
    });

    if (!_validateInputs()) return; // Validate inputs before proceeding.

    setState(() {
      _isLoading = true; // Show loader and disable button
    });

    final birthDate =
        '${_yearController.text}-${_monthController.text.padLeft(2, '0')}-${_dayController.text.padLeft(2, '0')}';

    final Map<String, dynamic> userData = {
      'username': _emailController.text.trim(), // Add username if needed
      'email': _emailController.text.trim(),
      'first_name': _firstNameController.text.trim(),
      'last_name': _lastNameController.text.trim(),
      'password': _passwordController.text,
      'confirmpassword': _confirmPasswordController
          .text, // Assuming you have a confirm password field
      'pkg_id': 1, // Assuming this is a static value; update if necessary
      'profile': {
        'created': DateTime.now()
            .toIso8601String(), // Assuming this is when the user is created
        'is_verified': false, // You can modify this based on your actual value
        'gender': _selectedGender,
        'birth_date':
            birthDate, // Assuming birthDate is a variable with the user's birth date
        'country': _countryController.text.trim(),
        'phone_no':
            '$_selectedCountryCode${_phoneNumberController.text.trim()}', // Combining country code and phone number
      }
    };

    try {
      final response = await ApiService.signup(userData);
      // Log the response
      print('Response Message: ${response['message']}');

      if (response['success'] == true) {
        await _saveUserToDatabase(response);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => VerificationScreen()),
        );
      } else {
        // Handle API validation errors specifically
        _handleApiErrors(response['errors']);
      }
    } catch (e) {
      _showErrorPopup('Signup failed: ${e.toString()}');
      print('Signup failed: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false; // Hide loader and enable button
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  /// **Enhanced Input Validation**
  bool _validateInputs() {
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

    if (_phoneNumberController.text.trim().length < 9) {
      _showSnackBar('Enter a valid phone number.');
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

    return isValid;
  }

  /// **Helper Methods**
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
      final parsedDate =
          DateTime(int.parse(year), int.parse(month), int.parse(day));
      return parsedDate.isBefore(DateTime.now());
    } catch (e) {
      return false;
    }
  }

  /// **Handle API Errors Specifically**
  void _handleApiErrors(Map<String, dynamic>? errors) {
    if (errors == null) {
      _showErrorPopup('Phone number or email already exists.');
      return;
    }

    errors.forEach((field, message) {
      _setError(field, message);
    });

    setState(() {}); // Refresh UI with error messages
  }

  Future<void> _saveUserToDatabase(Map<String, dynamic> response) async {
    final profileData = {
      'id': response['userId'],
      'name': '${_firstNameController.text} ${_lastNameController.text}',
      'phone_number': '$_selectedCountryCode${_phoneNumberController.text}',
      'email': _emailController.text,
      'created_at': DateTime.now().toIso8601String(),
    };

    final dbHelper = DatabaseHelper();
    await dbHelper.insertUser(profileData);
  }

  void _checkUserExistence() async {
    setState(() {
      _isCheckingUser = true;
    });
    String phoneno =
        '${_selectedCountryCode}${_phoneNumberController.text.trim()}';
    print(phoneno);
    try {
      final response = await ApiService.checkup({
        'email': _emailController.text.trim(),
        'phone': phoneno,
      });

      if (response['email_exists'] == false &&
          response['phone_exists'] == false) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        String message = response['message'];
        if (message.isEmpty) {
          message = response['email_exists'] == true
              ? 'Email already exists.'
              : 'Phone number already exists.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error checking user: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isCheckingUser = false;
      });
    }
  }

  void _showErrorPopup(String message) {
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
  @override
  Widget build(BuildContext context) {
    const Color yourPrimaryColor = primaryTwo;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Signup'),
      ),
      body: Stack(
        children: [
          // Main content
          Column(
            children: [
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
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
                      onPhoneChanged: (code) => setState(() {
                        _selectedCountryCode = code;
                      }),
                      selectCountry: _selectCountry,
                    ),
                    EmailBirthSlide(
                      yearController: _yearController,
                      monthController: _monthController,
                      dayController: _dayController,
                      selectedGender: _selectedGender,
                      onGenderSelected: (gender) => setState(() {
                        _selectedGender = gender;
                      }),
                    ),
                    PasswordSlide(
                      passwordController: _passwordController,
                      confirmPasswordController: _confirmPasswordController,
                    ),
                  ],
                ),
              ),
              _buildNavigationButtons(yourPrimaryColor),
            ],
          ),

          // Full-screen overlay with loader
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5), // Semi-transparent overlay
              child: const Center(
                child: Loader(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons(Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentPage > 0)
            ElevatedButton(
              onPressed:
                  _isLoading ? null : _previousPage, // Disable if loading
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: white,
              ),
              child: const Text('Previous'),
            ),
          ElevatedButton(
            onPressed: _isLoading ? null : _nextPage, // Disable if loading
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  _isCurrentSlideValid() ? primaryColor : Colors.grey,
              foregroundColor: white,
            ),
            child: Text(_currentPage < 3 ? 'Next' : 'Submit'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
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
