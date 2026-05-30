import 'dart:async';
import 'dart:convert';

import 'package:cyanase/helpers/database_helper.dart';
import 'package:cyanase/helpers/endpoints.dart';
import 'package:cyanase/helpers/hash_numbers.dart' show debugPrintContactSyncFailure;
import 'package:flutter/foundation.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

/// Progress updates for contact sync UI.
class ContactSyncProgress {
  /// `null` = indeterminate (e.g. waiting on OS contact read).
  final double? fraction;
  final String statusMessage;
  final int? processed;
  final int? total;

  const ContactSyncProgress({
    this.fraction,
    required this.statusMessage,
    this.processed,
    this.total,
  });
}

enum ContactsPermissionOutcome {
  granted,
  denied,
  permanentlyDenied,
  restricted,
}

class ContactSyncCancelled implements Exception {
  const ContactSyncCancelled();
  @override
  String toString() => 'Contact sync cancelled';
}

/// Shared contact read + server match + local DB insert.
class ContactSyncService {
  ContactSyncService._();

  static const Duration getContactsTimeout = Duration(seconds: 90);
  static const Duration httpTimeout = Duration(seconds: 30);
  static const int apiBatchSize = 500;

  static bool _cancelled = false;

  static void resetCancellation() => _cancelled = false;

  static void cancel() => _cancelled = true;

  static void _throwIfCancelled() {
    if (_cancelled) throw const ContactSyncCancelled();
  }

  /// Check / request contacts permission (call before blocking UI).
  static Future<ContactsPermissionOutcome> ensureContactsPermission({
    bool requestIfNeeded = true,
  }) async {
    var status = await Permission.contacts.status;
    if (status.isGranted) {
      return ContactsPermissionOutcome.granted;
    }
    if (status.isPermanentlyDenied) {
      return ContactsPermissionOutcome.permanentlyDenied;
    }
    if (status.isRestricted) {
      return ContactsPermissionOutcome.restricted;
    }
    if (!requestIfNeeded) {
      return ContactsPermissionOutcome.denied;
    }
    status = await Permission.contacts.request();
    if (status.isGranted) {
      return ContactsPermissionOutcome.granted;
    }
    if (status.isPermanentlyDenied) {
      return ContactsPermissionOutcome.permanentlyDenied;
    }
    if (status.isRestricted) {
      return ContactsPermissionOutcome.restricted;
    }
    return ContactsPermissionOutcome.denied;
  }

  static String normalizePhoneNumber(String phoneNumber, String regionCode) {
    try {
      phoneNumber = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
      if (!phoneNumber.startsWith('+')) {
        phoneNumber = '+256${phoneNumber.replaceFirst(RegExp(r'^0'), '')}';
      }
      if (!phoneNumber.startsWith('+256')) {
        throw Exception('Invalid country code for Uganda: $phoneNumber');
      }
      if (phoneNumber.length != 12) {
        throw Exception('Invalid phone number length: $phoneNumber');
      }
      final digits = phoneNumber.substring(4);
      if (!RegExp(r'^\d+$').hasMatch(digits)) {
        throw Exception('Invalid phone number format: $phoneNumber');
      }
      return phoneNumber;
    } catch (_) {
      return phoneNumber;
    }
  }

  /// Read device contacts, normalize in a background isolate.
  static Future<List<Map<String, String>>> fetchAndHashContacts({
    void Function(ContactSyncProgress)? onProgress,
    bool skipPermissionRequest = false,
  }) async {
    _throwIfCancelled();

    if (!skipPermissionRequest) {
      final perm = await ensureContactsPermission();
      if (perm != ContactsPermissionOutcome.granted) {
        switch (perm) {
          case ContactsPermissionOutcome.permanentlyDenied:
            throw Exception(
              'Contacts permission denied. Enable it in Settings to find friends.',
            );
          case ContactsPermissionOutcome.restricted:
            throw Exception('Contacts access is restricted on this device.');
          default:
            throw Exception('Permission to access contacts denied');
        }
      }
    }

    onProgress?.call(
      const ContactSyncProgress(
        fraction: null,
        statusMessage: 'Reading contacts from your phone…',
      ),
    );

    final rawContacts = await FlutterContacts.getContacts(
      withProperties: false,
      withPhoto: false,
    ).timeout(
      getContactsTimeout,
      onTimeout: () => throw TimeoutException(
        'Reading contacts took too long. Try again or skip for now.',
        getContactsTimeout,
      ),
    );

    _throwIfCancelled();

    final serializable = <Map<String, String>>[];
    for (final contact in rawContacts) {
      final name = contact.displayName;
      for (final phone in contact.phones) {
        final number = phone.number.trim();
        if (number.isEmpty) continue;
        serializable.add({
          'name': name.isNotEmpty ? name : 'Unknown',
          'phone': number,
        });
      }
    }

    if (serializable.isEmpty) {
      onProgress?.call(
        const ContactSyncProgress(
          fraction: 1.0,
          statusMessage: 'No phone numbers found in contacts',
          processed: 0,
          total: 0,
        ),
      );
      return [];
    }

    onProgress?.call(
      ContactSyncProgress(
        fraction: 0.15,
        statusMessage: 'Processing ${serializable.length} numbers…',
        processed: 0,
        total: serializable.length,
      ),
    );

    final normalized = await compute(_normalizeContactsIsolate, serializable);

    _throwIfCancelled();

    onProgress?.call(
      ContactSyncProgress(
        fraction: 0.45,
        statusMessage: 'Prepared ${normalized.length} numbers',
        processed: normalized.length,
        total: normalized.length,
      ),
    );

    return normalized;
  }

