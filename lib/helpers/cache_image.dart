import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';

class ImageHelper {
  static Future<String?> downloadAndSaveImage(
      String imageUrl, String fileName) async {
    try {
      // Get the local storage directory
      final Directory directory = await getApplicationDocumentsDirectory();
      final String filePath = join(directory.path, fileName);

      // Download the image
      final http.Response response = await http.get(Uri.parse(imageUrl));

      // Save the image to local storage
      final File file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      return filePath; // Return the local file path
    } catch (e) {
      
      return null;
    }
  }
}
