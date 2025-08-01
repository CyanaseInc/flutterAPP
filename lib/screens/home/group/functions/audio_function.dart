import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class AudioFunctions {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterSoundRecorder _audioRecorder = FlutterSoundRecorder();
  bool _isRecorderInitialized = false;
  
  // Proper stream controllers for event handling
  final StreamController<Duration> _positionController = StreamController.broadcast();
  final StreamController<Duration> _durationController = StreamController.broadcast();
  final StreamController<void> _completeController = StreamController.broadcast();

  AudioFunctions() {
    _audioPlayer.onPositionChanged.listen((position) {
      _positionController.add(position);
    });
    
    _audioPlayer.onDurationChanged.listen((duration) {
      _durationController.add(duration);
    });
    
    _audioPlayer.onPlayerComplete.listen((_) {
      _completeController.add(null);
    });
  }

  // Maintain the same public interface
  void onPositionChanged(Function(Duration) callback) {
    _positionController.stream.listen(callback);
  }

  void onDurationChanged(Function(Duration) callback) {
    _durationController.stream.listen(callback);
  }

  void onPlayerComplete(Function() callback) {
    _completeController.stream.listen((_) => callback());
  }

  Future<void> initializeRecorder() async {
    if (!_isRecorderInitialized) {
      await _audioRecorder.openRecorder();
      _isRecorderInitialized = true;
    }
  }

  Future<void> playBeepSound() async {
    try {
      await _audioPlayer.play(AssetSource('audio/beep.mp3'));
    } catch (e) {
      
    }
  }

  Future<String?> startRecording() async {
    try {
      await initializeRecorder();
      
      if (!await _checkPermissions()) {
        
        return null;
      }

      final filePath = await _getRecordingPath();
      await _audioRecorder.startRecorder(
        toFile: filePath,
        codec: Codec.aacADTS,
      );

      
      return filePath;
    } catch (e) {
      
      return null;
    }
  }

  Future<String?> stopRecording() async {
    try {
      if (!_isRecorderInitialized) return null;
      return await _audioRecorder.stopRecorder();
    } catch (e) {
      
      return null;
    }
  }

  Future<void> playAudio(String path) async {
    try {
      await _audioPlayer.play(DeviceFileSource(path));
    } catch (e) {
      
    }
  }

  Future<void> pauseAudio() async {
    try {
      await _audioPlayer.pause();
    } catch (e) {
      
    }
  }

  Future<bool> hasPermission() async {
    return await _checkPermissions();
  }

  Future<void> dispose() async {
    await _audioPlayer.dispose();
    if (_isRecorderInitialized) {
      await _audioRecorder.closeRecorder();
    }
    _positionController.close();
    _durationController.close();
    _completeController.close();
  }

  // Private helper methods
  Future<String> _getRecordingPath() async {
    final directory = await getApplicationDocumentsDirectory();
    final folderPath = '${directory.path}/recordings';
    await Directory(folderPath).create(recursive: true);
    return '$folderPath/recording_${DateTime.now().millisecondsSinceEpoch}.aac';
  }

  Future<bool> _checkPermissions() async {
    final status = await Permission.microphone.status;
    if (!status.isGranted) {
      final result = await Permission.microphone.request();
      return result.isGranted;
    }
    return true;
  }
}