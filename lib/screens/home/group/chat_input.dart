import 'package:flutter/material.dart';
import 'package:record/record.dart';
import './functions/audio_function.dart';
import './functions/image_functions.dart';
import 'package:cyanase/theme/theme.dart';

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
  final String? replyingToMessage;
  final VoidCallback? onCancelReply;
  final AudioFunctions audioFunctions;
  final bool isAdminOnlyMode; // New parameter
  final bool isCurrentUserAdmin; // New parameter

  const InputArea(
      {super.key,
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
      required this.isAdminOnlyMode, // Default to false (normal mode)
      required this.isCurrentUserAdmin // Default to false (regular user)
      });

  @override
  _InputAreaState createState() => _InputAreaState();
}

class _InputAreaState extends State<InputArea> {
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      _isTyping = widget.controller.text.trim().isNotEmpty;
    });
  }

  Future<bool> _checkAudioPermission() async {
    return await Record().hasPermission();
  }

  bool get _canSendMessages {
    // If not in admin-only mode, anyone can send
    if (!widget.isAdminOnlyMode) return true;

    // In admin-only mode, only admins can send
    return widget.isCurrentUserAdmin;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: white,
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          if (widget.replyingToMessage != null)
            Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
                border: Border(left: BorderSide(color: primaryColor, width: 2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.reply, color: primaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.replyingToMessage!,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: primaryColor),
                    onPressed: widget.onCancelReply,
                  ),
                ],
              ),
            ),
          if (widget.replyingToMessage != null) const SizedBox(height: 4),

          // Add admin restriction notice
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
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),

          Row(
            children: [
              if (widget.isRecording)
                Expanded(
                  child: GestureDetector(
                    onHorizontalDragEnd: (details) {
                      if (details.primaryVelocity! < -200) {
                        widget.onCancelRecording();
                      }
                    },
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
                                fontSize: 14,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.send, color: Colors.green),
                            onPressed: widget.onStopRecording,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: widget.controller,
                          decoration: InputDecoration(
                            hintText: "Type a message...",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 16),
                            enabled: _canSendMessages, // Disable if not allowed
                          ),
                          maxLines: null,
                          keyboardType: TextInputType.multiline,
                          readOnly:
                              !_canSendMessages, // Make read-only if not allowed
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.image, color: primaryColor),
                        onPressed: _canSendMessages
                            ? () async {
                                try {
                                  final imageFile = await ImageFunctions()
                                      .pickImageFromGallery();
                                  if (imageFile != null) {
                                    final imagePath = await ImageFunctions()
                                        .saveImageToStorage(imageFile);
                                    widget.onSendImageMessage(imagePath);
                                  }
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content:
                                            Text('Error picking image: $e')),
                                  );
                                }
                              }
                            : null, // Disable if not allowed
                      ),
                      IconButton(
                        icon: Icon(
                          _isTyping ? Icons.send : Icons.mic,
                          color: _isTyping ? Colors.green : primaryColor,
                        ),
                        onPressed: _canSendMessages
                            ? () async {
                                if (_isTyping) {
                                  widget.onSendMessage();
                                } else {
                                  if (await _checkAudioPermission()) {
                                    widget.onStartRecording();
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Microphone permission required'),
                                      ),
                                    );
                                  }
                                }
                              }
                            : null, // Disable if not allowed
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
