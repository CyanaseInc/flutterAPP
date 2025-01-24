import 'package:flutter/material.dart';
import 'package:cyanase/theme/theme.dart';

class RecordingOverlay extends StatelessWidget {
  final Duration recordingDuration;
  final VoidCallback onStopRecording;
  final VoidCallback onDeleteRecording;

  const RecordingOverlay({
    Key? key,
    required this.recordingDuration,
    required this.onStopRecording,
    required this.onDeleteRecording,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            color: Colors.black54,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.mic, size: 48, color: white),
                  SizedBox(height: 16),
                  Text(
                    _formatDuration(recordingDuration),
                    style: TextStyle(fontSize: 24, color: white),
                  ),
                  SizedBox(height: 16),
                  GestureDetector(
                    onHorizontalDragEnd: (details) {
                      if (details.primaryVelocity! < 0) {
                        onDeleteRecording();
                      }
                    },
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.delete, color: white),
                          SizedBox(width: 8),
                          Text(
                            "Slide to cancel",
                            style: TextStyle(color: white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }
}
