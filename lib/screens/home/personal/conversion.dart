import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

class Conversion {
  String from;
  double input;
  String to;

  Map<String, dynamic> info = {}; // Changed to Map to correctly store the data
  String newFrom = "usd";
  double output = 0;
  String result = "";

  // Constructor
  Conversion(this.from, this.input, this.to);

  // For delay in network - to prevent 404 status code issues
  Future<void> fetchData() async {
    if (from.isEmpty) {
      from = newFrom;
    }
    if (input < 0) {
      input = input * -1;
    }

    try {
      final response = await http.get(
        Uri.parse(
          'https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@latest/v1/currencies/$from.json',
        ),
      );

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        info = Map<String, dynamic>.from(
            data[from]); // Cast to Map for easy key access
      } else {
        info = {"...": null}; // Handle API error gracefully
      }
    } catch (e) {
      info = {"...": null}; // Catch any errors and set to default value
    }
  }

  String convert() {
    // Ensure that the 'to' currency exists in the map
    if (info.isNotEmpty && info.containsKey(to)) {
      var rate = info[to];
      if (rate is num) {
        output = input * rate;
        result = output.toStringAsFixed(2);
      } else {
        result = 'Error: Invalid rate for $to.';
      }
    } else {
      result = 'Error: Conversion data not available.';
    }
    return result;
  }

  Future<String> executeConversion() async {
    await fetchData(); // Fetch data from API
    return convert(); // Perform conversion
  }
}
