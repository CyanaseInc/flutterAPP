import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;
  static const String tableUsers = 'profile';
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
      version: 4, // Updated to version 4 for reply_to_message
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

  Future<void> clearDatabase() async {
    final dbPath = join(await getDatabasesPath(), 'app_database.db');
    await deleteDatabase(dbPath);

    _database = null;
  }

  // Create tables
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE profile (

        id TEXT PRIMARY KEY,
        token TEXT NOT NULL,
        name TEXT NOT NULL,
        profile_pic TEXT,
        phone_number TEXT,
        country TEXT,
        email TEXT,
        last_seen TEXT,
        status TEXT,
        auto_save BOOLEAN NOT NULL DEFAULT FALSE,
        goals_alert BOOLEAN NOT NULL DEFAULT FALSE,
        created_at TEXT NOT NULL,
        privacy_settings TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE groups (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amAdmin INTEGER,
        name TEXT NOT NULL,
        description TEXT,
        profile_pic TEXT,
        type TEXT NOT NULL,
        created_at TEXT NOT NULL,
        created_by TEXT NOT NULL,
        last_activity TEXT,
        settings TEXT
        requires_payment INTEGER,
        deposit_amount REAL,
        allows_subscription INTEGER,
        subscription_frequency TEXT,
        subscription_amount TEXT,
        has_user_paid INTEGER,
        restrict_messages_to_admins INTEGER
        
      )
    ''');

    await db.execute('''
      CREATE TABLE participants (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        is_admin BOOLEAN NOT NULL DEFAULT TRUE,
        is_approved BOOLEAN NOT NULL DEFAULT TRUE,
        is_denied BOOLEAN NOT NULL DEFAULT FALSE,
        is_removed INTEGER,
        user_name TEXT NOT NULL,
        group_id INTEGER NOT NULL,
        user_id TEXT NOT NULL,
        role TEXT NOT NULL,
        joined_at TEXT NOT NULL,
        muted BOOLEAN NOT NULL DEFAULT FALSE,
        FOREIGN KEY (group_id) REFERENCES groups (id) ON DELETE CASCADE
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
        isMe INTEGER NOT NULL DEFAULT 0,
        media_id INTEGER,
        type TEXT NOT NULL,
        status TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        reply_to_id INTEGER,
        reply_to_message TEXT,  -- Added for reply feature
        forwarded BOOLEAN NOT NULL DEFAULT FALSE,
        edited BOOLEAN NOT NULL DEFAULT FALSE,
        deleted BOOLEAN NOT NULL DEFAULT FALSE,
        FOREIGN KEY (group_id) REFERENCES groups (id) ON DELETE CASCADE,
        FOREIGN KEY (sender_id) REFERENCES profile(id) ON DELETE CASCADE,
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

    // Add indexes for performance
    await db
        .execute('CREATE INDEX idx_messages_group_id ON messages(group_id)');
    await db
        .execute('CREATE INDEX idx_messages_timestamp ON messages(timestamp)');
  }

  // Handle schema upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
          'ALTER TABLE messages ADD COLUMN isMe INTEGER NOT NULL DEFAULT 0');
    }

    if (oldVersion < 3) {
      await db.execute('ALTER TABLE media ADD COLUMN thumbnail_path TEXT');
    }

    if (oldVersion < 4) {
      await db.execute('ALTER TABLE messages ADD COLUMN reply_to_message TEXT');
    }
  }

  Future<int> insertUser(Map<String, dynamic> user) async {
    final db = await database;
    return await db.insert('profile', user);
  }

  Future<int> insertGroup(Map<String, dynamic> group) async {
    final db = await database;
    return await db.insert('groups', group);
  }

  Future<int> insertParticipant(Map<String, dynamic> participant) async {
    final db = await database;
    return await db.insert('participants', participant);
  }

  Future<int> insertMessage(Map<String, dynamic> message) async {
    final db = await database;

    // Ensure the timestamp and reply fields are set
    final Map<String, dynamic> messageWithDefaults = {
      ...message,
      'timestamp': message['timestamp'] ?? DateTime.now().toIso8601String(),
      'reply_to_id': message['reply_to_id'],
      'reply_to_message': message['reply_to_message'],
    };

    return await db.insert(
      'messages',
      messageWithDefaults,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> insertContact(Map<String, dynamic> contact) async {
    final db = await database;
    return await db.insert('contacts', contact);
  }

  Future<void> insertContacts(List<Map<String, dynamic>> contacts) async {
    final db = await database;
    for (var contact in contacts) {
      await db.insert(
        'contacts',
        {
          'id': contact['id'],
          'user_id': contact['id'] ?? 'unknown',
          'name': contact['name'],
          'phone_number': contact['phone'],
          'is_registered': contact['is_registered'] == true ? 1 : 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

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

  Future<int> insertImageMessage(Map<String, dynamic> message) async {
    final db = await database;
    return await db.insert(
      'messages',
      {
        'group_id': message['group_id'],
        'sender_id': message['sender_id'],
        'message': message['message'],
        'type': 'image',
        'timestamp': message['timestamp'] ?? DateTime.now().toIso8601String(),
        'media_id': message['media_id'],
        'status': message['status'] ?? 'sent',
        'isMe': message['isMe'] ?? 0,
        'reply_to_id': message['reply_to_id'],
        'reply_to_message': message['reply_to_message'],
      },
    );
  }

  Future<List<Map<String, dynamic>>> getContacts() async {
    final db = await database;
    return await db.query('contacts');
  }

  Future<List<Map<String, dynamic>>> getUsers() async {
    final db = await database;
    return await db.query('profile');
  }

  Future<List<Map<String, dynamic>>> getGroups() async {
    final db = await database;
    return await db.query('groups');
  }

  Future<List<Map<String, dynamic>>> getParticipants(int groupId) async {
    final db = await database;
    return await db
        .query('participants', where: 'group_id = ?', whereArgs: [groupId]);
  }

  Future<List<Map<String, dynamic>>> getMessages({
    int? groupId,
    int limit = 20,
    int offset = 0,
  }) async {
    final db = await database;
    final result = await db.query(
      'messages',
      where: groupId != null ? 'group_id = ? AND deleted = 0' : 'deleted = 0',
      whereArgs: groupId != null ? [groupId] : null,
      limit: limit,
      offset: offset,
      orderBy: 'timestamp DESC', // Changed to DESC for newest first
    );
    return result;
  }

  Future<Map<String, dynamic>?> getMedia(int mediaId) async {
    final db = await database;
    final media = await db.query(
      'media',
      where: 'id = ? AND deleted = 0',
      whereArgs: [mediaId],
    );
    return media.isNotEmpty ? media.first : null;
  }

  Future<List<Map<String, String>>> getGroupMemberNames(int groupId) async {
    final db = await database;
    final result = await db.rawQuery('''
    SELECT *
    FROM participants   
    WHERE  participants.group_id = ?
  ''', [groupId]);

    return result
        .map((row) => {
              'name': row['user_name'] as String,
              'role': row['role'] as String? ?? 'Member',
            })
        .toList();
  }

  Future<void> updateMemberRole(
      int groupId, String userId, String newRole) async {
    final db = await database;
    await db.update(
      'participants',
      {'role': newRole},
      where: 'group_id = ? AND user_id = ?',
      whereArgs: [groupId, userId],
    );
  }

  Future<int> insertNotification({
    required int groupId,
    required String message,
    String? senderId, // Optional, for cases like "Admin added X"
  }) async {
    final db = await database;
    final notification = {
      'group_id': groupId,
      'sender_id':
          senderId ?? 'system', // Use 'system' for automated notifications
      'message': message,
      'type': 'notification',
      'status': 'delivered',
      'timestamp': DateTime.now().toIso8601String(),
      'isMe': 0, // Notifications aren't "sent" by the user
      'reply_to_id': null,
      'reply_to_message': null,
    };
    return await db.insert(
      'messages',
      notification,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> deleteUser(String userId) async {
    final db = await database;
    return await db.delete('profile', where: 'id = ?', whereArgs: [userId]);
  }

  Future<int> removeMember(int groupID, String userId) async {
    final db = await database;
    return await db
        .delete('participants', where: 'id = ?', whereArgs: [userId]);
  }

  Future<int> deleteGroup(int groupId) async {
    final db = await database;
    return await db.delete('groups', where: 'id = ?', whereArgs: [groupId]);
  }

  Future<int> deleteParticipant(int participantId) async {
    final db = await database;
    return await db
        .delete('participants', where: 'id = ?', whereArgs: [participantId]);
  }

  Future<int> deleteMessage(int messageId) async {
    final db = await database;
    return await db.update(
      'messages',
      {'deleted': true},
      where: 'id = ?',
      whereArgs: [messageId],
    );
  }

  Future<int> clearMessages(int groupId) async {
    final db = await database;
    return await db.update(
      'messages',
      {'deleted': true},
      where: 'group_id = ?',
      whereArgs: [groupId],
    );
  }

  Future<List<Map<String, dynamic>>> getMediaForGroup(int groupId) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT media.* FROM media
      INNER JOIN messages ON media.id = messages.media_id
      WHERE messages.group_id = ? AND messages.deleted = 0 AND media.deleted = 0
    ''', [groupId]);
  }

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