  static List<Map<String, String>> _normalizeContactsIsolate(
    List<Map<String, String>> raw,
  ) {
    final out = <Map<String, String>>[];
    for (final entry in raw) {
      final phone = entry['phone'] ?? '';
      if (phone.isEmpty) continue;
      out.add({
        'name': entry['name'] ?? 'Unknown',
        'phone': phone,
        'normalizedPhone': normalizePhoneNumber(phone, 'UG'),
      });
    }
    return out;
  }

  /// Match phone numbers with Cyanase users (batched) and save to SQLite.
  static Future<List<Map<String, dynamic>>> getRegisteredContacts(
    List<Map<String, dynamic>> contacts, {
    void Function(ContactSyncProgress)? onProgress,
    String debugSource = 'contact_sync_service',
  }) async {
    if (contacts.isEmpty) {
      return [];
    }

    final apiUrl = ApiEndpoints.fundAppGetMyContacts;
    final phoneNumbers = contacts
        .map((c) => (c['phone'] as String?)?.trim() ?? '')
        .where((p) => p.isNotEmpty)
        .toList();

    if (phoneNumbers.isEmpty) {
      return [];
    }

    final allRegistered = <dynamic>[];
    final totalBatches = (phoneNumbers.length / apiBatchSize).ceil();

    for (var i = 0; i < phoneNumbers.length; i += apiBatchSize) {
      _throwIfCancelled();

      final batchIndex = (i ~/ apiBatchSize) + 1;
      final batch = phoneNumbers.sublist(
        i,
        i + apiBatchSize > phoneNumbers.length
            ? phoneNumbers.length
            : i + apiBatchSize,
      );

      onProgress?.call(
        ContactSyncProgress(
          fraction: 0.5 + (0.45 * batchIndex / totalBatches),
          statusMessage:
              'Checking numbers with Cyanase ($batchIndex/$totalBatches)…',
          processed: i + batch.length,
          total: phoneNumbers.length,
        ),
      );

      final requestBody = jsonEncode({'phoneNumbers': batch});
      final response = await http
          .post(
            Uri.parse(apiUrl),
            headers: {'Content-Type': 'application/json'},
            body: requestBody,
          )
          .timeout(httpTimeout);

      if (response.statusCode != 200) {
        debugPrintContactSyncFailure(
          source: '$debugSource getRegisteredContacts',
          url: apiUrl,
          response: response,
          requestPhoneCount: batch.length,
          requestBodyPreview: requestBody,
        );
        throw Exception(
          'Failed to fetch registered contacts: ${response.statusCode}',
        );
      }

      final decoded = jsonDecode(response.body);
      final batchRegistered = decoded['registeredContacts'];
      if (batchRegistered is List) {
        allRegistered.addAll(batchRegistered);
      }
    }

    _throwIfCancelled();

    onProgress?.call(
      const ContactSyncProgress(
        fraction: 0.95,
        statusMessage: 'Saving friends on this device…',
      ),
    );

    final registeredContacts = contacts
        .where((contact) => allRegistered
            .any((registered) => registered['phoneno'] == contact['phone']))
        .map((contact) {
      final registered = allRegistered.firstWhere(
        (r) => r['phoneno'] == contact['phone'],
      );
      return {
        'id': int.parse(registered['id'].toString()),
        'user_id': registered['id'].toString(),
        'name': contact['name'],
        'phone': contact['phone'],
        'profilePic': contact['profilePic'] ?? '',
        'is_registered': true,
      };
    }).toList();

    final dbHelper = DatabaseHelper();
    await dbHelper.insertContacts(registeredContacts);

    onProgress?.call(
      ContactSyncProgress(
        fraction: 1.0,
        statusMessage: 'Found ${registeredContacts.length} friends on Cyanase',
        processed: registeredContacts.length,
        total: registeredContacts.length,
      ),
    );

    return registeredContacts;
  }

  /// Full pipeline: device contacts → API → local DB.
  static Future<List<Map<String, dynamic>>> syncContacts({
    void Function(ContactSyncProgress)? onProgress,
    bool skipPermissionRequest = false,
  }) async {
    final hashed = await fetchAndHashContacts(
      onProgress: onProgress,
      skipPermissionRequest: skipPermissionRequest,
    );
    _throwIfCancelled();
    return getRegisteredContacts(
      hashed,
      onProgress: onProgress,
    );
  }
}
