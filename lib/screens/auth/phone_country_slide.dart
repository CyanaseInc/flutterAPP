import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:sim_card_info/sim_card_info.dart';
import '../../theme/theme.dart';

class PhoneCountrySlide extends StatefulWidget {
  final TextEditingController phoneNumberController;
  final TextEditingController countryController;
  final TextEditingController emailController; // Added email controller
  final Function(String) onPhoneChanged;
  final VoidCallback selectCountry;

  const PhoneCountrySlide({
    Key? key,
    required this.phoneNumberController,
    required this.countryController,
    required this.emailController, // Added email controller
    required this.onPhoneChanged,
    required this.selectCountry,
  }) : super(key: key);

  @override
  _PhoneCountrySlideState createState() => _PhoneCountrySlideState();
}

class _PhoneCountrySlideState extends State<PhoneCountrySlide> {
  String _selectedCountryCode = '+1'; // Default to US
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _detectSimCountry();
  }

  Future<void> _detectSimCountry() async {
    try {
      final simCardInfo = await SimCardInfo().getSimInfo();
      if (simCardInfo != null && simCardInfo.isNotEmpty) {
        final sim = simCardInfo.first;
        setState(() {
          _selectedCountryCode = "+${sim.countryPhonePrefix}";
          widget.countryController.text = sim.countryIso.toUpperCase();
          _isLoading = false;
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
      widget.countryController.text = 'Uganda';
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Center(
                child: Image.asset(
                  'assets/images/logo.png',
                  height: 100,
                  width: 70,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Let\'s get you onboarded!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: primaryTwo,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                "Enter your phone number, email, and select your country.",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 50),
              // Email field
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: TextField(
                  controller: widget.emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: TextStyle(color: primaryTwo),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: primaryTwo),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: primaryTwo),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Phone number field with auto-detected country code
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: _isLoading
                    ? const CircularProgressIndicator() // Show loading indicator
                    : IntlPhoneField(
                        controller: widget.phoneNumberController,
                        initialCountryCode:
                            _selectedCountryCode.replaceFirst('+', ''),
                        decoration: InputDecoration(
                          labelText: 'Phone Number',
                          labelStyle: TextStyle(color: primaryTwo),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: primaryTwo),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: primaryTwo),
                          ),
                        ),
                        onChanged: (phone) =>
                            widget.onPhoneChanged(phone.countryCode),
                      ),
              ),
              const SizedBox(height: 16),
              // Country field
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: TextField(
                  controller: widget.countryController,
                  readOnly: true,
                  onTap: widget.selectCountry,
                  decoration: InputDecoration(
                    labelText: 'Country',
                    labelStyle: TextStyle(color: primaryTwo),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: primaryTwo),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: primaryTwo),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
