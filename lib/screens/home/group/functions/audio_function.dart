import 'dart:async'; // For Timer
import 'dart:io'; // For Directory and File
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class AudioFunctions {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final Record _audioRecorder = Record();
  Timer? _recordingTimer;

  Future<void> playBeepSound() async {
    await _audioPlayer.play(
        AssetSource('audio/beep.mp3')); // Add a beep sound file to your assets
  }

  /// Starts audio recording.
  Future<void> startRecording() async {
    try {
      // Check microphone permission

      // Get the application documents directory
      final directory = await getApplicationDocumentsDirectory();
      final folderPath = '${directory.path}/recordings';
      final folder = Directory(folderPath);

      // Create the recordings directory if it doesn't exist
      if (!await folder.exists()) {
        await folder.create(recursive: true);
      }

      // Define the file path for the recording
      final filePath =
          '$folderPath/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';

      // Start recording
      await _audioRecorder.start(
        path: filePath,
        encoder: AudioEncoder.aacLc,
      );
    } catch (e) {
      print("Error starting recording: $e");
    }
  }

  /// Stops audio recording and returns the file path.
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
        } else {
          print("Audio file does not exist at: $path");
        }
      } else {
        print("Recording path is null");
      }

      return path;
    } catch (e) {
      print("Error stopping recording: $e");
      return null;
    }
  }

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
    await _audioPlayer.play(DeviceFileSource(path));
  }

  /// Pauses the currently playing audio.
  Future<void> pauseAudio() async {
    await _audioPlayer.pause();
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
