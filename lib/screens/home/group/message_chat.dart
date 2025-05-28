import 'package:cyanase/helpers/loader.dart';
import 'package:flutter/material.dart';
import 'package:cyanase/theme/theme.dart';
import 'package:cyanase/helpers/date_helper.dart';
import 'dart:io';
import 'full_screen_image_viewer.dart';
import 'package:audioplayers/audioplayers.dart';

class MessageTailPainter extends CustomPainter {
  final Color color;
  final bool isMe;

  MessageTailPainter({required this.color, required this.isMe});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    if (isMe) {
      path.moveTo(size.width, 0);
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
    } else {
      path.moveTo(0, 0);
      path.lineTo(0, size.height);
      path.lineTo(size.width, size.height);
    }
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

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
  final bool isNotification;
  final bool isPlaying;
  final Duration audioDuration;
  final Duration audioPosition;
  final void Function(String, String)? onPlayAudio;
  final String messageId;
  final String senderName;
  final String senderAvatar;
  final Function(String, String)? onReply;
  final Function(String)? onReplyTap;
  final String messageStatus;
  final Widget? messageContent;
  final bool isHighlighted;

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
    required this.isNotification,
    required this.onPlayAudio,
    this.isPlaying = false,
    this.audioDuration = Duration.zero,
    this.audioPosition = Duration.zero,
    required this.messageId,
    required this.senderName,
    required this.senderAvatar,
    this.onReply,
    this.onReplyTap,
    required this.messageStatus,
    this.messageContent,
    this.isHighlighted = false,
  });

  @override
  State<MessageChat> createState() => _MessageChatState();
}

