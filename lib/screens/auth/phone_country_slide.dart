import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import '../../theme/theme.dart';

class PhoneCountrySlide extends StatelessWidget {
  final TextEditingController phoneNumberController;
  final TextEditingController countryController;
  final String selectedCountryCode;
  final Function(String) onPhoneChanged;
  final VoidCallback selectCountry;

  const PhoneCountrySlide({
    Key? key,
    required this.phoneNumberController,
    required this.countryController,
    required this.selectedCountryCode,
    required this.onPhoneChanged,
    required this.selectCountry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Image.asset(
              'assets/logo.png',
              height: 100,
              width: 70,
            ),
          ),
          const SizedBox(height: 16),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Let\'s get you onboarded!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: primaryTwo,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text("Enter your phone number and select your country."),
          ),
          const SizedBox(height: 50),
          IntlPhoneField(
            controller: phoneNumberController,
            initialCountryCode: selectedCountryCode.replaceFirst('+', ''),
            decoration: const InputDecoration(labelText: 'Phone Number'),
            onChanged: (phone) => onPhoneChanged(phone.countryCode),
          ),
          TextField(
            controller: countryController,
            readOnly: true,
            onTap: selectCountry,
            decoration: const InputDecoration(labelText: 'Country'),
          ),
        ],
      ),
    );
  }
}
