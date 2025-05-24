class ApiEndpoints {
  static const String myIp = '10.0.2.2:8000'; // For Android emulator
  // static const String myIp = 'localhost:8000'; // For iOS simulator

  static String get baseUrl => 'http://$myIp';

  // API endpoints
  static String get uploadFile => '$baseUrl/api/upload-file/';
  static String get messages => '$baseUrl/api/messages/';
  static String get groups => '$baseUrl/api/groups/';
  static String get users => '$baseUrl/api/users/';
}
