import 'package:cyanase/helpers/loader.dart';
import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/countries.dart';
import 'package:sim_card_info/sim_card_info.dart';
import '../../theme/theme.dart';

class PhoneCountrySlide extends StatefulWidget {
  final TextEditingController phoneNumberController;
  final TextEditingController countryController;
  final TextEditingController emailController;
  final Function(String) onPhoneChanged;
  final VoidCallback selectCountry;
  final bool isLoading;

  const PhoneCountrySlide({
    Key? key,
    required this.phoneNumberController,
    required this.countryController,
    required this.emailController,
    required this.onPhoneChanged,
    required this.selectCountry,
    this.isLoading = false,
  }) : super(key: key);

  @override
  _PhoneCountrySlideState createState() => _PhoneCountrySlideState();
}

class _PhoneCountrySlideState extends State<PhoneCountrySlide> {
  String _selectedCountryCode = '+256'; // Default to Uganda
  String _selectedCountryISO = 'UG'; // Default to Uganda ISO
  bool _isLoading = true;
  final double _inputFontSize = 16;

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
        final countryIso = sim.countryIso?.toUpperCase() ?? 'UG';
        _updateCountryByISO(countryIso);
      }
    } catch (e) {
      
      _setDefaultCountry();
    }
  }

  void _setDefaultCountry() {
    _updateCountryByISO('UG');
  }

  void _updateCountryByISO(String countryIso) {
    final country = countries.firstWhere(
      (c) => c.code == countryIso,
      orElse: () => countries.firstWhere((c) => c.code == 'UG'),
    );

    setState(() {
      _selectedCountryCode = country.dialCode ?? '+256';
      _selectedCountryISO = country.code ?? 'UG';
      widget.countryController.text = country.code ?? 'Uganda';
      _isLoading = false;
    });
  }

  void _onCountryChanged(Country country) {
    setState(() {
      _selectedCountryCode = country.dialCode ?? '+256';
      _selectedCountryISO = country.code ?? 'UG';
      widget.countryController.text = country.name ?? 'Uganda';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
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
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Phone number field with auto-detected country code
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.8,
                    child: _isLoading
                        ? const Center(child: Loader())
                        : IntlPhoneField(
                            controller: widget.phoneNumberController,
                            initialCountryCode: _selectedCountryISO,
                            style: TextStyle(fontSize: _inputFontSize),
                            dropdownTextStyle: TextStyle(fontSize: _inputFontSize),
                            decoration: InputDecoration(
                              labelText: 'Phone Number',
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(),
                              ),
                            ),
                            onChanged: (phone) {
                              setState(() {
                                _selectedCountryCode = phone.countryCode;
                              });
                              widget.onPhoneChanged(phone.completeNumber);
                            },
                            onCountryChanged: (country) {
                              _onCountryChanged(country);
                            },
                          ),
                  ),
                  const SizedBox(height: 16),

                  // Country field (read-only, synced with phone code)
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.8,
                    child: TextField(
                      controller: widget.countryController,
                      readOnly: true,
                      onTap: () => widget.selectCountry(),
                      style: TextStyle(fontSize: _inputFontSize),
                      decoration: InputDecoration(
                        labelText: 'Country',
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (widget.isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
