// Refactor of the SignupScreen code to separate each slide into its own file

// signup.dart
import 'package:cyanase/screens/auth/verification.dart';
import 'package:flutter/material.dart';
import 'package:country_picker/country_picker.dart';
import 'package:sim_card_info/sim_card_info.dart';
import '../../theme/theme.dart';
import 'first_name_slide.dart';
import 'phone_country_slide.dart';
import 'email_birth_slide.dart';
import 'password_slide.dart';

class SignupScreen extends StatefulWidget {
  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Form fields
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  String _selectedCountryCode = '+1'; // Default to US
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _detectSimCountry();
    _setupValidationListeners();
  }

  void _setupValidationListeners() {
    _firstNameController.addListener(() => setState(() {}));
    _lastNameController.addListener(() => setState(() {}));
    _phoneNumberController.addListener(() => setState(() {}));
    _emailController.addListener(() => setState(() {}));
    _birthDateController.addListener(() => setState(() {}));
    _passwordController.addListener(() => setState(() {}));
    _confirmPasswordController.addListener(() => setState(() {}));
  }

  Future<void> _detectSimCountry() async {
    try {
      final simCardInfo = await SimCardInfo().getSimInfo();
      if (simCardInfo != null && simCardInfo.isNotEmpty) {
        final sim = simCardInfo.first;
        setState(() {
          _selectedCountryCode = "+${sim.countryPhonePrefix}";
          _countryController.text = sim.countryIso.toUpperCase();
        });
      } else {
        _setDefaultCountry();
      }
    } catch (e) {
      print("Failed to detect SIM country: $e");
      _setDefaultCountry();
    }
  }

  void _setDefaultCountry() {
    setState(() {
      _selectedCountryCode = '+256'; // Default to Uganda
      _countryController.text = 'Uganda';
    });
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
            _countryController.text.trim().isNotEmpty;
      case 2:
        return _emailController.text.trim().isNotEmpty &&
            _birthDateController.text.trim().isNotEmpty;
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

  void _submitForm() {
    print("First Name: ${_firstNameController.text}");
    print("Last Name: ${_lastNameController.text}");
    print("Phone Number: ${_phoneNumberController.text}");
    print("Country: ${_countryController.text}");
    print("Email: ${_emailController.text}");
    print("Birth Date: ${_birthDateController.text}");
    print("Password: ${_passwordController.text}");
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VerificationScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color yourPrimaryColor = primaryTwo;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Signup'),
      ),
      body: Column(
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
                  selectedCountryCode: _selectedCountryCode,
                  onPhoneChanged: (code) => setState(() {
                    _selectedCountryCode = code;
                  }),
                  selectCountry: _selectCountry,
                ),
                EmailBirthSlide(
                  emailController: _emailController,
                  birthDateController: _birthDateController,
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
              onPressed: _previousPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Previous'),
            ),
          ElevatedButton(
            onPressed: _isCurrentSlideValid() ? _nextPage : null,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  _isCurrentSlideValid() ? primaryColor : Colors.grey,
              foregroundColor: Colors.white,
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
    _birthDateController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _pageController.dispose();
    super.dispose();
  }
}
