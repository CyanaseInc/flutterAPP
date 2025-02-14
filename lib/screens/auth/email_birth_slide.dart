import 'package:flutter/material.dart';
import '../../theme/theme.dart';

class EmailBirthSlide extends StatelessWidget {
  final TextEditingController yearController;
  final TextEditingController monthController;
  final TextEditingController dayController;
  final String? selectedGender; // Added gender field
  final Function(String?) onGenderSelected; // Callback for gender selection

  const EmailBirthSlide({
    Key? key,
    required this.yearController,
    required this.monthController,
    required this.dayController,
    this.selectedGender,
    required this.onGenderSelected,
  }) : super(key: key);

  // Validate the date of birth
  String? _validateDateOfBirth() {
    final year = int.tryParse(yearController.text);
    final month = int.tryParse(monthController.text);
    final day = int.tryParse(dayController.text);

    // Check if all fields are filled
    if (year == null || month == null || day == null) {
      return "Please enter a valid date of birth.";
    }

    // Validate year
    final currentYear = DateTime.now().year;
    if (year < 1900 || year > currentYear) {
      return "Year must be between 1900 and $currentYear.";
    }

    // Validate month
    if (month < 1 || month > 12) {
      return "Month must be between 1 and 12.";
    }

    // Validate day
    final maxDay = _getMaxDayForMonth(year, month);
    if (day < 1 || day > maxDay) {
      return "Day must be between 1 and $maxDay for the selected month and year.";
    }

    return null; // No error
  }

  // Get the maximum number of days for a given month and year
  int _getMaxDayForMonth(int year, int month) {
    if (month == 2) {
      // Check for leap year
      if ((year % 4 == 0 && year % 100 != 0) || (year % 400 == 0)) {
        return 29; // Leap year
      } else {
        return 28; // Non-leap year
      }
    } else if ([4, 6, 9, 11].contains(month)) {
      return 30; // Months with 30 days
    } else {
      return 31; // Months with 31 days
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment:
                CrossAxisAlignment.start, // Align children to the left
            children: [
              Center(
                child: Image.asset(
                  'assets/images/logo.png',
                  height: 100,
                  width: 70,
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'One more step to go!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: primaryTwo,
                  ),
                  textAlign:
                      TextAlign.center, // Ensures the text itself is centered
                ),
              ),

              const SizedBox(height: 16),
              const Text(
                "Enter your date of birth and select your gender.",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 50),
              // Gender selection
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: DropdownButtonFormField<String>(
                  value: selectedGender,
                  decoration: InputDecoration(
                    labelText: 'Gender',
                    labelStyle: TextStyle(color: primaryTwo),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: primaryTwo),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: primaryTwo),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Male', child: Text('Male')),
                    DropdownMenuItem(value: 'Female', child: Text('Female')),
                  ],
                  onChanged: onGenderSelected,
                ),
              ),
              const SizedBox(height: 36),
              // Date of birth fields (Year, Month, Day)
              const Text(
                "Birth date.",
                textAlign: TextAlign.left, // Align text to the left
              ),
              const SizedBox(height: 8), // Added spacing
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.start, // Align fields to the left
                children: [
                  // Year field
                  SizedBox(
                    width: 80,
                    child: TextFormField(
                      controller: yearController,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      decoration: InputDecoration(
                        labelText: 'YYYY',
                        labelStyle: TextStyle(color: primaryTwo),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: primaryTwo),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: primaryTwo),
                        ),
                        errorText: _validateDateOfBirth(),
                      ),
                      onChanged: (value) {
                        if (value.length == 4) {
                          FocusScope.of(context).nextFocus(); // Move to month
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Month field
                  SizedBox(
                    width: 60,
                    child: TextFormField(
                      controller: monthController,
                      keyboardType: TextInputType.number,
                      maxLength: 2,
                      decoration: InputDecoration(
                        labelText: 'MM',
                        labelStyle: TextStyle(color: primaryTwo),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: primaryTwo),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: primaryTwo),
                        ),
                        errorText: _validateDateOfBirth(),
                      ),
                      onChanged: (value) {
                        if (value.length == 2) {
                          FocusScope.of(context).nextFocus(); // Move to day
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Day field
                  SizedBox(
                    width: 60,
                    child: TextFormField(
                      controller: dayController,
                      keyboardType: TextInputType.number,
                      maxLength: 2,
                      decoration: InputDecoration(
                        labelText: 'DD',
                        labelStyle: TextStyle(color: primaryTwo),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: primaryTwo),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: primaryTwo),
                        ),
                        errorText: _validateDateOfBirth(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
