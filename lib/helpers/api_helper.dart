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

  static Future<Map<String, dynamic>> verifyPasscode(
      String token, Map<String, dynamic> userData) async {
    final url = Uri.parse(ApiEndpoints
        .verifyPasscode); // Ensure this path matches your Django URL

    try {
      final response = await http.post(
        url,
        headers: {
          "Authorization": "Token $token",
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

  static Future<Map<String, dynamic>> saveNextOfKin(
      String token, Map<String, dynamic> userData) async {
    final url = Uri.parse(ApiEndpoints
        .apiUrlUserNextOfKin); // Ensure this path matches your Django URL

    try {
      final response = await http.post(
        url,
        headers: {
          "Authorization": "Token $token",
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
      Map<String, dynamic> userData) async {
    final url = Uri.parse(ApiEndpoints
        .apiUrlPasswordReset); // Ensure this path matches your Django URL
    print('userData $userData');
    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode(userData), // userData should be directly encodable
      );
      print('response.body ${response.body}');
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

  static Future<Map<String, dynamic>> changeUserPassword(
      String token, Map<String, dynamic> userData) async {
    final url = Uri.parse(ApiEndpoints
        .changeUserPassword); // Ensure this path matches your Django URL

    try {
      final response = await http.post(
        url,
        headers: {
          "Authorization": "Token $token",
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

      return response as Map<String, dynamic>;
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
        throw Exception('Failed to fetch deposit: ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Error fetching deposit: $e');
    }
  }

  static Future<Map<String, dynamic>> getGroupDetails({
    required String token,
    required int groupId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiEndpoints.apiUrlGetGroupDetails),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'groupid': groupId,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        final data = responseData as Map<String, dynamic>;

        return data; // Return the 'data' portion of the response
      } else {
        throw Exception(
            'Failed to fetch group details: ${response.statusCode} - ${response.body}');
      }
    } on http.ClientException catch (e) {
      throw Exception('Network error: $e');
    } on FormatException catch (e) {
      throw Exception('Invalid JSON format: $e');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  static Future<Map<String, dynamic>> getGroupStat({
    required String token,
    required int groupId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiEndpoints.apiUrlGetGroupStat),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'groupid': groupId,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        return responseData;
      } else {
        throw Exception(
            'Failed to fetch group details: ${response.statusCode} - ${response.body}');
      }
    } on http.ClientException catch (e) {
      throw Exception('Network error: $e');
    } on FormatException catch (e) {
      throw Exception('Invalid JSON format: $e');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  static Future<Map<String, dynamic>> getGroupFinance({
    required String token,
    required int groupId,
  }) async {
    final response = await http.get(
      Uri.parse(''),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load group finance data: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> addInvestment({
    required String token,
    required int groupId,
    required Map<String, dynamic> data,
  }) async {
    final response = await http.post(
      Uri.parse(ApiEndpoints.addInvestmentUrl),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to add investment: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> addInvestmentInterest({
    required String token,
    required int investmentId,
    required Map<String, dynamic> data,
    String? password,
  }) async {
    // Create the complete request body
    final requestBody = {
      'investment_id': investmentId,
      ...data, // Spread the existing data
      if (password != null) 'password': password, // Conditionally add password
    };

    try {
      final response = await http.post(
        Uri.parse(ApiEndpoints.addInterestUrl),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to add interest: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> deleteInvestment(
      {required String token,
      required int investmentId,
      required String password}) async {
    final response = await http.post(Uri.parse(ApiEndpoints.cashOut),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'investment_id': investmentId,
          'password': password,
        }));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to cash out: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> payoutInterest({
    required String token,
    required int groupId,
    required double amount,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse(ApiEndpoints.payOutUrl),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'groupid': groupId,
        'amount': amount,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print('response.body ${response.body}');
      throw Exception('Failed to payout interest: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> getGroupDetailsNonUser({
    required String token,
    required int groupId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiEndpoints.apiUrlGetGroupDetailsNonUser),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'groupid': groupId,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        final data = responseData as Map<String, dynamic>;

        return data; // Return the 'data' portion of the response
      } else {
        throw Exception(
            'Failed to fetch group details: ${response.statusCode} - ${response.body}');
      }
    } on http.ClientException catch (e) {
      throw Exception('Network error: $e');
    } on FormatException catch (e) {
      throw Exception('Invalid JSON format: $e');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  static Future<dynamic> userTrack(String token) async {
    try {
      final response = await http.get(
        Uri.parse(ApiEndpoints.apiUrlGetUserTrack),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final decodedResponse = jsonDecode(response.body);
        // Normalize the response to always return a Map with a 'data' field
        if (decodedResponse is List<dynamic>) {
          return {
            'success': true,
            'data': decodedResponse,
          };
        } else if (decodedResponse is Map<String, dynamic>) {
          return decodedResponse;
        } else {
          throw Exception(
              'Unexpected response format: ${decodedResponse.runtimeType}');
        }
      } else {
        throw Exception('Failed to fetch user track: ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Error fetching user track: $e');
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
        throw Exception('Failed to fetch withdraws: ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Error fetching withdraws: $e');
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
      print('respons vvvvvve: $response.body');
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
      String token, data) async {
    try {
      final response = await http.post(
        Uri.parse(ApiEndpoints.paySubscription),
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
        throw Exception('Failed to subscribe: ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Error with subscription: $e');
    }
  }

  static Future<Map<String, dynamic>> groupSbscription(
      String token, data) async {
    try {
      final response = await http.post(
        Uri.parse(ApiEndpoints.payGroupSubscription),
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
        throw Exception('Failed to subscribe: ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Error with subscription: $e');
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

  static Future<Map<String, dynamic>> CreateGroupGoal(
      String token, Map<String, dynamic> data, image) async {
    try {
      final uri = Uri.parse(ApiEndpoints.apiUrlGroupGoal);
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

  static Future<Map<String, dynamic>> EditGroupGoal(
      String token, Map<String, dynamic> data) async {
    try {
      final uri = Uri.parse(ApiEndpoints.editGroupGoal);
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

  static Future<Map<String, dynamic>> DeleteGroupGoal(
      String token, Map<String, dynamic> data) async {
    try {
      final uri = Uri.parse(ApiEndpoints.deleteGroupGoal);
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
      final uri = Uri.parse(ApiEndpoints.newGroup);
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
      return responseData;
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> groupSettings(
      String token, Map<String, dynamic> data) async {
    try {
      final uri = Uri.parse(ApiEndpoints.loanSettingUrl);

      // Option 1: Send as application/x-www-form-urlencoded
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'groupid': data['groupId'],
          'data': data['setting'], // Already JSON-encoded in _updateSettings
        },
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        return responseData;
      } else {
        print('Failed to update loan settings: ${response.body}');
        throw Exception('Failed to update loan settings: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> approveRequest(
      String token, Map<String, dynamic> data) async {
    try {
      const String approve =
          ApiEndpoints.approveRequest; // Adjust to your endpoint
      final uri = Uri.parse(approve);
      final request = http.MultipartRequest('POST', uri);

      // Add headers
      request.headers['Authorization'] = 'Token $token';

      // Add fields
      request.fields['groupid'] = data['groupid'];
      request.fields['participants'] = jsonEncode(data);

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      // Parse response
      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      return responseData;
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> updateMemberRole(
      {required String token,
      required int groupId,
      required String role,
      required String userId}) async {
    try {
      final uri = Uri.parse(ApiEndpoints.memberRolesUrl);
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'role': role, 'groupId': groupId, 'user_id': userId}),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to update role: ${response.body}');
      }
    } catch (e) {
      print('Error updating role: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> removeMember({
    required String token,
    required int groupId,
    required String userId,
  }) async {
    try {
      final uri = Uri.parse(
          'https://your-api-url/api/groups/$groupId/members/$userId/');
      final response = await http.delete(
        uri,
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to remove member: ${response.body}');
      }
    } catch (e) {
      print('Error removing member: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> denyRequest(
      String token, Map<String, dynamic> data) async {
    try {
      const String deny = ApiEndpoints.denyRequest; // Adjust to your endpoint
      final uri = Uri.parse(deny);
      final request = http.MultipartRequest('POST', uri);

      // Add headers
      request.headers['Authorization'] = 'Token $token';

      // Add fields
      request.fields['groupid'] = data['groupid'];
      request.fields['participants'] = jsonEncode(data);

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      // Parse response
      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      return responseData;
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> updateGroupProfilePic({
    required String token,
    required int groupId,
    required File imageFile,
  }) async {
    try {
      final uri = Uri.parse(ApiEndpoints.changeGroupPic); // Adjust endpoint
      final request = http.MultipartRequest('POST', uri);

      // Add headers
      request.headers['Authorization'] = 'Token $token';

      // Add groupId to the request body as a field
      request.fields['group_id'] = groupId.toString();

      // Add the profile picture file
      if (await imageFile.exists()) {
        request.files.add(
          await http.MultipartFile.fromPath('profile_pic', imageFile.path),
        );
      } else {
        throw Exception('Profile picture file not found at: ${imageFile.path}');
      }

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      // Parse response
      final responseData = jsonDecode(response.body) as Map<String, dynamic>;

      // Handle response based on status code
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (responseData['success'] == true) {
          return responseData;
        } else {
          throw Exception(
              'Profile picture update failed: ${responseData['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception(
            'Profile picture update failed: ${response.statusCode} - ${responseData['message'] ?? response.body}');
      }
    } catch (e) {
      print('Error in updateGroupProfilePic: $e');
      rethrow;
    }
  }

  // Delete group profile picture
  static Future<Map<String, dynamic>> deleteGroupProfilePic({
    required String token,
    required int groupId,
  }) async {
    final response = await http.post(
      Uri.parse(ApiEndpoints.deleteGroupPic),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'group_id': groupId}),
    );

    final responseData = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return {
        'success': true,
        'message': responseData['message'] ?? 'Picture deleted successfully',
      };
    } else {
      throw Exception(
          responseData['message'] ?? 'Failed to delete profile picture');
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

  static Future<Map<String, dynamic>> getGroup(String token) async {
    final response = await http.post(
      Uri.parse(ApiEndpoints.getGroup),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({}), // Add empty JSON body
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to fetch groups: ${response.statusCode}');
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

  static Future<Map<String, dynamic>> withdrawRequest(
      String token, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse(ApiEndpoints.withdrawPayment), // Replace with your API endpoint
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

  static Future<Map<String, dynamic>> addInterest(
      String token, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse(ApiEndpoints.addInterestUrl), // Replace with your API endpoint
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

  static Future<Map<String, dynamic>> userWithdrawRequest(
      String token, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse(
          ApiEndpoints.userWithdrawPayment), // Replace with your API endpoint
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

  static Future<Map<String, dynamic>> groupSubscriptionWithdraw(
      String token, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse(ApiEndpoints
          .groupSubscriptionWithdraw), // Replace with your API endpoint
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

  static Future<Map<String, dynamic>> groupGoalWithdraw(
      String token, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse(
          ApiEndpoints.goalWithdrawPayment), // Replace with your API endpoint
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

  static Future<Map<String, dynamic>> PayToJoinGroup(
      String token, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse(ApiEndpoints.payTojoin), // Replace with your API endpoint
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

  static Future<Map<String, dynamic>> SubscriptionSetting(
      String token, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse(
          ApiEndpoints.SubscriptionSetting), // Replace with your API endpoint
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

  static Future<Map<String, dynamic>> PaySubscriptions(
      String token, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse(ApiEndpoints.paySubscription), // Replace with your API endpoint
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

  static Future<Map<String, dynamic>> submitLoanApplication(
      String token, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse(ApiEndpoints.loanApplication), // Replace with your API endpoint
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

  static Future<Map<String, dynamic>> processLoanRequest({
    required String token,
    required int loanId,
    required int groupId,
    required bool approved,
  }) async {
    try {
    final response = await http.post(
      Uri.parse(ApiEndpoints.processLoanRequest),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
        body: jsonEncode({
          'group_id': groupId,
          'loan_id': loanId,
          'approved': approved
        }),
    );

      print('API Response Status: ${response.statusCode}');
      print('API Response Body: ${response.body}');

    final responseData = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return {
        'success': true,
          'message': responseData['message'] ?? 'Loan processed successfully',
          'loan_status': responseData['loan_status'] ?? 'processed'
      };
    } else {
        throw Exception(responseData['message'] ?? 'Failed to process loan request');
      }
    } catch (e) {
      print('API Error: $e');
      throw Exception('Failed to process loan: $e');
    }
  }

  static Future<Map<String, dynamic>> processWithdrawRequest({
    required String token,
    required int withdrawId,
    required int groupId,
    required bool approved,
  }) async {
    // Replace with actual API call
    final response = await http.post(
      Uri.parse(ApiEndpoints.processWithdrawRequest),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'group_id': groupId,
        'withdraw_id': withdrawId,
        'approved': approved
      }),
    );

    final responseData = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return {
        'success': true,
        'message': responseData['message'] ?? 'Picture deleted successfully',
      };
    } else {
      throw Exception(
          responseData['message'] ?? 'Failed to delete profile picture');
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

  static Future<Map<String, dynamic>> groupDeposit(
      String token, Map<String, dynamic> requestData) async {
    final response = await http.post(
      Uri.parse(ApiEndpoints.groupDeposit), // Replace with your API endpoint
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

  static Future<Map<String, dynamic>> payLoan(
      String token, Map<String, dynamic> requestData) async {
    final response = await http.post(
      Uri.parse(ApiEndpoints.payLoan),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(requestData),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to submit deposit: ${response.statusCode}');
    } else {
      final decodedResponse = jsonDecode(response.body);

      return decodedResponse; // This may cause the error if decodedResponse is a List
    }
  }

  static Future<Map<String, dynamic>> groupTopUp(
      String token, Map<String, dynamic> requestData) async {
    final response = await http.post(
      Uri.parse(ApiEndpoints.groupTopup),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(requestData),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to submit deposit: ${response.statusCode}');
    } else {
      final decodedResponse = jsonDecode(response.body);

      return decodedResponse; // This may cause the error if decodedResponse is a List
    }
  }

  static Future<Map<String, dynamic>> goalContribute(
      String token, Map<String, dynamic> requestData) async {
    final response = await http.post(
      Uri.parse(ApiEndpoints.goalContribute), // Replace with your API endpoint
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

  static Future<Map<String, dynamic>> withdrawFromGroup({
    required String token,
    required int groupId,
    required double amount,
    required String password,
    required String withdrawMethod,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiEndpoints.withdrawFromGroup),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'group_id': groupId,
          'amount': amount,
          'password': password,
          'withdraw_method': withdrawMethod,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
            'Failed to process withdrawal: ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Error processing withdrawal: $e');
    }
  }

  static Future<Map<String, dynamic>> getNextOfKin(String token) async {
    final url = Uri.parse(ApiEndpoints.apiUrlGetNextOfKin);
    try {
      final response = await http.get(
        url,
        headers: {
          "Authorization": "Token $token",
          "Content-Type": "application/json",
        },
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
            'Failed to fetch next of kin: \\${response.statusCode} - \\${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching next of kin: $e');
    }
  }

  static Future<Map<String, dynamic>> updateNotificationSettings(
    String token,
    Map<String, dynamic> settings,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(ApiEndpoints.apiUrlUpdateNotificationSettings),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(settings),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to update notification settings');
      }
    } catch (e) {
      throw Exception('Error updating notification settings: $e');
    }
  }

  // Add more methods for other API calls as needed
}
