class ApiEndpoints {
  // Base URL
  static const String baseUrl = 'https://34.30.162.69:3000/api';

  // Authentication Endpoints
  static const String signup = '$baseUrl/signup';
  static const String login = '$baseUrl/login';
  static const String verifyOtp = '$baseUrl/verify-otp';

  // Group Endpoints
  static const String createGroup = '$baseUrl/create-group';
  static const String joinGroup = '$baseUrl/join-group';
  static const String fetchGroups = '$baseUrl/fetch-groups';

  // Message Endpoints
  static const String sendMessage = '$baseUrl/send-message';
  static const String fetchMessages = '$baseUrl/fetch-messages';

  // User Endpoints
  static const String updateProfile = '$baseUrl/update-profile';
  static const String fetchUserDetails = '$baseUrl/fetch-user-details';
}
