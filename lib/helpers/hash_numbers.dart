import 'package:cyanase/helpers/contact_sync_service.dart';
import 'package:http/http.dart' as http;

export 'package:cyanase/helpers/contact_sync_service.dart'
    show ContactSyncProgress, ContactSyncService, ContactSyncCancelled;

/// Logs contact-sync API failures to the console (`flutter run` / terminal).
void debugPrintContactSyncFailure({
  required String source,
  required String url,
  required http.Response response,
  int requestPhoneCount = 0,
  String? requestBodyPreview,
}) {
  final preview = requestBodyPreview == null
      ? ''
      : (requestBodyPreview.length > 4000
          ? '${requestBodyPreview.substring(0, 4000)}… [truncated]'
          : requestBodyPreview);
  print('');
  print('========== CONTACT SYNC API ERROR [$source] ==========');
  print('URL: $url');
  if (requestPhoneCount > 0) {
    print('request phoneNumbers count: $requestPhoneCount');
  }
  if (preview.isNotEmpty) {
    print('request body preview: $preview');
  }
  print('statusCode: ${response.statusCode}');
  print('reasonPhrase: ${response.reasonPhrase}');
  print('response headers: ${response.headers}');
  print('response body (raw): ${response.body}');
  print('======================================================');
  print('');
}

String normalizePhoneNumber(String phoneNumber, String regionCode) =>
    ContactSyncService.normalizePhoneNumber(phoneNumber, regionCode);

Future<List<Map<String, String>>> fetchAndHashContacts() =>
    ContactSyncService.fetchAndHashContacts();

Future<List<Map<String, dynamic>>> getRegisteredContacts(
  List<Map<String, dynamic>> contacts,
) =>
    ContactSyncService.getRegisteredContacts(
      contacts,
      debugSource: 'hash_numbers',
    );
