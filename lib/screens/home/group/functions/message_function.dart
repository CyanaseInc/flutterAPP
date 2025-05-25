import 'package:cyanase/helpers/database_helper.dart';
import 'dart:async'; // For StreamController and Timer

class MessageFunctions {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Get current user ID from profile table
  Future<String?> _getCurrentUserId() async {
    try {
      final db = await _dbHelper.database;
      final userProfile = await db.query('profile', limit: 1);
      if (userProfile.isNotEmpty) {
        return userProfile.first['user_id'] as String?;
      }
      return null;
    } catch (e) {
      print("Error getting current user ID: $e");
      return null;
    }
  }

  // Fetch messages with pagination
  Future<List<Map<String, dynamic>>> getMessages(int? groupId,
      {int limit = 20, int offset = 0}) async {
    try {
      final currentUserId = await _getCurrentUserId();
      final messages = await _dbHelper.getMessages(
        groupId: groupId,
        limit: limit,
        offset: offset,
      );

      return messages.map((msg) {
        return {
          ...msg,
          "isMe": msg['sender_id'] == currentUserId,
          "isReply": msg['reply_to_id'] != null,
          "replyTo": msg['reply_to_id'] != null
              ? {
                  "id": msg['reply_to_id'],
                  "message": msg['reply_to_message'],
                }
              : null,
        };
      }).toList();
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
      final currentUserId = await _getCurrentUserId();
      final messages = await _dbHelper.getMessages(groupId: groupId);
      final formattedMessages = messages.map((msg) {
        return {
          "id": msg['id'].toString(),
          "isMe": msg['sender_id'] == currentUserId,
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
            "isMe": msg['sender_id'] == currentUserId,
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
    final currentUserId = await _getCurrentUserId();
    final messages = await _dbHelper.getMessages(groupId: groupId);
    return messages.map((msg) {
      return {
        "id": msg['id'].toString(),
        "isMe": msg['sender_id'] == currentUserId,
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
    required int groupId,
    required String senderId,
  }) async {
    try {
      // Validate the message content
      if (message.trim().isEmpty) {
        throw ArgumentError("Message cannot be empty");
      }

      // Create the message data
      final messageData = {
        "id": DateTime.now().millisecondsSinceEpoch,
        "sender_id": senderId,
        "message": message.trim(),
        "timestamp": DateTime.now().toIso8601String(),
        "type": "text",
        "isMe": true,
        "group_id": groupId.toString(),
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
