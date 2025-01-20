import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;
  static const String tableUsers = 'users';
  static const String tableGroups = 'groups';
  static const String tableParticipants = 'participants';
  static const String tableMedia = 'media';
  static const String tableMessages = 'messages';
  static const String tableContacts = 'contacts';

  // Singleton constructor
  DatabaseHelper._internal();

  factory DatabaseHelper() {
    return _instance;
  }

  // Initialize database
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Path and database initialization
  Future<Database> _initDatabase() async {
    // Request permissions for Android 10+
    await _requestPermissions();

    // Get the external storage directory
    final externalStorage = await getExternalStorageDirectory();
    if (externalStorage == null) {
      throw Exception('External storage not available');
    }

    // Define the app-specific folder path
    final appSpecificPath = Directory(
      '${externalStorage.path}/Android/data/com.cyanase.app/database',
    );

    // Create the directory if it doesn't exist
    if (!await appSpecificPath.exists()) {
      await appSpecificPath.create(recursive: true);
    }

    // Define the database path
    final dbPath = join(appSpecificPath.path, 'app_database.db');

    // Open the database
    return await openDatabase(
      dbPath,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // Request permissions
  Future<void> _requestPermissions() async {
    if (await Permission.storage.isDenied) {
      await Permission.storage.request();
    }
  }

  // Create tables
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        profile_pic TEXT,
        phone_number TEXT,
        last_seen TEXT,
        status TEXT,
        created_at TEXT NOT NULL,
        privacy_settings TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE groups (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        profile_pic TEXT,
        type TEXT NOT NULL,
        created_at TEXT NOT NULL,
        created_by TEXT NOT NULL,
        last_activity TEXT,
        settings TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE participants (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        group_id INTEGER NOT NULL,
        user_id TEXT NOT NULL,
        role TEXT NOT NULL,
        joined_at TEXT NOT NULL,
        muted BOOLEAN NOT NULL DEFAULT FALSE,
        FOREIGN KEY (group_id) REFERENCES groups (id) ON DELETE CASCADE,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE media (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        file_path TEXT NOT NULL UNIQUE,
        type TEXT NOT NULL,
        mime_type TEXT,
        file_size INTEGER,
        duration INTEGER,
        thumbnail_path TEXT,
        created_at TEXT NOT NULL,
        deleted BOOLEAN NOT NULL DEFAULT FALSE
      )
    ''');

    await db.execute('''
      CREATE TABLE messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        group_id INTEGER NOT NULL,
        sender_id TEXT NOT NULL,
        message TEXT,
        media_id INTEGER,
        type TEXT NOT NULL,
        status TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        reply_to_id INTEGER,
        forwarded BOOLEAN NOT NULL DEFAULT FALSE,
        edited BOOLEAN NOT NULL DEFAULT FALSE,
        deleted BOOLEAN NOT NULL DEFAULT FALSE,
        FOREIGN KEY (group_id) REFERENCES groups (id) ON DELETE CASCADE,
        FOREIGN KEY (sender_id) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (media_id) REFERENCES media (id) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE contacts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        name TEXT NOT NULL,
        phone_number TEXT NOT NULL UNIQUE,
        is_registered INTEGER NOT NULL DEFAULT 0,
        last_synced TEXT
      )
    ''');
  }

  // Handle schema upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE media (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          file_path TEXT NOT NULL UNIQUE,
          type TEXT NOT NULL,
          mime_type TEXT,
          file_size INTEGER,
          duration INTEGER,
          thumbnail_path TEXT,
          created_at TEXT NOT NULL,
          deleted BOOLEAN NOT NULL DEFAULT FALSE
        )
      ''');

      await db.execute('''
        CREATE TABLE messages (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          group_id INTEGER NOT NULL,
          sender_id TEXT NOT NULL,
          message TEXT,
          media_id INTEGER,
          type TEXT NOT NULL,
          status TEXT NOT NULL,
          timestamp TEXT NOT NULL,
          reply_to_id INTEGER,
          forwarded BOOLEAN NOT NULL DEFAULT FALSE,
          edited BOOLEAN NOT NULL DEFAULT FALSE,
          deleted BOOLEAN NOT NULL DEFAULT FALSE,
          FOREIGN KEY (group_id) REFERENCES groups (id) ON DELETE CASCADE,
          FOREIGN KEY (sender_id) REFERENCES users (id) ON DELETE CASCADE,
          FOREIGN KEY (media_id) REFERENCES media (id) ON DELETE SET NULL
        )
      ''');
    }
  }

  // Insert a user
  Future<int> insertUser(Map<String, dynamic> user) async {
    final db = await database;
    return await db.insert('users', user);
  }

  // Insert a group
  Future<int> insertGroup(Map<String, dynamic> group) async {
    final db = await database;
    return await db.insert('groups', group);
  }

  // Insert a participant
  Future<int> insertParticipant(Map<String, dynamic> participant) async {
    final db = await database;
    return await db.insert('participants', participant);
  }

  // Insert a message
  Future<int> insertMessage(Map<String, dynamic> message) async {
    final db = await database;

    // Ensure the timestamp is always set
    final Map<String, dynamic> messageWithTimestamp = {
      ...message,
      'timestamp': message['timestamp'] ?? DateTime.now().toIso8601String(),
    };

    // Insert the message into the database
    return await db.insert(
      'messages',
      messageWithTimestamp,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Insert a contact
  Future<int> insertContact(Map<String, dynamic> contact) async {
    final db = await database;
    return await db.insert('contacts', contact);
  }

  // Insert multiple contacts
  Future<void> insertContacts(List<Map<String, dynamic>> contacts) async {
    final db = await database;
    for (var contact in contacts) {
      await db.insert(
        'contacts',
        {
          'id': contact['id'], // Ensure the ID is an int
          'user_id':
              contact['id'] ?? 'unknown', // Provide a default value for user_id
          'name': contact['name'],
          'phone_number': contact['phone'],
          'is_registered':
              contact['is_registered'] == true ? 1 : 0, // Convert bool to int
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  // Insert an audio file
  Future<int> insertAudioFile(String filePath) async {
    final db = await database;
    return await db.insert(
      'media',
      {
        'file_path': filePath,
        'type': 'audio',
        'mime_type': 'audio/m4a',
        'file_size': await File(filePath).length(),
        'duration': 0,
        'thumbnail_path': null,
        'created_at': DateTime.now().toIso8601String(),
        'deleted': false,
      },
    );
  }

  // Insert an image file
  Future<int> insertImageFile(String filePath) async {
    final db = await database;
    return await db.insert(
      'media',
      {
        'file_path': filePath,
        'type': 'image',
        'mime_type': 'image/jpeg',
        'file_size': await File(filePath).length(),
        'duration': 0,
        'thumbnail_path': null,
        'created_at': DateTime.now().toIso8601String(),
        'deleted': false,
      },
    );
  }

  // Insert an image message
  Future<int> insertImageMessage(Map<String, dynamic> message) async {
    final db = await database;
    return await db.insert(
      'messages',
      {
        'group_id': message['group_id'],
        'sender_id': message['sender_id'],
        'message': message['message'],
        'type': 'image',
        'timestamp': message['timestamp'],
        'media_id': message['media_id'],
      },
    );
  }

  // Retrieve all contacts
  Future<List<Map<String, dynamic>>> getContacts() async {
    final db = await database;
    return await db.query('contacts');
  }

  // Retrieve all users
  Future<List<Map<String, dynamic>>> getUsers() async {
    final db = await database;
    return await db.query('users');
  }

  // Retrieve all groups
  Future<List<Map<String, dynamic>>> getGroups() async {
    final db = await database;
    return await db.query('groups');
  }

  // Retrieve all participants in a group
  Future<List<Map<String, dynamic>>> getParticipants(int groupId) async {
    final db = await database;
    return await db
        .query('participants', where: 'group_id = ?', whereArgs: [groupId]);
  }

  // Retrieve all messages in a group
  Future<List<Map<String, dynamic>>> getMessages({
    int? groupId, // Named parameter
    int limit = 20,
    int offset = 0,
  }) async {
    final db = await database;
    final result = await db.query(
      'messages',
      where: groupId != null ? 'group_id = ?' : null,
      whereArgs: groupId != null ? [groupId] : null,
      limit: limit,
      offset: offset,
    );
    return result;
  }

  // Retrieve a single media file by ID
  Future<Map<String, dynamic>?> getMedia(int mediaId) async {
    final db = await database;
    final media = await db.query(
      'media',
      where: 'id = ?',
      whereArgs: [mediaId],
    );
    return media.isNotEmpty ? media.first : null;
  }

  // Retrieve group member names
  Future<List<String>> getGroupMemberNames(int groupId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT contacts.name 
      FROM participants
      INNER JOIN contacts ON participants.user_id = contacts.user_id
      WHERE participants.group_id = ?
    ''', [groupId]);
    return result.map((row) => row['name'] as String).toList();
  }

  // Delete a user
  Future<int> deleteUser(String userId) async {
    final db = await database;
    return await db.delete('users', where: 'id = ?', whereArgs: [userId]);
  }

  // Delete a group
  Future<int> deleteGroup(int groupId) async {
    final db = await database;
    return await db.delete('groups', where: 'id = ?', whereArgs: [groupId]);
  }

  // Delete a participant
  Future<int> deleteParticipant(int participantId) async {
    final db = await database;
    return await db
        .delete('participants', where: 'id = ?', whereArgs: [participantId]);
  }

  // Delete a message
  Future<int> deleteMessage(int messageId) async {
    final db = await database;
    return await db.delete('messages', where: 'id = ?', whereArgs: [messageId]);
  }

  // Clear all messages in a group
  Future<int> clearMessages(int groupId) async {
    final db = await database;
    return await db
        .delete('messages', where: 'group_id = ?', whereArgs: [groupId]);
  }

  // Retrieve all media for a group
  Future<List<Map<String, dynamic>>> getMediaForGroup(int groupId) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT media.* FROM media
      INNER JOIN messages ON media.id = messages.media_id
      WHERE messages.group_id = ?
    ''', [groupId]);
  }

  // Delete media (soft delete)
  Future<int> deleteMedia(int mediaId) async {
    final db = await database;
    return await db.update(
      'media',
      {'deleted': true},
      where: 'id = ?',
      whereArgs: [mediaId],
    );
  }
}
