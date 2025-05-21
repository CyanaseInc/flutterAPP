import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cyanase/helpers/database_helper.dart';

// Function to normalize Ugandan phone numbers
String normalizePhoneNumber(String phoneNumber, String regionCode) {
  try {
    // Clean the phone number (remove non-digits except +)
    phoneNumber = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');

    // Prepend country code if missing
    if (!phoneNumber.startsWith('+')) {
      phoneNumber = '+256${phoneNumber.replaceFirst(RegExp(r'^0'), '')}';
    }

    // Validate phone number
    if (!phoneNumber.startsWith('+256')) {
      throw Exception("Invalid country code for Uganda: $phoneNumber");
    }

    // Check length (Ugandan numbers: +256 followed by 9 digits, total 12)
    if (phoneNumber.length != 12) {
      throw Exception("Invalid phone number length: $phoneNumber");
    }

    // Ensure the number contains only digits after the country code
    final digits = phoneNumber.substring(4); // Skip +256
    if (!RegExp(r'^\d+$').hasMatch(digits)) {
      throw Exception("Invalid phone number format: $phoneNumber");
    }

    return phoneNumber;
  } catch (e) {
    
    return phoneNumber; // Return original if normalization fails
  }
}

// Function to fetch and collect normalized contacts
Future<List<Map<String, String>>> fetchAndHashContacts() async {
  List<Map<String, String>> contactsWithHashes = [];

  // Request contacts permission
  PermissionStatus permissionStatus = await Permission.contacts.request();
  if (permissionStatus != PermissionStatus.granted) {
    throw Exception("Permission to access contacts denied");
  }

  // Fetch contacts
  final contacts = await FlutterContacts.getContacts(
    withProperties: true,
    withPhoto: false,
  );

  // Normalize contacts
  for (var contact in contacts) {
    if (contact.phones.isNotEmpty) {
      for (var phone in contact.phones) {
        try {
          String normalizedNumber = normalizePhoneNumber(
            phone.number,
            'UG', // 'UG' is the ISO code for Uganda
          );
          contactsWithHashes.add({
            'name': contact.displayName ?? 'Unknown', // Original name
            'phone': phone.number, // Original phone number
            'normalizedPhone': normalizedNumber, // Normalized phone number
          });
        } catch (e) {
          print('Error processing ${contact.displayName}: $e');
        }
      }
    }
  }

  return contactsWithHashes;
}

// Function to send normalized contacts to the server
Future<List<Map<String, dynamic>>> getRegisteredContacts(
    List<Map<String, dynamic>> contacts) async {
  final String apiUrl = "https://fund.cyanase.app/app/get_my_contacts.php";

  // Extract normalized phone numbers for the request
  List<String> phoneNumbers =
      contacts.map((contact) => contact['phone'] as String).toList();

  final response = await http.post(
    Uri.parse(apiUrl),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({"phoneNumbers": phoneNumbers}),
  );

  if (response.statusCode == 200) {
    // Parse the response to get registered contacts with their IDs
    List<dynamic> registeredNumbersWithIds =
        jsonDecode(response.body)["registeredContacts"];

    // Filter the original contacts to only include registered ones and add the ID
    List<Map<String, dynamic>> registeredContacts = contacts
        .where((contact) => registeredNumbersWithIds
            .any((registered) => registered['phoneno'] == contact['phone']))
        .map((contact) {
      // Find the corresponding ID from the server response
      var registered = registeredNumbersWithIds.firstWhere(
          (registered) => registered['phoneno'] == contact['phone']);
      return {
        'id': int.parse(registered['id'].toString()), // Ensure the ID is an int
        'user_id': registered['id'].toString(), // Use the ID as the user_id
        'name': contact['name'],
        'phone': contact['phone'],
        'profilePic': contact['profilePic'] ?? '',
        'is_registered': true, // Mark as registered
      };
    }).toList();

    // Insert registered contacts into the database
    final dbHelper = DatabaseHelper();
    await dbHelper.insertContacts(registeredContacts);

    return registeredContacts;
  } else {
    throw Exception(
        "Failed to fetch registered contacts: ${response.statusCode}");
  }
}
