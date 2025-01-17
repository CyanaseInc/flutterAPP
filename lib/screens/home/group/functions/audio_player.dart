import 'package:audioplayers/audioplayers.dart';

class AudioPlayerFunctions {
  final AudioPlayer _audioPlayer = AudioPlayer();

  Future<void> playAudio(String path) async {
    await _audioPlayer.play(DeviceFileSource(path));
  }

  Future<void> pauseAudio() async {
    await _audioPlayer.pause();
  }

  void onPositionChanged(Function(Duration) callback) {
    _audioPlayer.onPositionChanged.listen(callback);
  }

  void onDurationChanged(Function(Duration) callback) {
    _audioPlayer.onDurationChanged.listen(callback);
  }

  void onPlayerComplete(Function() callback) {
    _audioPlayer.onPlayerComplete.listen((event) => callback());
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}
