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
              const Text(
                'One more step to go!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: primaryTwo,
                ),
                textAlign: TextAlign.center,
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
                    child: TextField(
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
                    child: TextField(
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
                    child: TextField(
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
