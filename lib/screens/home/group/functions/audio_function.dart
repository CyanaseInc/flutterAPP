

import 'dart:async'; // For Timer
import 'dart:io'; // For Directory and File
import 'package:audioplayers/audioplayers.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class AudioFunctions {
final AudioPlayer _audioPlayer = AudioPlayer();
  final Record _audioRecorder = Record(); 

  Future<void> playBeepSound() async {
    await _audioPlayer.play(
        AssetSource('audio/beep.mp3')); // Add a beep sound file to your assets
  }

  /// Ensures the folder exists at the given path.
  Future<void> ensureFolderExists(String folderPath) async {
    final folder = Directory(folderPath);

    // Check if the folder exists
    if (!await folder.exists()) {
      // Create the folder if it doesn't exist
      await folder.create(
          recursive:
              true); // `recursive: true` creates parent directories if needed
   
    } 
  }

  /// Starts audio recording.
  Future<String?> startRecording() async {
    try {
      // Check and request microphone permission
      final status = await Permission.microphone.status;
      if (!status.isGranted) {
        final result = await Permission.microphone.request();
        if (!result.isGranted) {
          print("Microphone permission denied");
          return null;
        }
      }

      // Get the application documents directory
      final directory = await getApplicationDocumentsDirectory();
      final folderPath = '${directory.path}/recordings';

      // Ensure the recordings folder exists
      await ensureFolderExists(folderPath);

      // Define the file path for the recording
      final filePath =
          '$folderPath/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';

      // Start recording
      await _audioRecorder.start(
        path: filePath,
        encoder: AudioEncoder.aacLc,
      );

      print("Recording started at: $filePath");
      return filePath;
    } catch (e) {
      print("Error starting recording: $e");
      return null;
    }
  }

  Future<String?> stopRecording() async {
    try {
      // Stop recording
      final path = await _audioRecorder.stop();

      if (path != null) {
        // Verify the file exists
        final file = File(path);
        if (await file.exists()) {
          print("Audio file exists at: $path");
          print("File size: ${await file.length()} bytes");
          return path;
        } else {
          print("Audio file does not exist at: $path");
        }
      } else {
        print("Recording path is null");
      }

      return null;
    } catch (e) {
      print("Error stopping recording: $e");

      return null;
    }
  }

  /// Stops audio recording and returns the file path.

  /// Checks and requests microphone permission.
  Future<bool> _checkMicrophonePermission() async {
    final status = await Permission.microphone.status;
    if (status.isDenied) {
      final result = await Permission.microphone.request();
      return result.isGranted;
    }
    return status.isGranted;
  }

  /// Starts audio playback from the given file path.
  Future<void> playAudio(String path) async {
    try {
      await _audioPlayer.play(DeviceFileSource(path));
    } catch (e) {
      print("Error playing audio: $e");
    }
  }

  /// Pauses the currently playing audio.
  Future<void> pauseAudio() async {
    try {
      await _audioPlayer.pause();
    } catch (e) {
      print("Error pausing audio: $e");
    }
  }

  /// Listens for changes in the audio playback position.
  void onPositionChanged(Function(Duration) callback) {
    _audioPlayer.onPositionChanged.listen(callback);
  }

  /// Listens for changes in the audio duration.
  void onDurationChanged(Function(Duration) callback) {
    _audioPlayer.onDurationChanged.listen(callback);
  }

  /// Listens for when the audio playback completes.
  void onPlayerComplete(Function() callback) {
    _audioPlayer.onPlayerComplete.listen((event) => callback());
  }

  /// Releases resources used by the audio player and recorder.
  void dispose() {
    _audioPlayer.dispose();
    _audioRecorder.dispose();
  }
}