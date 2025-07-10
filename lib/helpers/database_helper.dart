import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
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

  // StreamController for broadcasting message updates
  final StreamController<Map<int, List<Map<String, dynamic>>>> _messageStreamController =
      StreamController.broadcast();

  // Stream of messages, keyed by groupId
  Stream<Map<int, List<Map<String, dynamic>>>> get messageStream => _messageStreamController.stream;

  final _unreadCountController = StreamController<Map<String, int>>.broadcast();
  Stream<Map<String, int>> get unreadCountStream => _unreadCountController.stream;

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
    print('Initializing database...');
    // Request permissions for Android 10+
    await _requestPermissions();

    // Get the application documents directory instead of external storage
    final appDir = await getApplicationDocumentsDirectory();
    final dbPath = join(appDir.path, 'app_database.db');
    print('Database path: $dbPath');

    // Open the database with proper configuration
    return await openDatabase(
      dbPath,
      version: 4,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: (Database db) async {
        // Enable foreign keys
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  // Request permissions
  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      if (status.isDenied) {
        print('Storage permission denied');
      }
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
        settings TEXT,
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
        profile_pic TEXT NOT NULL,
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
    message_id INTEGER NOT NULL,
    temp_id INTEGER,
    file_path TEXT, -- Nullable for undownloaded media
    type TEXT NOT NULL, -- 'image', 'audio'
    mime_type TEXT, -- e.g., 'image/jpeg', 'audio/mpeg'
    file_size INTEGER, -- In bytes
    duration INTEGER, -- In seconds for audio
    thumbnail_path TEXT, -- For image thumbnails
    url TEXT, -- Server URL for downloading
    blurhash TEXT, -- For blurred image placeholders
    is_downloaded INTEGER NOT NULL DEFAULT 0, -- 0: not downloaded, 1: downloaded
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
        reply_to_message TEXT,
        forwarded INTEGER NOT NULL DEFAULT 0,
        edited INTEGER NOT NULL DEFAULT 0,
        deleted INTEGER NOT NULL DEFAULT 0,
        temp_id TEXT,
        FOREIGN KEY (group_id) REFERENCES groups (id) ON DELETE CASCADE,
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
    await db.execute('CREATE INDEX idx_messages_group_id ON messages(group_id)');
    await db.execute('CREATE INDEX idx_messages_timestamp ON messages(timestamp)');
  }

  // Handle schema upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE messages ADD COLUMN isMe INTEGER NOT NULL DEFAULT 0');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE media ADD COLUMN thumbnail_path TEXT');
    }
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE messages ADD COLUMN reply_to_message TEXT');
    }
  }
  Future<void> insertMedia({
    required int messageId,
    required String type,
    required String url,
    String? filePath,
    String? blurhash,
    String? mimeType,
    int? fileSize,
    int? duration,
    String? thumbnailPath,
    bool isDownloaded = false,
  }) async {
    final db = await database;
    try {
      await db.insert(
        'media',
        {
          'message_id': messageId,
          'type': type,
          'url': url,
          'file_path': filePath,
          'blurhash': blurhash,
          'mime_type': mimeType,
          'file_size': fileSize,
          'duration': duration,
          'thumbnail_path': thumbnailPath,
          'is_downloaded': isDownloaded ? 1 : 0,
          'created_at': DateTime.now().toIso8601String(),
          'deleted': 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      print('🔵 [DatabaseHelper] Inserted media for message $messageId');
    } catch (e) {
      print('🔴 [DatabaseHelper] Error inserting media: $e');
    }
  }

  Future<Map<String, dynamic>?> getMedia(int messageId) async {

    print('🔵 [DatabaseHelper] Fetching media for message $messageId');
    final db = await database;
    final result = await db.query(
      'media',
      where: 'message_id = ? ',
      whereArgs: [messageId],
      limit: 1,
    );
    
    return result.isNotEmpty ? result.first : null;
  }

  Future<void> updateMedia({
    required int messageId,
    String? filePath,
    bool? isDownloaded,
    String? thumbnailPath,
    int? fileSize,
    int? duration,
  }) async {
    final db = await database;
    final updateData = <String, dynamic>{};
    if (filePath != null) updateData['file_path'] = filePath;
    if (isDownloaded != null) updateData['is_downloaded'] = isDownloaded ? 1 : 0;
    if (thumbnailPath != null) updateData['thumbnail_path'] = thumbnailPath;
    if (fileSize != null) updateData['file_size'] = fileSize;
    if (duration != null) updateData['duration'] = duration;

    if (updateData.isNotEmpty) {
      await db.update(
        'media',
        updateData,
        where: 'message_id = ?',
        whereArgs: [messageId],
      );
      print('🔵 [DatabaseHelper] Updated media for message $messageId');
    }
  }
  // Insert methods
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
    try {
      // First check if the group exists
      final groupExists = await db.query(
        'groups',
        where: 'id = ?',
        whereArgs: [participant['group_id']],
        limit: 1,
      );

      if (groupExists.isEmpty) {
      
        await db.insert('groups', {
          'id': participant['group_id'],
          'name': 'Group ${participant['group_id']}', // Default name
          'type': 'group',
          'created_at': DateTime.now().toIso8601String(),
          'profile_pic':participant['profile_pic'],
          'created_by': participant['user_id'],
          'amAdmin': participant['is_admin'] is bool ? (participant['is_admin'] ? 1 : 0) : 
                    participant['is_admin'] is int ? participant['is_admin'] : 0,
          'requires_payment': 0,
          'deposit_amount': 0.0,
          'allows_subscription': 0,
          'subscription_frequency': null,
          'subscription_amount': null,
          'has_user_paid': 1,
          'restrict_messages_to_admins': 0,
        });
      }

      // Convert boolean fields to integers
      final participantData = {
        'group_id': participant['group_id'],
        'user_id': participant['user_id'],
        'user_name': participant['user_name'],
        'role': participant['role'] ?? 'member',
        'joined_at': participant['joined_at'] ?? DateTime.now().toIso8601String(),
        'muted': participant['muted'] is bool ? (participant['muted'] ? 1 : 0) : 
                participant['muted'] is int ? participant['muted'] : 0,
        'is_admin': participant['is_admin'] is bool ? (participant['is_admin'] ? 1 : 0) : 
                   participant['is_admin'] is int ? participant['is_admin'] : 0,
        'is_approved': participant['is_approved'] is bool ? (participant['is_approved'] ? 1 : 0) : 
                      participant['is_approved'] is int ? participant['is_approved'] : 0,
        'is_denied': participant['is_denied'] is bool ? (participant['is_denied'] ? 1 : 0) : 
                    participant['is_denied'] is int ? participant['is_denied'] : 0,
        'is_removed': participant['is_removed'] is bool ? (participant['is_removed'] ? 1 : 0) : 
                     participant['is_removed'] is int ? participant['is_removed'] : 0,
        'profile_pic': participant['profile_pic'] ?? 'assets/images/avatar.png',
      };

      print('🔵 [DatabaseHelper] Inserting participant with data: $participantData');

      // Now insert the participant
      final result = await db.insert(
        'participants',
        participantData,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

      print('🔵 [DatabaseHelper] Successfully inserted participant for group ${participant['group_id']}');
      return result;
    } catch (e, stackTrace) {
      print('🔴 [DatabaseHelper] Error inserting participant: $e');
      print('🔴 [DatabaseHelper] Stack trace: $stackTrace');
      rethrow;
    }
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

  Future<int> insertAudioFile(String filePath, String messageId) async {
    final db = await database;
    return await db.insert(
      'media',
      {
        'message_id': messageId, 
        'temp_id': messageId, // No message ID for standalone images
        'file_path': filePath,
        'url':  filePath, // No URL for local images
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

  Future<int> insertImageFile(String filePath, String messageId) async {
    final db = await database;
    return await db.insert(
      'media',
      {
        'message_id': messageId, 
        'temp_id': messageId, // No message ID for standalone images
        'file_path': filePath,
        'url':  filePath, // No URL for local images
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

  Future<void> insertMessage(Map<String, dynamic> message) async {
    final db = await database;
    try {
      print('🔵 [DatabaseHelper] Inserting message with data: $message');
      
      // Convert all fields to their proper types
      final messageData = {
        'group_id': message['group_id'] is String ? int.tryParse(message['group_id']) : 
                   message['group_id'] is int ? message['group_id'] : null,
        'sender_id': message['sender_id']?.toString(),
        'message': message['message']?.toString(),
        'type': message['type']?.toString() ?? 'text',
        'timestamp': message['timestamp']?.toString() ?? DateTime.now().toIso8601String(),
        'status': message['status']?.toString() ?? 'sent',
        'isMe': message['isMe'] is bool ? (message['isMe'] ? 1 : 0) : 
                message['isMe'] is int ? message['isMe'] : 0,
        'id': message['id'] is String ? int.tryParse(message['id']) : 
              message['id'] is int ? message['id'] : null,
        'temp_id': message['temp_id']?.toString(),
        'reply_to_id': message['reply_to_id'] is String ? int.tryParse(message['reply_to_id']) : 
                      message['reply_to_id'] is int ? message['reply_to_id'] : null,
        'reply_to_message': message['reply_to_message']?.toString(),
        'forwarded': message['forwarded'] is bool ? (message['forwarded'] ? 1 : 0) : 
                    message['forwarded'] is int ? message['forwarded'] : 0,
        'edited': message['edited'] is bool ? (message['edited'] ? 1 : 0) : 
                 message['edited'] is int ? message['edited'] : 0,
        'deleted': message['deleted'] is bool ? (message['deleted'] ? 1 : 0) : 
                  message['deleted'] is int ? message['deleted'] : 0,
      };

      // Validate required fields
      if (messageData['group_id'] == null) {
        print('🔴 [DatabaseHelper] Invalid group_id: ${message['group_id']}');
        return;
      }

      if (messageData['sender_id'] == null) {
        print('🔴 [DatabaseHelper] Invalid sender_id: ${message['sender_id']}');
        return;
      }

      // Ensure group exists
      await ensureGroupExists(messageData['group_id'] as int, messageData['sender_id'] as String);

      // Insert the message
      final result = await db.insert(
        'messages',
        messageData,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      print('🔵 [DatabaseHelper] Successfully inserted message, row ID: $result');
      
      // Update group's last_activity
      await db.update(
        'groups',
        {'last_activity': messageData['timestamp']},
        where: 'id = ?',
        whereArgs: [messageData['group_id']],
      );
      
      // Fetch updated messages for the group
      final messages = await getMessages(groupId: messageData['group_id'] as int);
      
      // Broadcast updated messages
      _messageStreamController.add({messageData['group_id'] as int: messages});
      
      // Immediately get and broadcast updated unread counts
      final unreadCounts = await getGroupUnreadCounts();
      _unreadCountController.add(unreadCounts);
    } catch (e, stackTrace) {
      print('🔴 [DatabaseHelper] Error inserting message: $e, StackTrace: $stackTrace');
      rethrow;
    }
  }

  Future<int> insertContact(Map<String, dynamic> contact) async {
    final db = await database;
    return await db.insert('contacts', contact);
  }

  // Query methods
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
    return await db.query(
      'groups',
      orderBy: 'last_activity DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getParticipants(int groupId) async {
    final db = await database;
    return await db.query('participants', where: 'group_id = ?', whereArgs: [groupId]);
  }

  Future<List<Map<String, dynamic>>> getMessages({
    required int? groupId,
    String? sinceTimestamp,
    int limit = 20,
    int offset = 0,
  }) async {
    final db = await database;
    String query = '''
      SELECT m.*, media.file_path as media_path, media.type as media_type,
             p.user_name as sender_name, p.profile_pic as sender_avatar, p.role as sender_role
      FROM messages m
      LEFT JOIN media ON m.media_id = media.id
      LEFT JOIN participants p ON m.sender_id = p.user_id AND m.group_id = p.group_id
      WHERE m.group_id = ? AND m.deleted = 0
    ''';
    List<dynamic> args = [groupId];

    if (sinceTimestamp != null) {
      query += ' AND m.timestamp > ?';
      args.add(sinceTimestamp);
    }

    query += ' ORDER BY m.timestamp DESC LIMIT ? OFFSET ?';
    args.addAll([limit, offset]);

    try {
      final result = await db.rawQuery(query, args);

    return result;
    } catch (e) {
      print('🔴 [DatabaseHelper] Error fetching messages: $e');
      return [];
    }
  }



  Future<List<Map<String, String>>> getGroupMemberNames(int groupId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT user_id, user_name, role, profile_pic FROM participants WHERE group_id = ?',
      [groupId]
    );

    return result
        .map((row) => {
              'id': row['user_id'] as String,
              'name': row['user_name'] as String,
              'role': row['role'] as String? ?? 'Member',
              'profile_pic': row['profile_pic'] as String? ?? '',
            })
        .toList();
  }

  Future<void> updateMemberRole(int groupId, String userId, String newRole) async {
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
    String? senderId,
  }) async {
    final db = await database;
    final notification = {
      'group_id': groupId,
      'sender_id': senderId ?? 'system',
      'message': message,
      'type': 'notification',
      'status': 'delivered',
      'timestamp': DateTime.now().toIso8601String(),
      'isMe': 0,
      'reply_to_id': null,
      'reply_to_message': null,
    };
    final id = await db.insert(
      'messages',
      notification,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    // Broadcast updated messages
    final messages = await getMessages(groupId: groupId);
    _messageStreamController.add({groupId: messages});
    return id;
  }

  // Delete methods
  Future<int> deleteUser(String userId) async {
    final db = await database;
    return await db.delete('profile', where: 'id = ?', whereArgs: [userId]);
  }

  Future<int> removeMember(int groupId, String userId) async {
    final db = await database;
    return await db.delete(
      'participants',
      where: 'group_id = ? AND user_id = ?',
      whereArgs: [groupId, userId],
    );
  }

  Future<int> deleteGroup(int groupId) async {
    final db = await database;
    return await db.delete('groups', where: 'id = ?', whereArgs: [groupId]);
  }

  Future<int> deleteParticipant(int participantId) async {
    final db = await database;
    return await db.delete('participants', where: 'id = ?', whereArgs: [participantId]);
  }

  Future<int> deleteMessage(int messageId) async {
    final db = await database;
    final result = await db.update(
      'messages',
      {'deleted': true},
      where: 'id = ?',
      whereArgs: [messageId],
    );
    // Broadcast updated messages
    final groupId = (await db.query(
      'messages',
      columns: ['group_id'],
      where: 'id = ?',
      whereArgs: [messageId],
    )).first['group_id'] as int;
    final messages = await getMessages(groupId: groupId);
    _messageStreamController.add({groupId: messages});
    return result;
  }

  Future<int> clearMessages(int groupId) async {
    final db = await database;
    final result = await db.update(
      'messages',
      {'deleted': true},
      where: 'group_id = ?',
      whereArgs: [groupId],
    );
    // Broadcast updated messages
    final messages = await getMessages(groupId: groupId);
    _messageStreamController.add({groupId: messages});
    return result;
  }
Future<String?> getgroupic(String userId) async {
  final db = await database;
  final result = await db.query(
    'participants',
    columns: ['profile_pic'], // Assuming the column name is 'profile_pic'
    where: 'user_id = ?',
    whereArgs: [userId],
  );
  return result.isNotEmpty ? result.first['profile_pic'] as String? : null;
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
    final result = await db.update(
      'media',
      {'deleted': true},
      where: 'id = ?',
      whereArgs: [mediaId],
    );
    // Broadcast updated messages for affected groups
    final messagesWithMedia = await db.query(
      'messages',
      where: 'media_id = ?',
      whereArgs: [mediaId],
    );
    for (var message in messagesWithMedia) {
      final groupId = message['group_id'] as int;
      final messages = await getMessages(groupId: groupId);
      _messageStreamController.add({groupId: messages});
    }
    return result;
  }

  // Update methods
  Future<void> updateMessageStatus(String messageId, String status) async {
    final db = await database;
    
    // Get the message details before updating
    final message = await db.query(
      'messages',
      where: 'id = ? OR temp_id = ?',
      whereArgs: [messageId, messageId],
      limit: 1,
    );
    
    if (message.isNotEmpty) {
      final groupId = message.first['group_id'] as int;
      
      // Update the message status
      await db.update(
        'messages',
        {'status': status},
        where: 'id = ? OR temp_id = ?',
        whereArgs: [messageId, messageId],
      );
      
      print('🔵 [DatabaseHelper] Updated message $messageId status to $status');
      
      // Fetch updated messages for the group and broadcast
      final messages = await getMessages(groupId: groupId);
      _messageStreamController.add({groupId: messages});
      
      // Also update unread counts
      _notifyUnreadCountUpdate();
    }
  }

  Future<List<Map<String, dynamic>>> getPendingMessages() async {
    final db = await database;
    return await db.query(
      'messages',
      where: 'status = ?',
      whereArgs: ['pending'],
    );
  }

  Future<void> verifyDatabaseIntegrity() async {
    print('Verifying database integrity...');
    final db = await database;
    final tables = ['profile', 'groups', 'participants', 'messages', 'media', 'contacts'];
    for (var table in tables) {
      try {
        final result = await db.query(table, limit: 1);
        print('Table $table exists with ${result.length} rows');
      } catch (e) {
        print('Error checking table $table: $e');
      }
    }
  }

  Future<void> updateMessageId(String tempId, String serverId, String? status) async {
    final db = await database;
    
    // Get the message details before updating
    final message = await db.query(
      'messages',
      where: 'temp_id = ?',
      whereArgs: [tempId],
      limit: 1,
    );
    
    if (message.isNotEmpty) {
      final groupId = message.first['group_id'] as int;
      
      final updateData = {
        'id': serverId,
        'temp_id': null, // Clear temp_id to prevent duplicates
      };
      if (status != null) {
        updateData['status'] = status;
      }
      
      await db.update(
        'messages',
        updateData,
        where: 'temp_id = ?',
        whereArgs: [tempId],
      );
      
      print('🔵 [DatabaseHelper] Updated message ID from $tempId to $serverId with status $status');
      
      // Fetch updated messages for the group and broadcast
      final messages = await getMessages(groupId: groupId);
      _messageStreamController.add({groupId: messages});
      
      // Also update unread counts
      _notifyUnreadCountUpdate();
    }
  }

  Future<void> updateMessageMediaId(String messageId, int mediaId) async {
    final db = await database;
    await db.update(
      'messages',
      {'media_id': mediaId},
      where: 'id = ?',
      whereArgs: [messageId],
    );
    // Broadcast updated messages
    final message = (await db.query(
      'messages',
      where: 'id = ?',
      whereArgs: [messageId],
    )).first;
    final groupId = message['group_id'] as int;
    final messages = await getMessages(groupId: groupId);
    _messageStreamController.add({groupId: messages});
  }

  Future<void> updateMessageLocalPath(String messageId, String localPath) async {
    final db = await database;
    await db.update(
      'messages',
      {'message': localPath},
      where: 'id = ?',
      whereArgs: [messageId],
    );
    // Broadcast updated messages
    final message = (await db.query(
      'messages',
      where: 'id = ?',
      whereArgs: [messageId],
    )).first;
    final groupId = message['group_id'] as int;
    final messages = await getMessages(groupId: groupId);
    _messageStreamController.add({groupId: messages});
  }

  Future<int> getTotalUnreadMessageCount() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT COUNT(*)
      FROM messages
      WHERE isMe = 0 AND status = 'unread'
    ''');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Dispose stream controller
  void dispose() {
    _messageStreamController.close();
    _database?.close();
  }

  // Add a method to ensure group exists
  Future<void> ensureGroupExists(int groupId, String createdBy) async {
    final db = await database;
    try {
      final groupExists = await db.query(
        'groups',
        where: 'id = ?',
        whereArgs: [groupId],
        limit: 1,
      );

      if (groupExists.isEmpty) {
        print('🔵 [DatabaseHelper] Creating group $groupId');
        await db.insert('groups', {
          'id': groupId,
          'name': 'Group $groupId',
          'type': 'group',
          'created_at': DateTime.now().toIso8601String(),
          'created_by': createdBy,
          'amAdmin': 0,
          'requires_payment': 0,
          'deposit_amount': 0.0,
          'allows_subscription': 0,
          'subscription_frequency': null,
          'subscription_amount': null,
          'has_user_paid': 1,
          'restrict_messages_to_admins': 0,
        });
      }
    } catch (e) {
      print('🔴 [DatabaseHelper] Error ensuring group exists: $e');
      rethrow;
    }
  }

  void _notifyMessageUpdate() async {
    final db = await database;
    final messages = await db.query('messages', orderBy: 'timestamp DESC');
    
    final Map<int, List<Map<String, dynamic>>> groupMessages = {};
    for (var message in messages) {
      final groupId = message['group_id'] as int;
      groupMessages[groupId] ??= [];
      groupMessages[groupId]!.add(message);
    }
    
    _messageStreamController.add(groupMessages);
  }

  Future<Map<String, int>> getGroupUnreadCounts() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT group_id, COUNT(*) as count 
      FROM messages 
      WHERE isMe = 0 AND status = 'unread' 
      GROUP BY group_id
    ''');
    
    final Map<String, int> unreadCounts = {};
    for (var row in result) {
      unreadCounts[row['group_id'].toString()] = row['count'] as int;
    }
    return unreadCounts;
  }

  Future<int> getGroupUnreadCount(String groupId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT COUNT(*)
      FROM messages
      WHERE group_id = ? AND isMe = 0 AND status = 'unread'
    ''', [groupId]);
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> _notifyUnreadCountUpdate() async {
    final unreadCounts = await getGroupUnreadCounts();
    _unreadCountController.add(unreadCounts);
  }

  Future<void> markMessagesAsRead(String groupId, {String? messageId}) async {
    final db = await database;
    try {
      if (messageId != null) {
        await db.update(
          'messages',
          {'status': 'read'},
          where: 'id = ?',
          whereArgs: [messageId],
        );
      } else {
        await db.update(
          'messages',
          {'status': 'read'},
          where: 'group_id = ? AND isMe = 0 AND status = ?',
          whereArgs: [groupId, 'unread'],
        );
      }
      
      // Immediately get updated unread counts and notify listeners
      final unreadCounts = await getGroupUnreadCounts();
      _unreadCountController.add(unreadCounts);
      
      // Also update message stream to reflect read status
      final messages = await getMessages(groupId: int.parse(groupId));
      _messageStreamController.add({int.parse(groupId): messages});
    } catch (e) {
      print('🔴 Error marking messages as read: $e');
    }
  }

  // Fetch the last message for a group by largest id
  Future<Map<String, dynamic>?> getLastMessageById(int groupId) async {
    final db = await database;
    final result = await db.query(
      'messages',
      where: 'group_id = ?',
      whereArgs: [groupId],
      orderBy: 'id DESC',
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }
}