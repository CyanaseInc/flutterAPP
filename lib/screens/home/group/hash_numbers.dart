import 'package:contacts_service/contacts_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:libphonenumber/libphonenumber.dart';
import 'package:cyanase/helpers/database_helper.dart';

// Function to normalize phone numbers
Future<String> normalizePhoneNumber(
    String phoneNumber, String regionCode) async {
  try {
    // Prepend country code if missing
    if (!phoneNumber.startsWith('+')) {
      phoneNumber = '+256${phoneNumber.replaceAll(RegExp(r'[^0-9]'), '')}';
    }

    // Print the number being processed

    // Check if the phone number is valid
    bool? isValid = await PhoneNumberUtil.isValidPhoneNumber(
      phoneNumber: phoneNumber,
      isoCode: regionCode,
    );

    if (isValid != true) {
      // Print the invalid number
      throw Exception("Invalid phone number: $phoneNumber");
    }

    // Normalize the phone number
    String? normalizedNumber = await PhoneNumberUtil.normalizePhoneNumber(
      phoneNumber: phoneNumber,
      isoCode: regionCode,
    );

    if (normalizedNumber == null) {
      // Print the failed number
      throw Exception("Failed to normalize phone number: $phoneNumber");
    }

    return normalizedNumber;
  } catch (e) {
    // Print the number and error
    return phoneNumber; // Return the original number if normalization fails
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
  Iterable<Contact> contacts = await ContactsService.getContacts();

  // Normalize contacts
  for (var contact in contacts) {
    if (contact.phones != null && contact.phones!.isNotEmpty) {
      for (var phone in contact.phones!) {
        try {
          String normalizedNumber = await normalizePhoneNumber(
              phone.value!, 'UG'); // 'UG' is the ISO code for Uganda
          contactsWithHashes.add({
            'name': contact.displayName ?? 'Unknown', // Original name
            'phone': phone.value ?? 'No phone number', // Original phone number
            'normalizedPhone': normalizedNumber, // Normalized phone number
          });
        } catch (e) {}
      }
    }
  }

  return contactsWithHashes;
}

// Function to send normalized contacts to the server
Future<List<Map<String, String>>> getRegisteredContacts(
    List<Map<String, String>> contactsWithHashes) async {
  final String apiUrl = "https://fund.cyanase.app/app/get_my_contacts.php";

  // Extract normalized phone numbers for the request
  List<String> phoneNumbers =
      contactsWithHashes.map((contact) => contact['normalizedPhone']!).toList();

  final response = await http.post(
    Uri.parse(apiUrl),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({"phoneNumbers": phoneNumbers}),
  );

  if (response.statusCode == 200) {
    List<dynamic> registeredNumbers =
        jsonDecode(response.body)["registeredContacts"];

    // Filter the original contacts to only include registered ones
    List<Map<String, String>> registeredContacts = contactsWithHashes
        .where(
            (contact) => registeredNumbers.contains(contact['normalizedPhone']))
        .toList();

    // Insert registered contacts into the database
    final dbHelper = DatabaseHelper();
    await dbHelper.insertContacts(registeredContacts);

    return registeredContacts;
  } else {
    print("Request failed with status: ${response.statusCode}");
    print("Response body: ${response.body}");
    print("Response headers: ${response.headers}");
    throw Exception("Failed to fetch registered contacts");
  }
}
