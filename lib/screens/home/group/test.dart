import 'package:cyanase/helpers/loader.dart';
import 'package:flutter/material.dart';
import 'package:cyanase/theme/theme.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'dart:io';
import 'package:cyanase/screens/home/group/full_screen_image_viewer.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:cyanase/helpers/database_helper.dart';
import 'package:cyanase/helpers/download_helper.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/gestures.dart';
import 'package:cyanase/helpers/chat_utils.dart';
import 'package:cyanase/helpers/link_preview_service.dart';

class MessageTailPainter extends CustomPainter {
  final Color color;
  final bool isMe;
  final bool isUnread;

  MessageTailPainter({required this.color, required this.isMe, required this.isUnread});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isMe ? color : isUnread ? Colors.grey[300]! : color
      ..style = PaintingStyle.fill;

    final path = Path();
    const double tailWidth = 12.0;
    const double tailHeight = 16.0;
    const double borderRadius = 16.0;

    if (isMe) {
      path.moveTo(size.width - borderRadius, 0);
      path.lineTo(borderRadius, 0);
      path.quadraticBezierTo(0, 0, 0, borderRadius);
      path.lineTo(0, size.height - borderRadius);
      path.quadraticBezierTo(0, size.height, borderRadius, size.height);
      path.lineTo(size.width - tailWidth - borderRadius, size.height);
      path.quadraticBezierTo(
        size.width - tailWidth - borderRadius / 2,
        size.height,
        size.width - tailWidth,
        size.height - tailHeight / 2,
      );
      path.lineTo(size.width, size.height - tailHeight);
      path.quadraticBezierTo(
        size.width,
        size.height - tailHeight / 2,
        size.width - tailWidth,
        size.height - tailHeight,
      );
      path.lineTo(size.width - borderRadius, size.height - tailHeight);
      path.quadraticBezierTo(
        size.width,
        size.height - tailHeight,
        size.width,
        size.height - tailHeight - borderRadius,
      );
      path.lineTo(size.width, borderRadius);
      path.quadraticBezierTo(size.width, 0, size.width - borderRadius, 0);
    } else {
      path.moveTo(borderRadius, 0);
      path.lineTo(size.width - borderRadius, 0);
      path.quadraticBezierTo(size.width, 0, size.width, borderRadius);
      path.lineTo(size.width, size.height - borderRadius);
      path.quadraticBezierTo(size.width, size.height, size.width - borderRadius, size.height);
      path.lineTo(tailWidth + borderRadius, size.height);
      path.quadraticBezierTo(
        tailWidth + borderRadius / 2,
        size.height,
        tailWidth,
        size.height - tailHeight / 2,
      );
      path.lineTo(0, size.height - tailHeight);
      path.quadraticBezierTo(
        0,
        size.height - tailHeight / 2,
        tailWidth,
        size.height - tailHeight,
      );
      path.lineTo(borderRadius, size.height - tailHeight);
      path.quadraticBezierTo(
        0,
        size.height - tailHeight,
        0,
        size.height - tailHeight - borderRadius,
      );
      path.lineTo(0, borderRadius);
      path.quadraticBezierTo(0, 0, borderRadius, 0);
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
  final String senderRole;
  final Function(String, String)? onReply;
  final Function(String)? onReplyTap;
  final String messageStatus;
  final Widget? messageContent;
  final bool isHighlighted;
  final bool isUnread;

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
    required this.senderRole,
    this.onReply,
    this.onReplyTap,
    required this.messageStatus,
    this.messageContent,
    this.isHighlighted = false,
    this.isUnread = false,
  });

  @override
  State<MessageChat> createState() => _MessageChatState();
}

class _MessageChatState extends State<MessageChat> with SingleTickerProviderStateMixin {
  late Future<bool> _messageFileExists;
  late Future<bool> _replyFileExists;
  late Future<Duration> _audioDuration;
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  Map<String, dynamic>? _mediaData;
  double _dragDistance = 0.0;
  static const double _swipeThreshold = 70.0;
  late String _currentStatus;
  Map<String, Map<String, String>?> _linkPreviews = {};
  bool _isLoadingPreview = false;

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
      duration: const Duration(milliseconds: 200),
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
    _loadMediaData();
    _loadLinkPreviews();
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
    if (widget.isNotification) return;

