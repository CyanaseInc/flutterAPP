import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';

class ApiService {
  // Base URL for the REST API
  static const String _baseUrl = 'https://http://34.30.162.69:3000/api';

  // WebSocket URL
  static const String _webSocketUrl = 'wss://your-server.com/ws';

  // Headers for REST API requests
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
  };

  // WebSocket channel
  WebSocketChannel? _webSocketChannel;

  // Stream to listen to WebSocket messages
  Stream? get webSocketStream => _webSocketChannel?.stream;

  // Helper function to handle REST API responses
  static dynamic _handleResponse(http.Response response) {
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load data: ${response.statusCode}');
    }
  }

  // Connect to the WebSocket server
  void connectWebSocket() {
    try {
      _webSocketChannel = IOWebSocketChannel.connect(Uri.parse(_webSocketUrl));
      
    } catch (e) {
      throw Exception('Failed to connect to WebSocket: $e');
    }
  }

  // Disconnect from the WebSocket server
  void disconnectWebSocket() {
    _webSocketChannel?.sink.close();
    
  }

  // Send a message over WebSocket
  void sendWebSocketMessage(Map<String, dynamic> message) {
    if (_webSocketChannel == null) {
      throw Exception('WebSocket is not connected');
    }
    _webSocketChannel!.sink.add(jsonEncode(message));
  }

  // Upload an image to the server (REST API)
  static Future<String?> uploadImage(File imageFile) async {
    try {
      final uri = Uri.parse('$_baseUrl/upload-image');
      final request = http.MultipartRequest('POST', uri);
      request.files
          .add(await http.MultipartFile.fromPath('file', imageFile.path));

      final response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final jsonResponse = jsonDecode(responseData);
        return jsonResponse['imageUrl']; // Return the uploaded image URL
      } else {
        throw Exception('Failed to upload image: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error uploading image: $e');
    }
  }

  // Create a group on the server (REST API)
  static Future<bool> createGroup({
    required String groupName,
    required String? groupImageUrl,
    required List<String> participantIds,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/create-group');
      final response = await http.post(
        uri,
        headers: _headers,
        body: jsonEncode({
          'name': groupName,
          'profile_pic': groupImageUrl,
          'participants': participantIds,
          'created_by': 'current_user_id', // Replace with actual user ID
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Failed to create group: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating group: $e');
    }
  }

  // Send a message to the server (REST API)
  static Future<bool> sendMessage({
    required String groupId,
    required String senderId,
    required String message,
    required String type,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/send-message');
      final response = await http.post(
        uri,
        headers: _headers,
        body: jsonEncode({
          'group_id': groupId,
          'sender_id': senderId,
          'message': message,
          'type': type,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Failed to send message: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error sending message: $e');
    }
  }

  // Add a participant to a group (REST API)
  static Future<bool> addParticipant({
    required String groupId,
    required String userId,
    required String role,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/add-participant');
      final response = await http.post(
        uri,
        headers: _headers,
        body: jsonEncode({
          'group_id': groupId,
          'user_id': userId,
          'role': role,
          'joined_at': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Failed to add participant: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error adding participant: $e');
    }
  }

  // Fetch all groups for a user (REST API)
  static Future<List<dynamic>> fetchUserGroups(String userId) async {
    try {
      final uri = Uri.parse('$_baseUrl/user-groups?user_id=$userId');
      final response = await http.get(uri, headers: _headers);
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Error fetching user groups: $e');
    }
  }

  // Fetch all messages for a group (REST API)
  static Future<List<dynamic>> fetchGroupMessages(String groupId) async {
    try {
      final uri = Uri.parse('$_baseUrl/group-messages?group_id=$groupId');
      final response = await http.get(uri, headers: _headers);
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Error fetching group messages: $e');
    }
  }
}
