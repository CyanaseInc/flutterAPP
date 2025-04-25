// ignore_for_file: avoid_print

import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:crypto/crypto.dart';

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
      print("Invalid country code for Uganda: $phoneNumber");
      throw Exception("Invalid country code for Uganda: $phoneNumber");
    }

    // Check length (Ugandan numbers: +256 followed by 9 digits, total 12)
    if (phoneNumber.length != 12) {
      print("Invalid phone number length: $phoneNumber");
      throw Exception("Invalid phone number length: $phoneNumber");
    }

    // Ensure the number contains only digits after the country code
    final digits = phoneNumber.substring(4); // Skip +256
    if (!RegExp(r'^\d+$').hasMatch(digits)) {
      print("Invalid phone number format: $phoneNumber");
      throw Exception("Invalid phone number format: $phoneNumber");
    }

    return phoneNumber;
  } catch (e) {
    print("Error normalizing phone number: $phoneNumber, Error: $e");
    return phoneNumber; // Return original if normalization fails
  }
}

// Function to hash phone numbers
String hashPhoneNumber(String phoneNumber) {
  String cleanedNumber = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
  var bytes = utf8.encode(cleanedNumber);
  var digest = sha256.convert(bytes);
  return digest.toString();
}

// Function to fetch and hash contacts
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

  // Normalize and hash contacts
  for (var contact in contacts) {
    if (contact.phones.isNotEmpty) {
      for (var phone in contact.phones) {
        print("Processing phone number: ${phone.number}");
        try {
          String normalizedNumber = normalizePhoneNumber(
            phone.number,
            'UG', // 'UG' is the ISO code for Uganda
          );
          String hashedNumber = hashPhoneNumber(normalizedNumber);
          contactsWithHashes.add({
            'name': contact.displayName ?? 'Unknown', // Original name
            'phone': phone.number, // Original phone number
            'hashedPhone': hashedNumber, // Hashed phone number
          });
        } catch (e) {
          print("Error processing ${contact.displayName}: $e");
        }
      }
    }
  }

  return contactsWithHashes;
}

// Function to send hashed contacts to the server
Future<List<Map<String, String>>> getRegisteredContacts(
    List<Map<String, String>> contactsWithHashes) async {
  final String apiUrl = "https://fund.cyanase.app/app/get_my_contacts.php";

  // Extract hashed contacts for the request
  List<String> hashedContacts =
      contactsWithHashes.map((contact) => contact['hashedPhone']!).toList();

  final response = await http.post(
    Uri.parse(apiUrl),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({"hashedContacts": hashedContacts}),
  );

  if (response.statusCode == 200) {
    List<dynamic> registeredHashes =
        jsonDecode(response.body)["registeredContacts"];
    List<dynamic> sentHash = jsonDecode(response.body)["sentContacts"];
    // Filter the original contacts to only include registered ones
    List<Map<String, String>> registeredContacts = contactsWithHashes
        .where((contact) => registeredHashes.contains(contact['hashedPhone']))
        .toList();

    print("Registered Contacts: $registeredContacts Sent Contacts: $sentHash");
    return registeredContacts;
  } else {
    throw Exception("Failed to fetch registered contacts");
  }
}
