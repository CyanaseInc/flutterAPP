import 'package:cyanase/screens/auth/verification.dart';
import 'package:flutter/material.dart';
import 'package:country_picker/country_picker.dart';
import 'package:sim_card_info/sim_card_info.dart';
import '../../theme/theme.dart';
import 'first_name_slide.dart';
import 'phone_country_slide.dart';
import 'email_birth_slide.dart';
import 'password_slide.dart';
import 'package:cyanase/helpers/api_helper.dart';
import 'package:cyanase/helpers/database_helper.dart';
import 'package:cyanase/helpers/loader.dart'; // Import the Loader

class SignupScreen extends StatefulWidget {
  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = false; // Track loading state

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
      if (_currentPage < 3) {
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
    setState(() {
      _isLoading = true; // Show loader and disable button
    });

    // Combine year, month, and day into a single string (YYYY-MM-DD)
    final birthDate =
        '${_yearController.text}-${_monthController.text.padLeft(2, '0')}-${_dayController.text.padLeft(2, '0')}';

    // Prepare the data to send
    final Map<String, dynamic> userData = {
      'firstName': _firstNameController.text,
      'lastName': _lastNameController.text,
      'email': _emailController.text,
      'password': _passwordController.text,
      'phoneNumber': '$_selectedCountryCode${_phoneNumberController.text}',
      'country': _countryController.text,
      'birthDate': birthDate,
      'gender': _selectedGender, // Added gender field
    };

    try {
      // Call the signup method from ApiService
      final response = await ApiService.signup(userData);

      // Check if the registration was successful
      if (response['success'] == true) {
        final Map<String, dynamic> profileData = {
          'id': response['userId'], // Assuming the API returns a userId
          'name': '${_firstNameController.text} ${_lastNameController.text}',
          'phone_number': '$_selectedCountryCode${_phoneNumberController.text}',
          'email': _emailController.text,
          'created_at': DateTime.now().toIso8601String(),
        };

        // Insert the profile data into the database
        final dbHelper = DatabaseHelper();
        await dbHelper.insertUser(profileData);

        // Success: Navigate to the verification screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VerificationScreen(),
          ),
        );
      } else {
        // Handle server-side errors (e.g., email already exists)
        _showErrorPopup(response['message'] ?? 'Registration failed');
      }
    } catch (e) {
      // Handle network or other errors
      _showErrorPopup('Signup failed: $e');
    } finally {
      setState(() {
        _isLoading = false; // Hide loader and enable button
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
  Widget build(BuildContext context) {
    const Color yourPrimaryColor = primaryTwo;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Signup'),
      ),
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
          if (_isLoading) // Show transparent overlay and loader
            Container(
              color: Colors.black.withOpacity(0.5), // Transparent overlay
              child: const Center(
                child: Loader(), // Use the Loader widget
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
