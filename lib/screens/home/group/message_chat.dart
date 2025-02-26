import 'package:cyanase/helpers/loader.dart';
import 'package:flutter/material.dart';
import 'package:cyanase/theme/theme.dart';
import 'package:cyanase/helpers/date_helper.dart';
import 'dart:io';
import 'full_screen_image_viewer.dart';

class MessageChat extends StatefulWidget {
  final bool isMe;
  final String? message;
  final String time;
  final bool isSameSender;
  final String? replyToId;
  final String? replyTo;
  final String? replyToType;
  final bool isAudio;
  final bool isImage;
  final bool isNotification; // Added for notifications
  final bool isPlaying;
  final Duration audioDuration;
  final Duration audioPosition;
  final void Function(String, String)? onPlayAudio;
  final String messageId;
  final String senderName;
  final String senderAvatar;

  const MessageChat({
    super.key,
    required this.isMe,
    required this.message,
    required this.time,
    required this.isSameSender,
    this.replyToId,
    this.replyTo,
    this.replyToType,
    required this.isAudio,
    required this.isImage,
    required this.isNotification, // Added parameter
    required this.onPlayAudio,
    this.isPlaying = false,
    this.audioDuration = Duration.zero,
    this.audioPosition = Duration.zero,
    required this.messageId,
    required this.senderName,
    required this.senderAvatar,
  });

  @override
  State<MessageChat> createState() => _MessageChatState();
}

class _MessageChatState extends State<MessageChat> {
  late Future<bool> _messageFileExists;
  late Future<bool> _replyFileExists;

  @override
  void initState() {
    super.initState();
    _messageFileExists = widget.isImage && widget.message != null
        ? doesFileExist(widget.message!)
        : Future.value(false);
    _replyFileExists = widget.replyTo != null && widget.replyToType == "image"
        ? doesFileExist(widget.replyTo!)
        : Future.value(false);
  }

  Future<bool> doesFileExist(String filePath) async {
    final file = File(filePath);
    return await file.exists();
  }

