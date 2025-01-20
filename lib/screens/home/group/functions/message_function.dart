import 'package:cyanase/helpers/database_helper.dart';
import 'dart:async'; // For StreamController and Timer
import 'dart:io'; // For File

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

  // Send an audio message
  Future<void> sendAudioMessage({
    required String path,
    required int? groupId,
    required String senderId,
  }) async {
    try {
      // Check if the file exists
      final fileExists = await _checkFileExists(path);
      if (!fileExists) {
        print("Audio file does not exist at: $path");
        throw Exception("Audio file not found");
      }

      // Proceed with sending the audio file
      final mediaId = await _dbHelper.insertAudioFile(path);
      final message = {
        "group_id": groupId,
        "sender_id": senderId,
        "message": path,
        "type": "audio",
        "timestamp": DateTime.now().toIso8601String(),
        "media_id": mediaId,
        "status": "sent",
      };

      await _dbHelper.insertMessage(message);
    } catch (e) {
      print("Error sending audio message: $e");
      throw Exception("Failed to send audio message: ${e.toString()}");
    }
  }

  // Fetch messages as a Stream for real-time updates
  Stream<List<Map<String, dynamic>>> getMessagesStream({
    int? groupId,
    required String currentUserId,
  }) {
    final controller = StreamController<List<Map<String, dynamic>>>();

    // Fetch initial messages
    () async {
      try {
        final messages = await _dbHelper.getMessages(groupId: groupId);
        final formattedMessages = _formatMessages(messages, currentUserId);
        controller.add(formattedMessages);

        // Poll for updates (or use a better mechanism like triggers)
        Timer.periodic(Duration(seconds: 1), (timer) async {
          try {
            final updatedMessages =
                await _dbHelper.getMessages(groupId: groupId);
            final formattedUpdatedMessages =
                _formatMessages(updatedMessages, currentUserId);
            controller.add(formattedUpdatedMessages);
          } catch (e) {
            print("Error polling for messages: $e");
            controller.addError("Failed to fetch updated messages");
          }
        });
      } catch (e) {
        print("Error fetching initial messages: $e");
        controller.addError("Failed to fetch initial messages");
      }
    }();

    return controller.stream;
  }

  // Fetch messages as a list (for one-time use)
  Future<List<Map<String, dynamic>>> loadMessages({
    int? groupId,
    required String currentUserId,
  }) async {
    try {
      final messages = await _dbHelper.getMessages(groupId: groupId);
      return _formatMessages(messages, currentUserId);
    } catch (e) {
      print("Error loading messages: $e");
      throw Exception("Failed to load messages");
    }
  }

  // Send a new text message
  Future<void> sendMessage({
    required String message,
    required bool isGroup,
    required int? groupId,
    required String receiverId,
    required String senderId,
  }) async {
    try {
      // Validate the message content
      if (message.trim().isEmpty) {
        throw ArgumentError("Message cannot be empty");
      }

      // Ensure group_id is not null when isGroup is true
      if (isGroup && groupId == null) {
        throw ArgumentError("group_id cannot be null for group messages");
      }

      final messageData = {
        "sender_id": senderId, // Use the provided senderId
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
    } catch (e) {
      print("Error sending text message: $e");
      throw Exception("Failed to send text message: ${e.toString()}");
    }
  }

  // Delete a message
  Future<void> deleteMessage(int messageId) async {
    try {
      await _dbHelper.deleteMessage(messageId);
    } catch (e) {
      print("Error deleting message: $e");
      throw Exception("Failed to delete message");
    }
  }

  // Format messages into a consistent structure
  List<Map<String, dynamic>> _formatMessages(
    List<Map<String, dynamic>> messages,
    String currentUserId,
  ) {
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

  // Check if the file exists at the given path
  Future<bool> _checkFileExists(String path) async {
    try {
      final file = File(path);
      return await file.exists();
    } catch (e) {
      print("Error checking file existence: $e");
      return false;
    }
  }
}
