import 'package:cyanase/helpers/database_helper.dart';

class MessageFunctions {
  final DatabaseHelper _dbHelper = DatabaseHelper();

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

  Future<void> sendMessage({
    required String message,
    required bool isGroup,
    required int? groupId,
    required String receiverId,
  }) async {
    // Validate the message content
    if (message.trim().isEmpty) {
      throw ArgumentError("Message cannot be empty");
    }

    // Ensure group_id is not null when isGroup is true
    if (isGroup && groupId == null) {
      throw ArgumentError("group_id cannot be null for group messages");
    }

    final messageData = {
      "sender_id": "current_user_id", // Replace with actual user ID
      "message": message.trim(), // Trim whitespace
      "timestamp": DateTime.now().toIso8601String(), // Current timestamp
      "type": "text", // Message type
    };

    // Add group_id or receiver_id based on the message type
    if (isGroup) {
      messageData['group_id'] = groupId.toString(); // Convert to String
    } else {
      messageData['receiver_id'] =
          receiverId; // Receiver ID for direct messages
    }

    // Insert the message into the database
    await _dbHelper.insertMessage(messageData);
  }

  Future<void> deleteMessage(int messageId) async {
    await _dbHelper.deleteMessage(messageId);
  }
}
