import 'package:http/http.dart' as http;
import 'dart:convert';
import 'endpoints.dart'; // Import the file with API endpoints

class ApiService {
  // Helper function to handle API responses
  static dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load data: ${response.statusCode}');
    }
  }

  // POST request
  static Future<dynamic> post(
      String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // GET request
  static Future<dynamic> get(String endpoint) async {
    try {
      final response = await http.get(Uri.parse(endpoint));
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Signup request
  static Future<Map<String, dynamic>> signup(
      Map<String, dynamic> userData) async {
    try {
      final response = await http.post(
        Uri.parse(ApiEndpoints.signup), // Use the correct signup endpoint
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(userData),
      );

      if (response.statusCode == 200) {
        // If the server responds with a success code, decode and return the response body
        return jsonDecode(response.body);
      } else {
        // Print the error message if the response status is not 200
        print('Error: ${response.statusCode}');
        print('Error Body: ${response.body}');
        throw Exception('Failed to load data');
      }
    } catch (e) {
      // Catch any errors and log them for debugging
      print('Error during sign up: $e');
      throw Exception('Error during sign up: $e');
    }
  }

  static Future<Map<String, dynamic>> checkup(
      Map<String, dynamic> userData) async {
    final url = Uri.parse(
        ApiEndpoints.checkuser); // Ensure this path matches your Django URL

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode(userData), // userData should be directly encodable
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
            'Failed to check user: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error during user check: $e');
    }
  }

  // Login request
  static Future<Map<String, dynamic>> login(
      Map<String, dynamic> credentials) async {
    try {
      final response = await post(ApiEndpoints.login, credentials);
      // return response;
      return {
        'id': '1200',
        'name': 'wasswa viannie',
        'email': 'wasswaviannie@gmail.com',
        'phone_number': '1234567890',
        'is_verified': true, // Manually set this to false for testing
      };
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  // Verify OTP request
  static Future<Map<String, dynamic>> verifyOtp(
      Map<String, dynamic> otpData) async {
    try {
      final response = await post(ApiEndpoints.verifyOtp, otpData);
      return response;
    } catch (e) {
      throw Exception('OTP verification failed: $e');
    }
  }

  // Create group request
  static Future<Map<String, dynamic>> createGroup(
      Map<String, dynamic> groupData) async {
    try {
      final response = await post(ApiEndpoints.createGroup, groupData);
      return response;
    } catch (e) {
      throw Exception('Failed to create group: $e');
    }
  }

  // Join group request
  static Future<Map<String, dynamic>> joinGroup(
      Map<String, dynamic> joinData) async {
    try {
      final response = await post(ApiEndpoints.joinGroup, joinData);
      return response;
    } catch (e) {
      throw Exception('Failed to join group: $e');
    }
  }

  // Fetch groups request
  static Future<List<dynamic>> fetchGroups(String userId) async {
    try {
      final response = await get('${ApiEndpoints.fetchGroups}?user_id=$userId');
      return response;
    } catch (e) {
      throw Exception('Failed to fetch groups: $e');
    }
  }

  // Send message request
  static Future<Map<String, dynamic>> sendMessage(
      Map<String, dynamic> messageData) async {
    try {
      final response = await post(ApiEndpoints.sendMessage, messageData);
      return response;
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  // Fetch messages request
  static Future<List<dynamic>> fetchMessages(String groupId) async {
    try {
      final response =
          await get('${ApiEndpoints.fetchMessages}?group_id=$groupId');
      return response;
    } catch (e) {
      throw Exception('Failed to fetch messages: $e');
    }
  }

  // Update profile request
  static Future<Map<String, dynamic>> updateProfile(
      Map<String, dynamic> profileData) async {
    try {
      final response = await post(ApiEndpoints.updateProfile, profileData);
      return response;
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  // Fetch user details request
  static Future<Map<String, dynamic>> fetchUserDetails(String userId) async {
    try {
      final response =
          await get('${ApiEndpoints.fetchUserDetails}?user_id=$userId');
      return response;
    } catch (e) {
      throw Exception('Failed to fetch user details: $e');
    }
  }

  // Add more methods for other API calls as needed
}
