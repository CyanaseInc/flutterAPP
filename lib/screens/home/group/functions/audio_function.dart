import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class AudioFunctions {
  final Record _audioRecorder = Record();

  Future<void> startRecording() async {
    if (!await _audioRecorder.hasPermission()) {
      print("Microphone permission denied");
      return;
    }

    final directory = await getApplicationDocumentsDirectory();
    final folderPath = '${directory.path}/recordings';
    final folder = Directory(folderPath);
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }

    final filePath =
        '$folderPath/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _audioRecorder.start(
      path: filePath,
      encoder: AudioEncoder.aacLc,
    );
  }

  Future<String?> stopRecording() async {
    return await _audioRecorder.stop();
  }
}
