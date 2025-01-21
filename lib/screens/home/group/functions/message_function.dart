import 'package:cyanase/helpers/database_helper.dart';
import 'dart:async'; // For StreamController and Timer

class MessageFunctions {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Fetch messages with pagination
  Future<List<Map<String, dynamic>>> getMessages(int? groupId,
      {int limit = 20, int offset = 0}) async {
    try {
      return await _dbHelper.getMessages(
        groupId: groupId, // Pass groupId as a named parameter
        limit: limit,
        offset: offset,
      );
    } catch (e) {
      print("Error fetching messages: $e");
      throw Exception("Failed to fetch messages");
    }
  }

  // Fetch messages as a Stream for real-time updates
  Stream<List<Map<String, dynamic>>> getMessagesStream({int? groupId}) {
    final controller = StreamController<List<Map<String, dynamic>>>();

    // Fetch initial messages
    () async {
      final messages = await _dbHelper.getMessages(groupId: groupId);
      final formattedMessages = messages.map((msg) {
        return {
          "id": msg['id'].toString(),
          "isMe": msg['sender_id'] == "current_user_id",
          "message": msg['message'],
          "time": msg['timestamp'],
          "replyTo": null,
          "isAudio": msg['type'] == 'audio',
        };
      }).toList();

      controller.add(formattedMessages);

      // Poll for updates (or use a better mechanism like triggers)
      Timer.periodic(Duration(seconds: 1), (timer) async {
        final updatedMessages = await _dbHelper.getMessages(groupId: groupId);
        final formattedUpdatedMessages = updatedMessages.map((msg) {
          return {
            "id": msg['id'].toString(),
            "isMe": msg['sender_id'] == "current_user_id",
            "message": msg['message'],
            "time": msg['timestamp'],
            "replyTo": null,
            "isAudio": msg['type'] == 'audio',
          };
        }).toList();

        controller.add(formattedUpdatedMessages);
      });
    }();

    return controller.stream;
  }

  // Fetch messages as a list (for one-time use)
  Future<List<Map<String, dynamic>>> loadMessages({int? groupId}) async {
    final messages = await _dbHelper.getMessages(groupId: groupId);
    return messages.map((msg) {
      return {
        "id": msg['id'].toString(),
        "isMe": msg['sender_id'] == "current_user_id",
        "message": msg['message'],
        "time": msg['timestamp'],
        "replyTo": null,
        "isAudio": msg['type'] == 'audio',
      };
    }).toList();
  }

  // Send a new message
  Future<Map<String, dynamic>> sendMessage({
    required String message,
    required int groupId, // Group ID is required
    required String senderId,
  }) async {
    try {
      // Validate the message content
      if (message.trim().isEmpty) {
        throw ArgumentError("Message cannot be empty");
      }

      // Create the message data
      final messageData = {
        "id": DateTime.now().millisecondsSinceEpoch, // Temporary ID
        "sender_id": senderId, // Use the provided senderId
        "message": message.trim(), // Trim whitespace
        "timestamp": DateTime.now().toIso8601String(), // Current timestamp
        "type": "text", // Message type
        "isMe": true, // Mark as sent by the current user
        "group_id": groupId.toString(), // Group ID for the message
      };

      // Insert the message into the database
      await _dbHelper.insertMessage(messageData);

      // Return the new message
      return messageData;
    } catch (e) {
      print("Error sending text message: $e");
      throw Exception("Failed to send text message: ${e.toString()}");
    }
  }

  // Delete a message
  Future<void> deleteMessage(int messageId) async {
    await _dbHelper.deleteMessage(messageId);
  }
}