    setState(() {
      _dragDistance += details.delta.dx;
      _dragDistance = _dragDistance.clamp(-100.0, 100.0);
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    if (widget.isNotification) return;

    if (_dragDistance.abs() > _swipeThreshold) {
      if (widget.onReply != null && widget.message != null) {
        widget.onReply!(widget.messageId, widget.message!);
      }
    }

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

  Future<void> _loadMediaData() async {
    if (!widget.isImage && !widget.isAudio) return;

    try {
      if (widget.messageId.isEmpty) {
        return;
      }

      final messageId = int.tryParse(widget.messageId);
      if (messageId == null) {
        return;
      }

      final media = await DatabaseHelper().getMedia(messageId);

      if (mounted) {
        setState(() {
          _mediaData = media;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _mediaData = null;
        });
      }
    }
  }

  Future<void> _downloadMedia() async {
    if (_mediaData == null || _mediaData!['url'] == null) return;

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    final mediaInfo = await MediaDownloader.downloadMedia(
      url: _mediaData!['url'],
      type: widget.isImage ? 'image' : 'audio',
      messageId: int.parse(widget.messageId),
    );

    if (mediaInfo != null && mounted) {
      await DatabaseHelper().updateMedia(
        messageId: int.parse(widget.messageId),
        filePath: mediaInfo['file_path'],
        isDownloaded: true,
        fileSize: mediaInfo['file_size'],
        duration: mediaInfo['duration'],
      );
      setState(() {
        _mediaData = {
          ..._mediaData!,
          'file_path': mediaInfo['file_path'],
          'is_downloaded': 1,
          'file_size': mediaInfo['file_size'],
          'duration': mediaInfo['duration'],
        };
        _isDownloading = false;
      });
    } else if (mounted) {
      setState(() {
        _isDownloading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Download failed')),
      );
    }
  }

  Future<void> _loadLinkPreviews() async {
    if (widget.isAudio || widget.isImage || widget.isNotification || widget.message == null) return;

    setState(() => _isLoadingPreview = true);
    final urls = ChatUtils.extractUrls(widget.message!);
    if (urls.isNotEmpty) {
      final preview = await LinkPreviewService.getLinkPreview(urls.first);
      if (mounted) {
        setState(() {
          _linkPreviews[urls.first] = preview;
          _isLoadingPreview = false;
        });
      }
    } else {
      if (mounted) {
        setState(() => _isLoadingPreview = false);
      }
    }
  }

  Future<Duration> _getAudioDuration(String path) async {
    try {
      final player = AudioPlayer();
      await player.setSource(DeviceFileSource(path));
      final duration = await player.getDuration();
      await player.dispose();
      return duration ?? Duration.zero;
    } catch (e) {
      return Duration.zero;
    }
  }

  String _formatTime(String timestamp) => ChatUtils.formatTime(timestamp);

  String _getDayName(int weekday) => ChatUtils.getDayName(weekday);

  ImageProvider _getImageProvider(String profilePic) {
    if (profilePic.isEmpty || profilePic == 'null') {
      return const AssetImage('assets/images/avatar.png');
    }

    if (profilePic.startsWith('file://')) {
      final filePath = profilePic.replaceFirst('file://', '');
      final file = File(filePath);
      if (file.existsSync()) {
        return FileImage(file);
      } else {
        return const AssetImage('assets/images/avatar.png');
      }
    }

    if (profilePic.startsWith('http://') || profilePic.startsWith('https://')) {
      return NetworkImage(profilePic);
    }

    final file = File(profilePic);
    if (file.existsSync()) {
      return FileImage(file);
    }

    return const AssetImage('assets/images/avatar.png');
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
        child: Column(
          crossAxisAlignment: widget.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!widget.isSameSender)
              Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!widget.isMe)
                      CircleAvatar(
                        backgroundImage: _getImageProvider(widget.senderAvatar),
                        radius: 12,
                        backgroundColor: Colors.grey[200],
                        child: widget.senderAvatar.isEmpty
                            ? const Icon(Icons.person, color: Colors.grey)
                            : null,
                      ),
                    if (!widget.isMe) const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.senderName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: widget.isMe ? primaryColor : Colors.grey[700],
                          ),
                        ),
                        Text(
                          widget.senderRole,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            GestureDetector(
              onHorizontalDragUpdate: _handleDragUpdate,
              onHorizontalDragEnd: _handleDragEnd,
              child: Transform.translate(
                offset: Offset(_dragDistance, 0),
                child: Semantics(
                  label: widget.isMe ? "Sent message" : "Received message",
                  child: Stack(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.65,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: widget.isMe
                                ? [primaryTwo, primaryTwo.withOpacity(0.85)]
                                : widget.isUnread
                                    ? [Colors.grey[300]!, Colors.grey[300]!.withOpacity(0.9)]
                                    : [Color(0xFFECECEC), Color(0xFFECECEC)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(widget.isMe || widget.isSameSender ? 12 : 0),
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
                          crossAxisAlignment:
                              widget.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            if (widget.replyTo != null && widget.replyToId != null)
                              _buildReplySection(context),
                            if (widget.replyTo != null) const SizedBox(height: 4),
                            _buildMessageContent(context),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment:
                                  widget.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                              children: [
                                Text(
                                  formattedTime,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: widget.isMe ? Colors.white70 : Colors.grey[600],
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
                      Positioned(
                        bottom: 0,
                        right: widget.isMe ? 0 : null,
                        left: widget.isMe ? null : 0,
                        child: CustomPaint(
                          size: const Size(10, 10),
                          painter: MessageTailPainter(
                            color: widget.isMe ? primaryTwo : Color(0xFFECECEC),
                            isMe: widget.isMe,
                            isUnread: widget.isUnread,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context) {
    if (widget.isAudio) return _buildAudioPlayer(context);
    if (widget.isImage) return _buildImageViewer(context);
    if (widget.isNotification) return _buildNotification();
    if (widget.message == null) {
      return const Text(
        "Message unavailable",
        style: TextStyle(color: Colors.grey),
      );
    }

    if (!ChatUtils.containsUrl(widget.message!)) {
      return Text(
        widget.message!,
        style: TextStyle(
          color: widget.isMe ? Colors.white : Colors.black87,
          fontSize: 15,
          fontFamily: 'Roboto',
        ),
      );
    }

    final parts = _splitMessageWithUrls(widget.message!);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            children: parts.map((part) {
              if (ChatUtils.containsUrl(part)) {
                final displayUrl = part.length > 30 ? '${part.substring(0, 27)}...' : part;
                return TextSpan(
                  text: displayUrl,
                  style: TextStyle(
                    color: widget.isMe ? Colors.lightBlue[200] : Colors.blue,
                    fontSize: 15,
                    fontFamily: 'Roboto',
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () async {
                      final url = part.startsWith('http') ? part : 'https://$part';
                      if (await canLaunchUrl(Uri.parse(url))) {
                        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Cannot open URL: $url')),
                        );
                      }
                    },
                );
              }
              return TextSpan(
                text: part,
                style: TextStyle(
                  color: widget.isMe ? Colors.white : Colors.black87,
                  fontSize: 15,
                  fontFamily: 'Roboto',
                ),
              );
            }).toList(),
          ),
        ),
        if (_isLoadingPreview)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: SizedBox(
              width: 20,
              height: 20,
              child: Loader(),
            ),
          ),
        if (_linkPreviews.isNotEmpty &&
            _linkPreviews[parts.firstWhere(ChatUtils.containsUrl, orElse: () => '')] != null)
          _buildLinkPreview(context, _linkPreviews[parts.firstWhere(ChatUtils.containsUrl)]!),
      ],
    );
  }

  List<String> _splitMessageWithUrls(String message) {
    final urls = ChatUtils.extractUrls(message);
    List<String> parts = [];
    String remaining = message;

    for (var url in urls) {
      final index = remaining.indexOf(url);
      if (index > 0) {
        parts.add(remaining.substring(0, index));
      }
      parts.add(url);
      remaining = remaining.substring(index + url.length);
    }
    if (remaining.isNotEmpty) {
      parts.add(remaining);
    }
    return parts;
  }

  Widget _buildLinkPreview(BuildContext context, Map<String, String> preview) {
    final maxWidth = MediaQuery.of(context).size.width * 0.55;
    return Semantics(
      link: true,
      label: 'Link to ${preview['title']}',
      child: GestureDetector(
        onTap: () async {
          final url = preview['url'] ?? '';
          if (await canLaunchUrl(Uri.parse(url))) {
            await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Cannot open URL: $url')),
            );
          }
        },
        child: Container(
          margin: const EdgeInsets.only(top: 8),
          constraints: BoxConstraints(maxWidth: maxWidth),
          decoration: BoxDecoration(
            color: widget.isMe ? Colors.white.withOpacity(0.1) : Colors.grey[300],
            borderRadius: const BorderRadius.all(Radius.circular(8)),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            children: [
              if (preview['image'] != null && preview['image']!.isNotEmpty)
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    bottomLeft: Radius.circular(8),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: preview['image']!,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[300],
                      child: const Loader(),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image_not_supported, size: 40),
                    ),
                  ),
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        preview['title'] ?? 'No title',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: widget.isMe ? Colors.white : Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        preview['description'] ?? 'No description',
                        style: TextStyle(
                          fontSize: 12,
                          color: widget.isMe ? Colors.white70 : Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
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

        String replyContent = widget.replyTo ?? 'Original message unavailable';
        final replyType = widget.replyToType ?? 'text';

        Widget replyContentWidget;
        switch (replyType) {
          case 'image':
            replyContentWidget = _buildReplyImage(context, fileExists, replyContent);
            break;
          case 'audio':
            replyContentWidget = _buildReplyAudio(context, fileExists);
            break;
          default:
            replyContentWidget = Text(
              replyContent,
              style: TextStyle(
                color: widget.isMe ? Colors.white : Colors.black87,
                fontSize: 12,
                fontFamily: 'Roboto',
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            );
            break;
        }

        return GestureDetector(
          onTap: () {
            if (widget.replyToId != null && widget.onReplyTap != null) {
              widget.onReplyTap!(widget.replyToId!);
            }
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.only(left: 4),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: widget.isMe ? primaryColor : primaryTwo!,
                  width: 3,
                ),
              ),
            ),
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.55,
              ),
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              decoration: BoxDecoration(
                color: widget.isMe ? primaryTwoLight : Colors.grey[100]!.withOpacity(0.8),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.isMe ? 'You' : widget.senderName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: widget.isMe ? primaryColor : primaryTwo,
                      fontFamily: 'Roboto',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  replyContentWidget,
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildReplyImage(BuildContext context, bool fileExists, String replyContent) {
    if (!fileExists || widget.replyTo == null) {
      return Row(
        children: [
          Icon(
            Icons.image,
            size: 16,
            color: widget.isMe ? Colors.white70 : Colors.grey[600],
          ),
          const SizedBox(width: 4),
          Text(
            'Photo',
            style: TextStyle(
              fontSize: 12,
              color: widget.isMe ? Colors.white70 : Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Stack(
            children: [
              Image.file(
                File(widget.replyTo!),
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 40,
                    height: 40,
                    color: Colors.grey[300],
                    child: Icon(
                      Icons.image_not_supported,
                      size: 20,
                      color: widget.isMe ? Colors.white70 : Colors.grey[600],
                    ),
                  );
                },
              ),
              Positioned(
                bottom: 2,
                right: 2,
                child: Icon(
                  Icons.camera_alt,
                  size: 12,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'Photo',
            style: TextStyle(
              fontSize: 12,
              color: widget.isMe ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReplyAudio(BuildContext context, bool fileExists) {
    if (!fileExists || widget.replyTo == null) {
      return Row(
        children: [
          Icon(
            Icons.mic,
            size: 16,
            color: widget.isMe ? Colors.white70 : Colors.grey[600],
          ),
          const SizedBox(width: 4),
          Text(
            'Voice message',
            style: TextStyle(
              fontSize: 12,
              color: widget.isMe ? Colors.white70 : Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Icon(
          Icons.play_arrow,
          size: 16,
          color: widget.isMe ? Colors.white : Colors.grey[800],
        ),
        const SizedBox(width: 4),
        FutureBuilder<Duration>(
          future: _audioDuration,
          builder: (context, snapshot) {
            final duration = snapshot.data ?? Duration.zero;
            return Text(
              _formatDuration(duration),
              style: TextStyle(
                fontSize: 12,
                color: widget.isMe ? Colors.white : Colors.black87,
              ),
            );
          },
        ),
        const SizedBox(width: 4),
        Icon(
          Icons.mic,
          size: 16,
          color: widget.isMe ? Colors.white : Colors.grey[800],
        ),
      ],
    );
  }

  Widget _buildAudioPlayer(BuildContext context) {
    if (_mediaData == null) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: widget.isMe ? primaryColor : Colors.yellow[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Loader(),
        ),
      );
    }

    if (widget.isMe && _mediaData!['file_path'] != null) {
      final filePath = _mediaData!['file_path'];
      final file = File(filePath);
      if (!file.existsSync()) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Icon(
              Icons.error,
              size: 24,
              color: white,
            ),
          ),
        );
      }

      return FutureBuilder<Duration>(
        future: _getAudioDuration(filePath),
        builder: (context, snapshot) {
          final duration = snapshot.data ?? Duration.zero;
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    widget.isPlaying ? Icons.pause_circle : Icons.play_circle,
                    color: white,
                    size: 28,
                  ),
                  onPressed: () {
                    if (widget.onPlayAudio != null) {
                      widget.onPlayAudio!(widget.messageId, filePath);
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
                        value: duration.inSeconds > 0
                            ? widget.audioPosition.inSeconds / duration.inSeconds
                            : 0.0,
                        backgroundColor: white,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          widget.isPlaying ? primaryTwo : Colors.grey[600]!,
                        ),
                        minHeight: 3,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            widget.isPlaying
                                ? _formatDuration(widget.audioPosition)
                                : _formatDuration(duration),
                            style: const TextStyle(
                              color: white,
                              fontSize: 11,
                            ),
                          ),
                          const Icon(
                            Icons.mic,
                            size: 20,
                            color: white,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    if (!widget.isMe) {
      if (_mediaData!['is_downloaded'] == 0) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.yellow[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Semantics(
                  button: true,
                  label: 'Download audio',
                  child: Icon(
                    Icons.download,
                    color: primaryColor,
                    size: 24,
                  ),
                ),
                onPressed: _isDownloading ? null : _downloadMedia,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              _isDownloading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: Loader(),
                    )
                  : Text(
                      'Download',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
              const SizedBox(width: 8),
              Icon(
                Icons.mic,
                size: 20,
                color: Colors.grey[600],
              ),
            ],
          ),
        );
      }

      final filePath = _mediaData!['file_path'];
      if (filePath == null) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.yellow[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: GestureDetector(
            onTap: _downloadMedia,
            child: const Center(
              child: Icon(
                Icons.error,
                size: 24,
                color: Colors.red,
              ),
            ),
          ),
        );
      }

      final file = File(filePath);
      if (!file.existsSync()) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.yellow[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: GestureDetector(
            onTap: _downloadMedia,
            child: const Center(
              child: Icon(
                Icons.error,
                size: 24,
                color: Colors.red,
              ),
            ),
          ),
        );
      }

      return FutureBuilder<Duration>(
        future: _getAudioDuration(filePath),
        builder: (context, snapshot) {
          final duration = snapshot.data ?? Duration.zero;
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.yellow[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    widget.isPlaying ? Icons.pause_circle : Icons.play_circle,
                    color: primaryColor,
                    size: 28,
                  ),
                  onPressed: () {
                    if (widget.onPlayAudio != null) {
                      widget.onPlayAudio!(widget.messageId, filePath);
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
                        value: duration.inSeconds > 0
                            ? widget.audioPosition.inSeconds / duration.inSeconds
                            : 0.0,
                        backgroundColor: white,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          widget.isPlaying ? primaryTwo : Colors.grey[600]!,
                        ),
                        minHeight: 3,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            widget.isPlaying
                                ? _formatDuration(widget.audioPosition)
                                : _formatDuration(duration),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 11,
                            ),
                          ),
                          Icon(
                            Icons.mic,
                            size: 20,
                            color: Colors.grey[600],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: widget.isMe ? primaryColor : Colors.yellow[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Icon(
          Icons.error,
          size: 24,
          color: Colors.red,
        ),
      ),
    );
  }

  Widget _buildImageViewer(BuildContext context) {
    final imageSize = MediaQuery.of(context).size.width * 0.5;

    if (widget.isMe) {
      final filePath = widget.message;
      if (filePath == null) {
        return Container(
          width: imageSize,
          height: imageSize,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Icon(
              Icons.error,
              size: 40,
              color: Colors.red,
            ),
          ),
        );
      }

      final file = File(filePath);
      if (!file.existsSync()) {
        return Container(
          width: imageSize,
          height: imageSize,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Icon(
              Icons.error,
              size: 40,
              color: Colors.red,
            ),
          ),
        );
      }

      return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FullScreenImage(imagePath: filePath),
            ),
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            file,
            width: imageSize,
            height: imageSize,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const Center(
                child: Icon(
                  Icons.image_not_supported,
                  size: 40,
                  color: primaryColor,
                ),
              );
            },
          ),
        ),
      );
    }

    if (!widget.isMe) {
      if (_mediaData == null) {
        return Container(
          width: imageSize,
          height: imageSize,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Loader(),
          ),
        );
      }

      if (_mediaData!['is_downloaded'] == 0) {
        return GestureDetector(
          onTap: _isDownloading ? null : _downloadMedia,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: imageSize,
                height: imageSize,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _mediaData!['blurhash'] != null
                      ? SizedBox(
                          width: imageSize,
                          height: imageSize,
                          child: BlurHash(
                            hash: _mediaData!['blurhash'],
                            imageFit: BoxFit.cover,
                          ),
                        )
                      : Container(
                          color: Colors.black.withOpacity(0.5),
                          child: const Center(
                            child: Icon(
                              Icons.image,
                              size: 40,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                ),
              ),
              _isDownloading
                  ? const Loader()
                  : Semantics(
                      button: true,
                      label: 'Download image',
                      child: Icon(
                        Icons.download,
                        size: 40,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
            ],
          ),
        );
      }

      final filePath = _mediaData!['file_path'];
      if (filePath == null) {
        return GestureDetector(
          onTap: _downloadMedia,
          child: Container(
            width: imageSize,
            height: imageSize,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Icon(
                Icons.error,
                size: 40,
                color: Colors.red,
              ),
            ),
          ),
        );
      }

      final file = File(filePath);
      if (!file.existsSync()) {
        return GestureDetector(
          onTap: _downloadMedia,
          child: Container(
            width: imageSize,
            height: imageSize,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Icon(
                Icons.error,
                size: 40,
                color: Colors.red,
              ),
            ),
          ),
        );
      }

      return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FullScreenImage(imagePath: filePath),
            ),
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            file,
            width: imageSize,
            height: imageSize,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return GestureDetector(
                onTap: _downloadMedia,
                child: const Center(
                  child: Icon(
                    Icons.image_not_supported,
                    size: 40,
                    color: Colors.grey,
                  ),
                ),
              );
            },
          ),
        ),
      );
    }

    return Container(
      width: imageSize,
      height: imageSize,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Icon(
          Icons.error,
          size: 40,
          color: Colors.red,
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }

  Widget _buildMessageStatus() {
    IconData icon;
    Color color;

    switch (widget.messageStatus) {
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
        if (widget.messageStatus == 'failed')
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

  Widget _buildReplyContent() {
    if (widget.replyTo == null) return const SizedBox.shrink();

    final isMediaReply = widget.replyTo!.startsWith('/') ||
        widget.replyTo!.contains('Pictures/Cyanase') ||
        widget.replyTo!.contains('audio_') ||
        widget.replyTo!.contains('image_');

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 40,
            color: primaryTwo,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Replying to message',
                  style: TextStyle(
                    color: primaryTwo,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                if (isMediaReply)
                  Row(
                    children: [
                      Icon(
                        widget.replyTo!.contains('audio_') ? Icons.audio_file : Icons.image,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.replyTo!.contains('audio_') ? 'Audio message' : 'Image',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    widget.replyTo!,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}