  @override
  Widget build(BuildContext context) {
    final formattedTime = formatTimestamp(widget.time);

    // Handle notification messages
    if (widget.isNotification) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 18.0),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            constraints: const BoxConstraints(
              minWidth: 120,
              minHeight: 42,
            ),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.grey[500],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.info,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.message ?? "Notification",
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Regular message UI (sent/received)
    return Padding(
      padding: EdgeInsets.only(
        left: widget.isMe ? 64.0 : 8.0,
        right: widget.isMe ? 8.0 : 64.0,
        top: widget.isSameSender ? 4.0 : 12.0,
        bottom: 4.0,
      ),
      child: Align(
        alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment:
              widget.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!widget.isSameSender)
              Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!widget.isMe)
                      CircleAvatar(
                        radius: 14,
                        backgroundImage: FileImage(File(widget.senderAvatar)),
                        backgroundColor: Colors.grey[300],
                        onBackgroundImageError: (_, __) => Container(),
                      ),
                    if (!widget.isMe) const SizedBox(width: 8),
                    Text(
                      widget.senderName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: widget.isMe ? primaryColor : Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            Semantics(
              label: widget.isMe ? "Sent message" : "Received message",
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width *
                      0.6, // Reduced from 0.75 to make bubbles narrower
                ),
                padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 12), // Reduced padding for compactness
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: widget.isMe
                        ? [primaryColor, primaryColor.withOpacity(0.85)]
                        : [Colors.yellow[100]!, Colors.yellow[200]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(
                        widget.isMe || widget.isSameSender ? 12 : 0),
                    topRight: Radius.circular(widget.isMe ? 0 : 12),
                    bottomLeft: const Radius.circular(12),
                    bottomRight: const Radius.circular(12),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4, // Reduced shadow for subtlety
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: widget.isMe
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    if (widget.replyTo != null && widget.replyToId != null)
                      _buildReplySection(context),
                    if (widget.replyTo != null)
                      const SizedBox(height: 4), // Reduced spacing
                    if (widget.message == null)
                      const Text(
                        "Message unavailable",
                        style: TextStyle(color: Colors.grey),
                      )
                    else if (widget.isAudio)
                      _buildAudioPlayer(context)
                    else if (widget.isImage)
                      _buildImageViewer(context)
                    else
                      Text(
                        widget.message!,
                        style: TextStyle(
                          color: widget.isMe ? white : Colors.black87,
                          fontSize:
                              15, // Slightly reduced font size for compactness
                          fontFamily: 'Roboto',
                        ),
                      ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: widget.isMe
                          ? MainAxisAlignment.end
                          : MainAxisAlignment.start, // Align time appropriately
                      children: [
                        Text(
                          formattedTime,
                          style: TextStyle(
                            fontSize: 10, // Smaller time font for compactness
                            color:
                                widget.isMe ? Colors.white70 : Colors.grey[600],
                          ),
                        ),
                        if (widget.isMe)
                          const SizedBox(width: 4), // Reduced spacing
                        if (widget.isMe)
                          Icon(
                            Icons.done_all,
                            color: Colors.white70,
                            size: 12, // Reduced icon size
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReplySection(BuildContext context) {
    return FutureBuilder<bool>(
      future: _replyFileExists,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 24,
            child: Center(child: Loader()),
          );
        }
        final fileExists = snapshot.data ?? false;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          margin: const EdgeInsets.only(bottom: 5),
          decoration: BoxDecoration(
            color: widget.isMe ? Colors.white12 : Colors.grey[200],
            borderRadius: BorderRadius.circular(5),
            border: Border(
              left: BorderSide(
                color: widget.isMe ? primaryTwo : Colors.grey[400]!,
                width: 3,
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.replyToType == "image" && fileExists)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.file(
                      File(widget.replyTo!),
                      width: 24,
                      height: 24,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(Icons.image_not_supported,
                            size: 24,
                            color: widget.isMe
                                ? Colors.white70
                                : Colors.grey[600]);
                      },
                    ),
                  ),
                ),
              Expanded(
                child: Text(
                  widget.replyToType == "image" ? "Image" : widget.replyTo!,
                  style: TextStyle(
                    color: widget.isMe ? Colors.grey : Colors.black54,
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAudioPlayer(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: widget.isMe ? primaryTwo : Colors.yellow[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              widget.isPlaying ? Icons.pause_circle : Icons.play_circle,
              color: widget.isMe ? primaryColor : Colors.yellow[800]!,
              size: 28,
            ),
            onPressed: () {
              if (widget.message != null && widget.onPlayAudio != null) {
                widget.onPlayAudio!.call(widget.messageId, widget.message!);
              }
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 18),
                LinearProgressIndicator(
                  value: widget.audioDuration.inSeconds > 0
                      ? widget.audioPosition.inSeconds /
                          widget.audioDuration.inSeconds
                      : 0,
                  backgroundColor: Colors.grey,
                  valueColor: AlwaysStoppedAnimation<Color>(
                      widget.isPlaying ? Colors.white : Colors.grey),
                  minHeight: 3,
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDuration(widget.isPlaying
                      ? widget.audioPosition
                      : widget.audioDuration),
                  style: TextStyle(
                    color: widget.isMe ? white : Colors.grey[600],
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageViewer(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (widget.message != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FullScreenImage(imagePath: widget.message!),
            ),
          );
        }
      },
      child: FutureBuilder<bool>(
        future: _messageFileExists,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              width: 180,
              height: 180,
              child: Center(child: Loader()),
            );
          }
          final fileExists = snapshot.data ?? false;
          if (!fileExists) {
            return Center(
              child: Icon(Icons.image_not_supported,
                  size: 40,
                  color: widget.isMe ? primaryColor : Colors.grey[600]),
            );
          }
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              File(widget.message!),
              width: 180,
              height: 180,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Center(
                  child: Icon(Icons.image_not_supported,
                      size: 40,
                      color: widget.isMe ? primaryColor : Colors.grey[600]),
                );
              },
            ),
          );
        },
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
