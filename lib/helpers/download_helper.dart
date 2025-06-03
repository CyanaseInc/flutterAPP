import 'dart:io';
import 'package:cyanase/helpers/database_helper.dart';
import 'package:cyanase/helpers/endpoints.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audioplayers/audioplayers.dart';

class MediaDownloader {
  static Future<bool> requestStoragePermission() async {
    final status = await Permission.storage.request();
    return status.isGranted;
  }
static final DatabaseHelper _dbHelper = DatabaseHelper();
  static Future<Map<String, dynamic>?> downloadMedia({
    required String url,
    required String type,
    required int messageId,
  }) async {
    try {
      if (!await requestStoragePermission()) {
        print('🔴 [MediaDownloader] Storage permission denied');
        return null;
      }
 final fileUrl =  "${ApiEndpoints.server}$url";

      final response = await http.get(Uri.parse(fileUrl));
      if (response.statusCode != 200) {
        print('🔴 [MediaDownloader] Failed to download: ${response.statusCode}');
        return null;
      }

      final directory = await getExternalStorageDirectory();
      final folder = type == 'image' ? 'Pictures/Cyanase' : 'Cyanase/Audio';
      final fullPath = Directory('${directory!.path}/$folder');
      await fullPath.create(recursive: true);

      final fileName = url.split('/').last;
      final filePath = '${fullPath.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      // Get metadata
      int? fileSize = response.bodyBytes.length;
      int? duration;
      if (type == 'audio') {
        final player = AudioPlayer();
        await player.setSource(DeviceFileSource(filePath));
        duration = (await player.getDuration())?.inSeconds;
        await player.dispose();
      }

      print('🔵 [MediaDownloader] Saved $type to $filePath, size: $fileSize bytes');
final db = await _dbHelper.database;
      // update database with file path, size, and duration
       await db.update(
        'media',
        {'file_path': filePath, 'file_size': fileSize, 'duration': duration},
        where: 'message_id = ?',  
        whereArgs: [messageId],
      );
      return {
        'file_path': filePath,
        'file_size': fileSize,
        'duration': duration,
      };
    } catch (e) {
      print('🔴 [MediaDownloader] Error downloading media: $e');
      return null;
    }
  }
}