import 'package:audioplayers/audioplayers.dart';

class AudioPlayerFunctions {
  final AudioPlayer _audioPlayer = AudioPlayer();

  /// Plays audio from the given file path.
  Future<void> playAudio(String path) async {
    await _audioPlayer.play(DeviceFileSource(path));
  }

  /// Pauses the currently playing audio.
  Future<void> pauseAudio() async {
    await _audioPlayer.pause();
  }

  /// Listens for changes in the audio duration.
  void onDurationChanged(Function(Duration) callback) {
    _audioPlayer.onDurationChanged.listen(callback);
  }

  /// Listens for changes in the audio playback position.
  void onPositionChanged(Function(Duration) callback) {
    _audioPlayer.onPositionChanged.listen(callback);
  }

  /// Listens for when the audio playback completes.
  void onPlayerComplete(Function() callback) {
    _audioPlayer.onPlayerComplete.listen((event) => callback());
  }

  /// Releases resources used by the audio player.
  void dispose() {
    _audioPlayer.dispose();
  }
}
