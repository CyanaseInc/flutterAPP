import 'dart:io';

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'endpoints.dart'; // Import the file with API endpoints
import 'package:http_parser/http_parser.dart';

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

  ////Send verification email

  static Future<Map<String, dynamic>> VerificationEmail(
      Map<String, dynamic> userData) async {
    final url = Uri.parse(
        ApiEndpoints.verifyOtp); // Ensure this path matches your Django URL

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
  } // Login request

  ////set the passcode
  static Future<Map<String, dynamic>> Setpasscode(
      Map<String, dynamic> userData) async {
    final url = Uri.parse(
        ApiEndpoints.passcode); // Ensure this path matches your Django URL

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

  static Future<Map<String, dynamic>> CheckResetPassword(
      Map<String, dynamic> userData) async {
    final url = Uri.parse(ApiEndpoints
        .checkPasswordEmail); // Ensure this path matches your Django URL

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

  static Future<Map<String, dynamic>> ResetPassword(
      Map<String, dynamic> userData, Map<String, dynamic> queryParams) async {
    final url = Uri.parse(ApiEndpoints
        .apiUrlPasswordReset); // Ensure this path matches your Django URL

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

  static Future<Map<String, dynamic>> login(
      Map<String, dynamic> credentials) async {
    try {
      final response = await post(ApiEndpoints.login, credentials);
      return response;
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  static Future<Map<String, dynamic>> passcodeLogin(
      Map<String, dynamic> credentials) async {
    try {
      final response = await post(ApiEndpoints.passcodeLogin, credentials);
      return response;
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  static Future<Map<String, dynamic>> subscriptionStatus(String token) async {
    try {
      // Define the URL
      final Uri url = Uri.parse(ApiEndpoints.apiUrlGetSubStatus);

      // Set the headers correctly
      final Map<String, String> headers = {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      };

      // Make a GET request (same as the working version)
      final http.Request request = http.Request('GET', url);
      request.headers.addAll(headers);

      // Send the request and get the response
      final http.StreamedResponse streamedResponse = await request.send();
      final http.Response response =
          await http.Response.fromStream(streamedResponse);

      // Check the response status
      if (response.statusCode == 200) {
        return jsonDecode(response.body); // Convert response to Map
      } else {
        throw Exception(
            'Failed to fetch subscription status: ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Error fetching subscription status: $e');
    }
  }

  static Future<Map<String, dynamic>> depositNetworth(String token) async {
    try {
      final response = await http.get(
        Uri.parse(ApiEndpoints.apiUrlGetDeposit),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
      );
      // Check the response status
      if (response.statusCode == 200) {
        return jsonDecode(response.body); // Convert response to Map
      } else {
        throw Exception(
            'Failed to fetch subscription status: ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Error fetching subscription status: $e');
    }
  }

  static Future<Map<String, dynamic>> userTrack(String token) async {
    try {
      final response = await http.get(
        Uri.parse(ApiEndpoints.apiUrlGetUserTrack),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
      );
      // Check the response status
      if (response.statusCode == 200) {
        return jsonDecode(response.body); // Convert response to Map
      } else {
        throw Exception(
            'Failed to fetch subscription status: ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Error fetching subscription status: $e');
    }
  }

  static Future<Map<String, dynamic>> withdraw(String token, data) async {
    try {
      final response = await http.post(
        Uri.parse(ApiEndpoints.apiUrlMmWithdraw),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(data), // Convert requestData to JSON
      );
      // Check the response status
      if (response.statusCode == 200) {
        return jsonDecode(response.body); // Convert response to Map
      } else {
        throw Exception(
            'Failed to fetch subscription status: ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Error fetching subscription status: $e');
    }
  }

  static Future<Map<String, dynamic>> uploadProfileImage(
      String token, File imageFile) async {
    try {
      final uri = Uri.parse(ApiEndpoints.apiUrlUserProfilePhoto);

      // Create a multipart request
      var request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Token $token';

      // Add the image file to the request
      var pic = await http.MultipartFile.fromPath(
        'profile_image', // This should be the field name that Django expects
        imageFile.path,
        contentType:
            MediaType('image', 'jpeg'), // or 'png' if the image is a PNG
      );
      request.files.add(pic);

      // Send the request
      var response = await request.send();

      // Check the response
      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        return jsonDecode(responseData);
      } else {
        throw Exception('Failed to upload image: ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Error uploading image: $e');
    }
  }

  static Future<Map<String, dynamic>> goalWithdraw(String token, data) async {
    try {
      final response = await http.post(
        Uri.parse(ApiEndpoints.apiUrlGoalMmWithdraw),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(data), // Convert requestData to JSON
      );
      // Check the response status
      if (response.statusCode == 200) {
        return jsonDecode(response.body); // Convert response to Map
      } else {
        throw Exception(
            'Failed to fetch subscription status: ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Error fetching subscription status: $e');
    }
  }

  static Future<Map<String, dynamic>> subscriptionPay(
      String token, String phone, String Currency) async {
    try {
      // Define the URL
      final Uri url = Uri.parse(ApiEndpoints.paySubscription);

      // Set the headers correctly
      final Map<String, String> headers = {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      };

      // Define the request body
      final Map<String, String> body = {'phone': phone, 'currency': Currency};

      // Make a POST request
      final http.Response response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body), // Convert body to JSON format
      );

      // Check the response status
      if (response.statusCode == 200) {
        return jsonDecode(response.body); // Convert response to Map
      } else {
        throw Exception('Failed to process payment: ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Error processing payment: $e');
    }
  }

  static Future<Map<String, dynamic>> CreateGoal(
      String token, Map<String, dynamic> data, image) async {
    try {
      final uri = Uri.parse(ApiEndpoints.apiUrlGoal);
      final request = http.MultipartRequest('POST', uri);

      // Add headers
      request.headers['Authorization'] = 'Token $token';
      request.headers['Content-Type'] = 'multipart/form-data';

      // Add form fields
      request.fields
          .addAll(data.map((key, value) => MapEntry(key, value.toString())));

      // Add image if provided
      if (image != null) {
        request.files.add(
          await http.MultipartFile.fromPath('goal_picture', image.path),
        );
      }

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      // Parse response
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return responseData; // { "message": ..., "success": ... }
      } else {
        throw Exception('Goal creation failed: ${responseData['message']}');
      }
    } catch (e) {
      throw Exception('Goal creation failed: $e');
    }
  }

  static Future<Map<String, dynamic>> EditGoal(
      String token, Map<String, dynamic> data, image) async {
    try {
      final uri = Uri.parse(ApiEndpoints.editGoal);
      final request = http.MultipartRequest('POST', uri);

      // Add headers
      request.headers['Authorization'] = 'Token $token';
      request.headers['Content-Type'] = 'multipart/form-data';

      // Add form fields
      request.fields
          .addAll(data.map((key, value) => MapEntry(key, value.toString())));

      // Add image if provided
      if (image != null) {
        request.files.add(
          await http.MultipartFile.fromPath('goal_picture', image.path),
        );
      }

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      // Parse response
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return responseData; // { "message": ..., "success": ... }
      } else {
        throw Exception('Goal creation failed: ${responseData['message']}');
      }
    } catch (e) {
      throw Exception('Goal creation failed: $e');
    }
  }

  static Future<Map<String, dynamic>> DeleteGoal(
      String token, Map<String, dynamic> data) async {
    try {
      final uri = Uri.parse(ApiEndpoints.deleteGoal);
      final request = http.MultipartRequest('POST', uri);

      // Add headers
      request.headers['Authorization'] = 'Token $token';
      request.headers['Content-Type'] = 'multipart/form-data';

      // Add form fields
      request.fields
          .addAll(data.map((key, value) => MapEntry(key, value.toString())));

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      // Parse response
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return responseData; // { "message": ..., "success": ... }
      } else {
        throw Exception('Goal creation failed: ${responseData['message']}');
      }
    } catch (e) {
      throw Exception('Goal creation failed: $e');
    }
  }

  static Future<Map<String, dynamic>> NewGroup(
    String token,
    Map<String, dynamic> data,
  ) async {
    try {
      final uri = Uri.parse(
          ApiEndpoints.newGroup); // e.g., 'https://your-api.com/groups/en/'
      final request = http.MultipartRequest('POST', uri);

      // Add headers
      request.headers['Authorization'] =
          'Token $token'; // Adjusted to 'Bearer' (common for JWT)

      // Extract fields from data
      final String name = data['name'] as String;
      final String description = data['description'] as String? ?? '';
      final String createdBy = data['created_by'] as String;
      final List<Map<String, dynamic>> participants =
          List<Map<String, dynamic>>.from(data['participants'] ?? []);
      final String? profilePicPath = data['profile_pic'] as String?;

      // Add text fields (excluding participants and profile_pic for now)
      request.fields['name'] = name;
      request.fields['description'] = description;
      request.fields['created_by'] = createdBy;

      // Add participants as a JSON-encoded string
      request.fields['participants'] = jsonEncode(participants);

      // Add profile picture file if provided
      if (profilePicPath != null && profilePicPath.isNotEmpty) {
        final file = File(profilePicPath);
        if (await file.exists()) {
          request.files.add(
            await http.MultipartFile.fromPath('profile_pic', profilePicPath),
          );
        } else {
          throw Exception('Profile picture file not found at: $profilePicPath');
        }
      }

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      // Parse response
      final responseData = jsonDecode(response.body) as Map<String, dynamic>;

      // Handle response based on status code
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (responseData['success'] == true) {
          return responseData; // Expected: { "message": ..., "success": true, "groupId": ... }
        } else {
          throw Exception(
              'Group creation failed: ${responseData['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception(
            'Group creation failed: ${response.statusCode} - ${responseData['message'] ?? response.body}');
      }
    } catch (e) {
      print('Error in NewGroup: $e'); // Log error for debugging
      rethrow; // Rethrow to allow caller to handle the exception
    }
  }

  static Future<Map<String, dynamic>> EditGroup(
    String token,
    Map<String, dynamic> data,
  ) async {
    try {
      final uri = Uri.parse(ApiEndpoints.editGroup);
      final request = http.MultipartRequest('POST', uri);

      // Add headers
      request.headers['Authorization'] =
          'Token $token'; // Adjusted to 'Bearer' (common for JWT)

      // Extract fields from data
      final String name = data['name'] as String;
      final String description = data['description'] as String? ?? '';
      final String groupId = data['groupid'] as String? ?? '';
      // Add text fields (excluding participants and profile_pic for now)
      request.fields['name'] = name;
      request.fields['description'] = description;
      request.fields['groupid'] = groupId;
      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      // Parse response
      final responseData = jsonDecode(response.body) as Map<String, dynamic>;

      // Handle response based on status code
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (responseData['success'] == true) {
          return responseData; // Expected: { "message": ..., "success": true, "groupId": ... }
        } else {
          throw Exception(
              'Group creation failed: ${responseData['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception(
            'Group creation failed: ${response.statusCode} - ${responseData['message'] ?? response.body}');
      }
    } catch (e) {
      rethrow; // Rethrow to allow caller to handle the exception
    }
  }

  static Future<Map<String, dynamic>> addMembers(
      String token, Map<String, dynamic> data) async {
    try {
      const String addMembersEndpoint =
          ApiEndpoints.addMembers; // Adjust to your endpoint
      final uri = Uri.parse(addMembersEndpoint);
      final request = http.MultipartRequest('POST', uri);

      // Add headers
      request.headers['Authorization'] = 'Token $token';

      // Add fields
      request.fields['groupid'] = data['groupid'];
      request.fields['participants'] = jsonEncode(data['participants']);

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      // Parse response
      final responseData = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (responseData['success'] == true) {
          return responseData;
        } else {
          throw Exception(
              'Failed to add members: ${responseData['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception(
            'Failed to add members: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> submitRiskProfile(
      String token, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse(ApiEndpoints.apiUrlAddAuthUserRiskProfile),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to submit risk profile: ${response.statusCode}');
    }
  }

  static Future<List<Map<String, dynamic>>> getClasses(String token) async {
    final response = await http.get(
      Uri.parse(ApiEndpoints.apiUrlGetInvestmentClasses),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      // Decode the JSON response into a List<Map<String, dynamic>>
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception(
          'Failed to fetch investment classes: ${response.statusCode}');
    }
  }

  static Future<List<Map<String, dynamic>>> getGroup(String token) async {
    final response = await http.post(
      Uri.parse(ApiEndpoints.getGroup),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      // Decode the JSON response into a Map<String, dynamic>
      final Map<String, dynamic> responseBody = jsonDecode(response.body);

      // Check if the response contains a list of groups under a specific key (e.g., 'groups')
      if (responseBody.containsKey('groups') &&
          responseBody['groups'] is List) {
        // Return the list of groups
        return List<Map<String, dynamic>>.from(responseBody['groups']);
      } else {
        // If the response is a single group, wrap it in a list
        return [responseBody];
      }
    } else {
      throw Exception('Failed to fetch groups ${response.statusCode}');
    }
  }

  static Future<Map<String, dynamic>> getAllUserGoals(String token) async {
    final response = await http.get(
      Uri.parse(ApiEndpoints.apiUrlGetGoal),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      // Decode the JSON response into a List<Map<String, dynamic>>
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch goals: ${response.statusCode}');
    }
  }

  static Future<Map<String, dynamic>> validatePhone(
      String token, Map<String, dynamic> phone) async {
    final response = await http.post(
      Uri.parse(ApiEndpoints.validatePhone), // Replace with your API endpoint
      headers: {
        'Authorization': 'Token $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(phone), // Convert requestData to JSON
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to validate phone: ${response.statusCode}');
    } else {
      return jsonDecode(response.body);
    }
  }

  static Future<Map<String, dynamic>> requestPayment(
      String token, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse(ApiEndpoints.requestPayment), // Replace with your API endpoint
      headers: {
        'Authorization': 'Token $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data), // Convert requestData to JSON
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to submit deposit: ${response.statusCode}');
    } else {
      return jsonDecode(response.body);
    }
  }

  static Future<Map<String, dynamic>> getTransaction(
      String token, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse(ApiEndpoints.getTransaction), // Replace with your API endpoint
      headers: {
        'Authorization': 'Token $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data), // Convert requestData to JSON
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to submit deposit: ${response.statusCode}');
    } else {
      return jsonDecode(response.body);
    }
  }

  static Future<Map<String, dynamic>> investDeposit(
      String token, Map<String, dynamic> requestData) async {
    final response = await http.post(
      Uri.parse(ApiEndpoints.apiUrlDeposit), // Replace with your API endpoint
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(requestData), // Convert requestData to JSON
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to submit deposit: ${response.statusCode}');
    } else {
      return jsonDecode(response.body);
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
