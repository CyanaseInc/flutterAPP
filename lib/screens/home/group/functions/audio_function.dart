import 'dart:async';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class AudioFunctions {
  final Record _audioRecorder = Record();
  Timer? _recordingTimer; // Declare the timer

  Future<bool> _checkMicrophonePermission() async {
    final status = await Permission.microphone.status;
    if (status.isDenied) {
      final result = await Permission.microphone.request();
      return result.isGranted;
    }
    return status.isGranted;
  }

  Future<void> startRecording() async {
    try {
      final hasPermission = await _checkMicrophonePermission();
      if (!hasPermission) {
        print("Microphone permission denied");
        return;
      }

      final directory = await getApplicationDocumentsDirectory();
      final folderPath = '${directory.path}/recordings';
      final folder = Directory(folderPath);

      // Create the directory if it doesn't exist
      if (!await folder.exists()) {
        await folder.create(recursive: true);
        print("Created directory: $folderPath");
      }

      final filePath =
          '$folderPath/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _audioRecorder.start(
        path: filePath,
        encoder: AudioEncoder.aacLc,
      );

      print("Recording started at: $filePath");

      // Start the timer
      _recordingTimer = Timer.periodic(Duration(seconds: 1), (timer) {
        print("Recording duration: ${timer.tick} seconds");
      });
    } catch (e) {
      print("Error starting recording: $e");
    }
  }

  Future<String?> stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      if (path != null) {
        final file = File(path);
        if (await file.exists()) {
          print("Audio file exists at: $path");
          print("File size: ${await file.length()} bytes");
        } else {
          print("Audio file does not exist at: $path");
        }
      } else {
        print("Recording path is null");
      }

      // Stop the timer
      _recordingTimer?.cancel();
      _recordingTimer = null;

      return path;
    } catch (e) {
      print("Error stopping recording: $e");
      return null;
    }
  }
}
