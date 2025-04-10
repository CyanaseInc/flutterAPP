import 'dart:convert';
import 'package:cyanase/helpers/web_db.dart';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  ChatScreenState createState() => ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> {
  String userToken = '';
  String username = '';
  WebSocketChannel? channel;
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];

  // Async function to get the token and username
  Future<void> getToken() async {
    await WebSharedStorage.init();
    var existingProfile = WebSharedStorage();
    var token = existingProfile.getCommon('token');
    var userName = existingProfile.getCommon('username');
    setState(() {
      userToken = token;
      username = userName;
    });

    print("Token Retrieved: $userToken");

    if (userToken.isNotEmpty && username.isNotEmpty) {
      _initializeWebSocket();
    }
  }

  // Initialize WebSocket when the token is available
  void _initializeWebSocket() {
    if (userToken.isNotEmpty && username.isNotEmpty) {
      print("Connecting to WebSocket with token: $userToken");

      channel = WebSocketChannel.connect(
        Uri.parse('ws://localhost:8000/ws/chat/private/1595/?token=$userToken'),
      );

      // Listen for messages from the WebSocket
      channel!.stream.listen((message) {
        // Only call setState if the widget is still mounted
        if (mounted) {
          var decodedMessage = json.decode(message);

          // Check if 'sender' matches 'username' and add message
          setState(() {
            _messages.add({
              'message': decodedMessage['message'],
              'sender': decodedMessage['sender'],
              'created': decodedMessage['created'],
            });
          });
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    getToken(); // Get the token asynchronously and then initialize WebSocket
  }

  @override
  void dispose() {
    if (channel != null) {
      channel!.sink.close(); // Close WebSocket if it's connected
    }
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (_controller.text.isNotEmpty && channel != null) {
      await WebSharedStorage.init();
      var existingProfile = WebSharedStorage();
      final userId = existingProfile.getCommon('user_id');
      channel!.sink
          .add(json.encode({'message': _controller.text, 'sender': userId}));
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('WebSocket Chat')),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                var message = _messages[index];
                bool isSender = message['sender'] == username;

                // Format the created timestamp
                DateTime createdAt = DateTime.parse(message['created']);
                String formattedTime =
                    '${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}';

                return Align(
                  alignment:
                      isSender ? Alignment.centerRight : Alignment.centerLeft,
                  child: Card(
                    margin:
                        const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    color: isSender ? Colors.blueAccent : Colors.grey[200],
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Sender's name
                          Text(
                            message['sender'], // Display sender's name
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isSender ? Colors.white : Colors.black,
                            ),
                          ),
                          SizedBox(height: 5),
                          // Message content
                          Text(
                            message['message'], // Display message content
                            style: TextStyle(
                              color: isSender ? Colors.white : Colors.black,
                            ),
                          ),
                          SizedBox(height: 5),
                          // Timestamp of message
                          Text(
                            formattedTime, // Display timestamp
                            style: TextStyle(
                              color: isSender ? Colors.white70 : Colors.black54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration:
                        const InputDecoration(hintText: 'Type a message'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
