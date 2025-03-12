// ignore_for_file: avoid_print

import 'package:contacts_service/contacts_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:libphonenumber/libphonenumber.dart';

// Function to normalize phone numbers
Future<String> normalizePhoneNumber(
    String phoneNumber, String regionCode) async {
  try {
    // Prepend country code if missing
    if (!phoneNumber.startsWith('+')) {
      phoneNumber = '+256${phoneNumber.replaceAll(RegExp(r'[^0-9]'), '')}';
    }

    // Check if the phone number is valid
    bool? isValid = await PhoneNumberUtil.isValidPhoneNumber(
      phoneNumber: phoneNumber,
      isoCode: regionCode,
    );

    if (isValid != true) {
      print("Invalid phone number: $phoneNumber"); // Print the invalid number
      throw Exception("Invalid phone number: $phoneNumber");
    }

    // Normalize the phone number
    String? normalizedNumber = await PhoneNumberUtil.normalizePhoneNumber(
      phoneNumber: phoneNumber,
      isoCode: regionCode,
    );

    if (normalizedNumber == null) {
      print(
          "Failed to normalize phone number: $phoneNumber"); // Print the failed number
      throw Exception("Failed to normalize phone number: $phoneNumber");
    }

    return normalizedNumber;
  } catch (e) {
    print(
        "Error normalizing phone number: $phoneNumber, Error: $e"); // Print the number and error
    return phoneNumber; // Return the original number if normalization fails
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
  Iterable<Contact> contacts = await ContactsService.getContacts();

  // Normalize and hash contacts
  for (var contact in contacts) {
    if (contact.phones != null && contact.phones!.isNotEmpty) {
      for (var phone in contact.phones!) {
        print(
            "Processing phone number: ${phone.value}"); // Log the phone number
        String normalizedNumber = await normalizePhoneNumber(
            phone.value!, 'UG'); // 'UG' is the ISO code for Uganda
        String hashedNumber = hashPhoneNumber(normalizedNumber);
        contactsWithHashes.add({
          'name': contact.displayName ?? 'Unknown', // Original name
          'phone': phone.value ?? 'No phone number', // Original phone number
          'hashedPhone': hashedNumber, // Hashed phone number
        });
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
    print("Request failed with status: ${response.statusCode}");
    print("Response body: ${response.body}");
    print("Response headers: ${response.headers}");
    throw Exception("Failed to fetch registered contacts");
  }
}
