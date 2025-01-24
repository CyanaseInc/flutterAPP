import 'package:flutter/material.dart';
import 'package:record/record.dart';
import './functions/audio_function.dart';
import './functions/image_functions.dart';
import 'package:cyanase/theme/theme.dart';

class InputArea extends StatefulWidget {
  final TextEditingController controller;
  final bool isRecording;
  final Duration recordingDuration;
  final Function() onSendMessage;
  final Function() onStartRecording;
  final Function() onStopRecording;
  final Function() onCancelRecording;
  final Function(String) onSendImageMessage;
  final Function(String) onSendAudioMessage;
  final String? replyingToMessage;
  final Function() onCancelReply;
  final AudioFunctions audioFunctions;
  const InputArea({
    Key? key,
    required this.controller,
    required this.isRecording,
    required this.recordingDuration,
    required this.onSendMessage,
    required this.onStartRecording,
    required this.onStopRecording,
    required this.onCancelRecording,
    required this.onSendImageMessage,
    required this.onSendAudioMessage,
    this.replyingToMessage,
    required this.onCancelReply,
    required this.audioFunctions,
  }) : super(key: key);

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

  @override
  Widget build(BuildContext context) {
    return Container(
      color: white,
      padding: EdgeInsets.all(8),
      child: Column(
        children: [
          if (widget.replyingToMessage != null)
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.reply, color: primaryColor),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.replyingToMessage!,
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: primaryColor),
                    onPressed: widget.onCancelReply,
                  ),
                ],
              ),
            ),
          Row(
            children: [
              if (widget.isRecording)
                Expanded(
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: widget.onCancelRecording,
                      ),
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.mic, color: Colors.red),
                              SizedBox(width: 8),
                              Text(
                                "Slide to cancel",
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontSize: 14,
                                ),
                              ),
                              Spacer(),
                              Text(
                                "${widget.recordingDuration.inSeconds}s",
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
              IconButton(
                icon: Icon(Icons.image, color: primaryColor),
                onPressed: () async {
                  final imageFile =
                      await ImageFunctions().pickImageFromGallery();
                  if (imageFile != null) {
                    final imagePath =
                        await ImageFunctions().saveImageToStorage(imageFile);
                    widget.onSendImageMessage(imagePath);
                  }
                },
              ),
              SizedBox(width: 8),
              IconButton(
                icon: Icon(
                  widget.isRecording
                      ? Icons.stop
                      : _isTyping
                          ? Icons.send
                          : Icons.mic,
                  color: widget.isRecording ? Colors.red : primaryColor,
                ),
                onPressed: () async {
                  if (widget.isRecording) {
                    // Stop recording and send the audio message
                    await widget.onStopRecording();
                  } else if (_isTyping) {
                    widget.onSendMessage();
                  } else {
                    widget.onStartRecording();
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
