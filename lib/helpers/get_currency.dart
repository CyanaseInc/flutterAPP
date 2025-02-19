// currency_helper.dart

import './country_helper.dart'; // Import the file containing the list of countries

class CurrencyHelper {
  /// Returns the currency code for a given country code (e.g., "UG").
  /// Throws an exception if the country code is not found.

  static String getCurrencyCode(String countryCode) {
    // Find the currency code for the user's country
    for (var country in mycountries) {
      // Debugging output
      if (country.twoCode == countryCode.toUpperCase()) {
        return country.currency; // Return the currency code
      }
    }

    // If no matching country is found, throw an exception
    throw Exception('Currency code not found for country: $countryCode');
  }
}