class _MessageChatState extends State<MessageChat>
    with SingleTickerProviderStateMixin {
  late Future<bool> _messageFileExists;
  late Future<bool> _replyFileExists;
  late Future<Duration> _audioDuration;
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  double _dragDistance = 0.0;
  static const double _swipeThreshold = 50.0;
  late String _currentStatus;

  @override
  void initState() {
    super.initState();
    _messageFileExists = widget.isImage && widget.message != null
        ? doesFileExist(widget.message!)
        : Future.value(false);
    _replyFileExists = widget.replyTo != null && widget.replyToType == "image"
        ? doesFileExist(widget.replyTo!)
        : Future.value(false);

    if (widget.isAudio && widget.message != null) {
      _audioDuration = _getAudioDuration(widget.message!);
    } else {
      _audioDuration = Future.value(Duration.zero);
    }

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 5),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0.1, 0),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _currentStatus = widget.messageStatus;
  }

  @override
  void didUpdateWidget(MessageChat oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.messageStatus != widget.messageStatus) {
      setState(() {
        _currentStatus = widget.messageStatus;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (widget.isNotification) return; // Don't allow swipe for notifications

    setState(() {
      _dragDistance += details.delta.dx;
      // Limit the drag distance
      _dragDistance = _dragDistance.clamp(-100.0, 100.0);
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    if (widget.isNotification) return;

    if (_dragDistance.abs() > _swipeThreshold) {
      // Trigger reply
      if (widget.onReply != null && widget.message != null) {
        widget.onReply!(widget.messageId, widget.message!);
      }
    }

    // Animate back to original position with faster animation
    _animationController.duration = const Duration(milliseconds: 5);
    _animationController.forward(from: 0.0).then((_) {
      setState(() {
        _dragDistance = 0.0;
      });
    });
  }

  Future<bool> doesFileExist(String filePath) async {
    final file = File(filePath);
    return await file.exists();
  }

  Future<Duration> _getAudioDuration(String path) async {
    try {
      final player = AudioPlayer();
      await player.setSource(DeviceFileSource(path));
      final duration = await player.getDuration();
      await player.dispose();
      return duration ?? Duration.zero;
    } catch (e) {
      print("Error getting audio duration: $e");
      return Duration.zero;
    }
  }

  String _formatTime(String timestamp) {
    final dateTime = DateTime.parse(timestamp);
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    // If message is from today, show time only
    if (difference.inDays == 0) {
      return TimeOfDay.fromDateTime(dateTime).format(context);
    }
    // If message is from yesterday, show "Yesterday"
    else if (difference.inDays == 1) {
      return "Yesterday";
    }
    // If message is from this year, show date without year
    else if (dateTime.year == now.year) {
      return "${dateTime.day}/${dateTime.month}";
    }
    // If message is from previous years, show full date
    else {
      return "${dateTime.day}/${dateTime.month}/${dateTime.year}";
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedTime = _formatTime(widget.time);

    if (widget.isNotification) {
      return _buildNotification();
    }

    return Padding(
      padding: EdgeInsets.only(
        left: widget.isMe ? 64.0 : 8.0,
        right: widget.isMe ? 8.0 : 64.0,
        top: widget.isSameSender ? 4.0 : 12.0,
        bottom: 4.0,
      ),
      child: Align(
        alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: GestureDetector(
          onHorizontalDragUpdate: _handleDragUpdate,
          onHorizontalDragEnd: _handleDragEnd,
          child: Transform.translate(
            offset: Offset(_dragDistance, 0),
            child: Column(
              crossAxisAlignment: widget.isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
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
                            backgroundImage:
                                FileImage(File(widget.senderAvatar)),
                            backgroundColor: Colors.grey[300],
                            onBackgroundImageError: (_, __) => Container(),
                          ),
                        if (!widget.isMe) const SizedBox(width: 8),
                        Text(
                          widget.senderName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color:
                                widget.isMe ? primaryColor : Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                Semantics(
                  label: widget.isMe ? "Sent message" : "Received message",
                  child: Stack(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.6,
                        ),
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: widget.isMe
                                ? [primaryTwo, primaryTwo.withOpacity(0.85)]
                                : [Color(0xFFECECEC), Color(0xFFECECEC)],
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
                              color: widget.isHighlighted
                                  ? Colors.yellow.withOpacity(0.5)
                                  : Colors.black.withOpacity(0.05),
                              blurRadius: widget.isHighlighted ? 8 : 4,
                              spreadRadius: widget.isHighlighted ? 2 : 0,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: widget.isMe
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            if (widget.replyTo != null &&
                                widget.replyToId != null)
                              _buildReplySection(context),
                            if (widget.replyTo != null)
                              const SizedBox(height: 4),
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
                              widget.messageContent ??
                                  Text(
                                    widget.message!,
                                    style: TextStyle(
                                      color: widget.isMe
                                          ? Colors.white
                                          : Colors.black87,
                                      fontSize: 15,
                                      fontFamily: 'Roboto',
                                    ),
                                  ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: widget.isMe
                                  ? MainAxisAlignment.end
                                  : MainAxisAlignment.start,
                              children: [
                                Text(
                                  formattedTime,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: widget.isMe
                                        ? Colors.white70
                                        : Colors.grey[600],
                                  ),
                                ),
                                if (widget.isMe) ...[
                                  const SizedBox(width: 4),
                                  _buildMessageStatus(),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Message tail
                      Positioned(
                        bottom: 0,
                        right: widget.isMe ? 0 : null,
                        left: widget.isMe ? null : 0,
                        child: CustomPaint(
                          size: const Size(10, 10),
                          painter: MessageTailPainter(
                            color: widget.isMe ? primaryTwo : Color(0xFFECECEC),
                            isMe: widget.isMe,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
        return GestureDetector(
          onTap: () {
            if (widget.replyToId != null && widget.onReplyTap != null) {
              widget.onReplyTap!(widget.replyToId!);
            }
          },
          child: Container(
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
                if (widget.replyToType == "image" ||
                    (widget.replyTo!.startsWith('/') &&
                        (widget.replyTo!.endsWith('.jpg') ||
                            widget.replyTo!.endsWith('.png') ||
                            widget.replyTo!.endsWith('.jpeg'))))
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Icon(
                      Icons.image,
                      size: 24,
                      color: widget.isMe ? Colors.white70 : Colors.grey[600],
                    ),
                  )
                else if (widget.replyToType == "audio" ||
                    (widget.replyTo!.startsWith('/') &&
                        (widget.replyTo!.endsWith('.m4a') ||
                            widget.replyTo!.endsWith('.mp3'))))
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Icon(
                      Icons.mic,
                      size: 24,
                      color: widget.isMe ? Colors.white70 : Colors.grey[600],
                    ),
                  ),
                Expanded(
                  child: Text(
                    widget.replyToType == "image" ||
                            (widget.replyTo!.startsWith('/') &&
                                (widget.replyTo!.endsWith('.jpg') ||
                                    widget.replyTo!.endsWith('.png') ||
                                    widget.replyTo!.endsWith('.jpeg')))
                        ? "Image"
                        : widget.replyToType == "audio" ||
                                (widget.replyTo!.startsWith('/') &&
                                    (widget.replyTo!.endsWith('.m4a') ||
                                        widget.replyTo!.endsWith('.mp3')))
                            ? "Audio"
                            : widget.replyTo!,
                    style: TextStyle(
                      color: widget.isMe ? Colors.white70 : Colors.black54,
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAudioPlayer(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: widget.isMe ? primaryColor : Colors.yellow[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              widget.isPlaying ? Icons.pause_circle : Icons.play_circle,
              color: widget.isMe ? white : primaryColor,
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
                FutureBuilder<Duration>(
                  future: _audioDuration,
                  builder: (context, snapshot) {
                    final totalDuration = snapshot.data ?? Duration.zero;
                    final progress = totalDuration.inSeconds > 0
                        ? widget.audioPosition.inSeconds /
                            totalDuration.inSeconds
                        : 0.0;

                    return LinearProgressIndicator(
                      value: progress,
                      backgroundColor: white,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        widget.isPlaying ? primaryTwo : Colors.grey[600]!,
                      ),
                      minHeight: 3,
                    );
                  },
                ),
                const SizedBox(height: 4),
                FutureBuilder<Duration>(
                  future: _audioDuration,
                  builder: (context, snapshot) {
                    final duration = snapshot.data ?? Duration.zero;
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.isPlaying
                              ? _formatDuration(widget.audioPosition)
                              : _formatDuration(duration),
                          style: TextStyle(
                            color: widget.isMe ? white : Colors.grey[600],
                            fontSize: 11,
                          ),
                        ),
                      ],
                    );
                  },
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
    final seconds = duration.inSeconds;
    return "${seconds}s";
  }

  Widget _buildMessageStatus() {
    IconData icon;
    Color color;

    switch (_currentStatus) {
      case 'sending':
        icon = Icons.access_time;
        color = Colors.grey;
        break;
      case 'sent':
        icon = Icons.check;
        color = Colors.grey;
        break;
      case 'delivered':
        icon = Icons.done_all;
        color = Colors.grey;
        break;
      case 'read':
        icon = Icons.done_all;
        color = Colors.blue;
        break;
      case 'failed':
        icon = Icons.error_outline;
        color = Colors.red;
        break;
      default:
        icon = Icons.access_time;
        color = Colors.grey;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        if (_currentStatus == 'failed')
          TextButton(
            onPressed: () {
              // Implement retry logic here
            },
            child: const Text('Retry'),
          ),
      ],
    );
  }

  Widget _buildNotification() {
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
}