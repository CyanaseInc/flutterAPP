import 'package:flutter/material.dart';
import 'package:cyanase/theme/theme.dart';

class MessageChat extends StatelessWidget {
  final bool isMe;
  final String message; // Expose the message text
  final String time;
  final bool isSameSender;
  final String? replyTo;
  final bool isAudio;
  final Function(String) onPlayAudio; // Accepts a String parameter (audio path)
  final bool isPlaying;
  final Duration audioDuration;
  final Duration audioPosition;

  const MessageChat({
    Key? key,
    required this.isMe,
    required this.message,
    required this.time,
    required this.isSameSender,
    this.replyTo,
    required this.isAudio,
    required this.onPlayAudio,
    required this.isPlaying,
    required this.audioDuration,
    required this.audioPosition,
  }) : super(key: key);

  // Helper function to truncate long text
  String _truncateText(String text, {int maxLength = 30}) {
    if (text.length > maxLength) {
      return text.substring(0, maxLength) + '...';
    }
    return text;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: isMe ? 64.0 : 8.0,
        right: isMe ? 8.0 : 64.0,
        top: isSameSender
            ? 2.0
            : 8.0, // Reduce space between consecutive messages
      ),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width *
                    0.75, // Increase bubble width
              ),
              padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? primaryColor : Colors.grey[300],
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(isMe ? 12 : 0),
                  topRight: Radius.circular(isMe ? 0 : 12),
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Column(
                crossAxisAlignment:
                    isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (replyTo != null)
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(8),
                      margin: EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: isMe
                            ? primaryLight
                            : Colors.grey[400], // Background color for replies
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 4,
                            height: 40,
                            margin: EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: isMe
                                  ? Colors.teal[800]
                                  : Colors.black, // Color for the quote bar
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              _truncateText(replyTo!),
                              style: TextStyle(
                                color: isMe ? Colors.black87 : Colors.black87,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  SizedBox(height: replyTo != null ? 8 : 0),
                  if (isAudio)
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            isPlaying ? Icons.pause : Icons.play_arrow,
                            color: isMe ? Colors.white : Colors.black87,
                          ),
                          onPressed: () =>
                              onPlayAudio(message), // Pass the audio path
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Audio",
                                style: TextStyle(
                                  color: isMe ? Colors.white : Colors.black87,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 4),
                              Container(
                                width: double
                                    .infinity, // Full width for progress bar
                                child: LinearProgressIndicator(
                                  value: audioDuration.inSeconds > 0
                                      ? audioPosition.inSeconds /
                                          audioDuration.inSeconds
                                      : 0,
                                  backgroundColor: isMe
                                      ? Colors.teal[800]
                                      : Colors.grey[500],
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    isMe ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          _formatDuration(audioDuration),
                          style: TextStyle(
                            color: isMe ? Colors.white70 : Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      message,
                      style: TextStyle(
                        color: isMe ? Colors.white : Colors.black87,
                        fontSize: 16,
                      ),
                    ),
                  SizedBox(height: 5),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        time,
                        style: TextStyle(
                          fontSize: 12,
                          color: isMe ? Colors.white70 : Colors.black54,
                        ),
                      ),
                      SizedBox(width: 5),
                      if (isMe)
                        const Icon(
                          Icons.done_all,
                          color: Colors.white70,
                          size: 16,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }
}
