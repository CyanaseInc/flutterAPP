import 'package:flutter/material.dart';
import 'package:cyanase/theme/theme.dart';
import 'package:cyanase/helpers/date_helper.dart'; // Import the date formatter

class MessageChat extends StatelessWidget {
  final bool isMe;
  final String? message;
  final String time; // Raw timestamp (e.g., "2023-10-15T10:30:00Z")
  final bool isSameSender;
  final String? replyTo;
  final bool isAudio;
  final bool isPlaying;
  final Duration audioDuration;
  final Duration audioPosition;
  final void Function(String)? onPlayAudio;
  const MessageChat({
    Key? key,
    required this.isMe,
    this.message,
    required this.time,
    required this.isSameSender,
    this.replyTo,
    this.onPlayAudio,
    required this.isAudio,
    this.isPlaying = false,
    this.audioDuration = Duration.zero,
    this.audioPosition = Duration.zero,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final formattedTime = formatTimestamp(time); // Format the timestamp

    return Padding(
      padding: EdgeInsets.only(
        left: isMe ? 64.0 : 8.0,
        right: isMe ? 8.0 : 64.0,
        top: isSameSender ? 2.0 : 8.0,
      ),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
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
                        color: isMe ? primaryLight : Colors.grey[400],
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
                              color: isMe ? Colors.teal[800] : Colors.black,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              replyTo!,
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

                  // Handle audio messages
                  if (isAudio)
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            isPlaying ? Icons.pause : Icons.play_arrow,
                            color: isMe ? Colors.white : Colors.black87,
                          ),
                          onPressed: () {
                            // Handle audio playback
                          },
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
                                width: double.infinity,
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
                      message ?? "",
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
                        formattedTime, // Use the formatted timestamp
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
