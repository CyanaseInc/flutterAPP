import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_sound/flutter_sound.dart'; // Changed from record package
import './functions/audio_function.dart';
import './functions/image_functions.dart';
import 'package:cyanase/theme/theme.dart';

import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';

class InputArea extends StatefulWidget {
  final TextEditingController controller;
  final bool isRecording;
  final Duration recordingDuration;
  final VoidCallback onSendMessage;
  final VoidCallback onStartRecording;
  final VoidCallback onStopRecording;
  final VoidCallback onCancelRecording;
  final Function(String) onSendImageMessage;
  final Function(String) onSendAudioMessage;
  final String? replyToId;
  final Map<String, dynamic>? replyingToMessage;
  final VoidCallback? onCancelReply;
  final AudioFunctions audioFunctions;
  final bool isAdminOnlyMode;
  final bool isCurrentUserAdmin;
  final String? currentUserId;

  const InputArea({
    super.key,
    required this.controller,
    required this.isRecording,
    required this.recordingDuration,
    required this.onSendMessage,
    required this.onStartRecording,
    required this.onStopRecording,
    required this.onCancelRecording,
    required this.onSendImageMessage,
    required this.onSendAudioMessage,
    this.replyToId,
    this.replyingToMessage,
    this.onCancelReply,
    required this.audioFunctions,
    required this.isAdminOnlyMode,
    required this.isCurrentUserAdmin,
    this.currentUserId,
  });

  @override
  _InputAreaState createState() => _InputAreaState();
}

class _InputAreaState extends State<InputArea> {
  bool _isTyping = false;
  final FocusNode _focusNode = FocusNode();
  double _textFieldHeight = 40.0;
  final double _maxHeight = 120.0;
  bool _showEmojiPicker = false;

  String _truncateReplyText(String text, {int maxLength = 30}) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        setState(() {
          _showEmojiPicker = false;
        });
      }
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      _isTyping = widget.controller.text.trim().isNotEmpty;
    });
  }

  Future<bool> _checkAudioPermission() async {
    // Updated permission check for flutter_sound
    final status = await Permission.microphone.status;
    if (!status.isGranted) {
      final result = await Permission.microphone.request();
      return result.isGranted;
    }
    return true;
  }

  bool get _canSendMessages {
    if (!widget.isAdminOnlyMode) return true;
    return widget.isCurrentUserAdmin;
  }

  void _onEmojiSelected(Category? category, Emoji emoji) {
    final text = widget.controller.text;
    final textSelection = widget.controller.selection;
    final newText = text.replaceRange(
      textSelection.start >= 0 ? textSelection.start : 0,
      textSelection.end >= 0 ? textSelection.end : 0,
      emoji.emoji,
    );
    final emojiLength = emoji.emoji.length;
    widget.controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset:
            (textSelection.start >= 0 ? textSelection.start : 0) + emojiLength,
      ),
    );
  }

  void _toggleEmojiPicker() {
    setState(() {
      _showEmojiPicker = !_showEmojiPicker;
      if (_showEmojiPicker) {
        _focusNode.unfocus();
      } else {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          color: white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.replyingToMessage != null)
                Container(
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border(left: BorderSide(color: primaryColor, width: 2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.reply, color: primaryColor, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Tooltip(
                          message: widget.replyingToMessage!['message'],
                          child: widget.replyingToMessage!['type'] == 'image'
                              ? const Icon(Icons.image, color: Colors.black54, size: 20)
                              : widget.replyingToMessage!['type'] == 'audio'
                                  ? const Icon(Icons.audio_file, color: Colors.black54, size: 20)
                                  : Text(
                                      _truncateReplyText(
                                          widget.replyingToMessage!['message']),
                                      style: const TextStyle(
                                        color: Colors.black54,
                                        fontSize: 14,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, 
                            color: primaryColor, size: 18),
                        onPressed: widget.onCancelReply,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),

              if (widget.isAdminOnlyMode && !widget.isCurrentUserAdmin)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.admin_panel_settings,
                          size: 16, color: Colors.red),
                      const SizedBox(width: 4),
                      Text(
                        'Only admins can send messages',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 13.5,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),

              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (widget.isRecording)
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: widget.onCancelRecording,
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.mic, color: Colors.red),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Recording... ${widget.recordingDuration.inSeconds}s",
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 15.5,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.send, color: primaryTwo),
                              onPressed: widget.onStopRecording,
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: Container(
                        constraints: BoxConstraints(
                          maxHeight: _maxHeight,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: Icon(
                                _showEmojiPicker
                                    ? Icons.keyboard
                                    : Icons.emoji_emotions,
                                color: primaryColor,
                              ),
                              onPressed: _toggleEmojiPicker,
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  if (!_showEmojiPicker) {
                                    _focusNode.requestFocus();
                                  }
                                },
                                child: TextField(
                                  controller: widget.controller,
                                  focusNode: _focusNode,
                                  maxLines: null,
                                  minLines: 1,
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  keyboardType: TextInputType.multiline,
                                  style: const TextStyle(fontSize: 16.5),
                                  decoration: InputDecoration(
                                    hintText: "Type a message...",
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 14,
                                    ),
                                    enabled: _canSendMessages &&
                                        widget.currentUserId != null,
                                  ),
                                  onChanged: (text) {
                                    setState(() {
                                      _textFieldHeight = text.isEmpty
                                          ? 40.0
                                          : (_textFieldHeight + 20.0)
                                              .clamp(40.0, _maxHeight);
                                    });
                                  },
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.attach_file,
                                  color: primaryColor),
                              onPressed: (_canSendMessages &&
                                      widget.currentUserId != null)
                                  ? () {
                                      showModalBottomSheet(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return Container(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 20),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                ListTile(
                                                  leading: const Icon(
                                                      Icons.image,
                                                      color: primaryColor),
                                                  title: const Text('Image'),
                                                  onTap: () async {
                                                    Navigator.pop(context);
                                                    try {
                                                      final imageFile =
                                                          await ImageFunctions()
                                                              .pickImageFromGallery();
                                                      if (imageFile != null) {
                                                        final imagePath =
                                                            await ImageFunctions()
                                                                .saveImageToStorage(
                                                                    imageFile);
                                                        widget
                                                            .onSendImageMessage(
                                                                imagePath);
                                                      }
                                                    } catch (e) {
                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                        SnackBar(
                                                            content: Text(
                                                                'Error picking image: $e')),
                                                      );
                                                    }
                                                  },
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      );
                                    }
                                  : null,
                            ),
                            IconButton(
                              icon: Icon(
                                _isTyping ? Icons.send : Icons.mic,
                                color: _isTyping ? primaryTwo : primaryColor,
                              ),
                              onPressed: (_canSendMessages &&
                                      widget.currentUserId != null)
                                  ? () async {
                                      if (_isTyping) {
                                        widget.onSendMessage();
                                      } else {
                                        if (await _checkAudioPermission()) {
                                          widget.onStartRecording();
                                        } else {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  'Microphone permission required'),
                                            ),
                                          );
                                        }
                                      }
                                    }
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        if (_showEmojiPicker)
          SizedBox(
            height: 250,
            child: EmojiPicker(
              onEmojiSelected: (category, emoji) => _onEmojiSelected(category, emoji),
              config: Config(
                height: 250,
                checkPlatformCompatibility: true,
                emojiViewConfig: EmojiViewConfig(
                  columns: 7,
                  emojiSizeMax: 32,
                  verticalSpacing: 0,
                  horizontalSpacing: 0,
                  gridPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ),
      ],
    );
  }
}