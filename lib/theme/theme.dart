import 'package:flutter/material.dart';

// Define your primary and secondary colors
const Color secondaryColor = Color(0xFFEDBB10);
const Color primaryColor = Color(0xFFEDBB10);
const Color primaryTwo = Color(0xFF252859); // Updated color to #252859
const Color primaryLight = Color(0xFFFFD86A); // Lighter shade
const Color primaryDark = Color(0xFFB57F0A);
const Color primaryTwoLight = Color(0xFF4B5188); // Lighter shade
const Color primaryTwoDark = Color(0xFF1A1E3A);
const Color highliter = Color(0xFFeff6ff);

// Create a ThemeData instance to be used throughout the app
final ThemeData appTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: primaryColor,
    secondary: secondaryColor,
    primary: primaryColor,
  ),
  fontFamily: 'Montserrat', // Set the default font to Montserrat
  useMaterial3: true, // Optional, for Material 3 design

  // Set white background for all screens by default
  scaffoldBackgroundColor: Colors.white,
);
