import 'package:cyanase/helpers/loader.dart';
import 'package:flutter/material.dart';
import 'package:cyanase/theme/theme.dart'; // Import your theme
import 'package:cyanase/helpers/database_helper.dart';
import 'package:cyanase/helpers/api_helper.dart';

class NotificationsSettingsPage extends StatefulWidget {
  @override
  _NotificationsSettingsPageState createState() =>
      _NotificationsSettingsPageState();
}

class _NotificationsSettingsPageState extends State<NotificationsSettingsPage> {
  bool _autoSaveEnabled = false;
  bool _goalsEnabled = false;

  @override
  void initState() {
    super.initState();
    getProfile();
  }

  Future<void> _updateSetting(String settingKey, bool value) async {
    try {
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;
      final userProfile = await db.query('profile', limit: 1);

      if (userProfile.isEmpty) {
        throw Exception('User profile not found');
      }

      final token = userProfile.first['token'] as String;
      final settings = {
        settingKey: value,
      };

      final response =
          await ApiService.updateNotificationSettings(token, settings);

      if (response['success'] == true) {
        // Map the setting key to the correct database column name
        String dbColumn;
        switch (settingKey) {
          case 'goals':
            dbColumn = 'goals_alert';
            break;
          case 'auto_save':
            dbColumn = 'auto_save';
            break;
          default:
            dbColumn = settingKey;
        }

        print('Updating database: $dbColumn = ${value ? 1 : 0}');
        await db.update('profile', {dbColumn: value ? 1 : 0});

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Settings updated successfully'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        throw Exception(response['message'] ?? 'Failed to update settings');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
      // Revert the switch state on error
      setState(() {
        switch (settingKey) {
          case 'auto_save':
            _autoSaveEnabled = !value;
            break;
          case 'goals':
            _goalsEnabled = !value;
            break;
        }
      });
    }
  }

  void getProfile() async {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;
    final userProfile = await db.query('profile', limit: 1);
    print('User Profile from DB: $userProfile');
    if (mounted) {
      setState(() {
        if (userProfile.isNotEmpty) {
          _autoSaveEnabled = userProfile.first['auto_save'] == 1;
          _goalsEnabled = userProfile.first['goals_alert'] == 1;
        } else {
          _autoSaveEnabled = false;
          _goalsEnabled = false;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Notifications "),
        backgroundColor: primaryTwo,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: white),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
        iconTheme: IconThemeData(
          color: white, // Change the back arrow color to white
        ),
        titleTextStyle: TextStyle(
          color: white, // Custom color
          fontSize: 24,
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Auto Save Section
            _buildNotificationOption(
              title: "Auto Save",
              subtitle: "Make all of my deposits automatic",
              value: _autoSaveEnabled,
              onChanged: (bool value) {
                setState(() => _autoSaveEnabled = value);
                _updateSetting('auto_save', value);
              },
            ),
            Divider(height: 1, indent: 72), // Add a divider

            // Goals Section
            _buildNotificationOption(
              title: "Goals",
              subtitle: "Remind me to invest for my goals",
              value: _goalsEnabled,
              onChanged: (bool value) {
                setState(() => _goalsEnabled = value);
                _updateSetting('goals', value);
              },
            ),
            Divider(height: 1, indent: 72), // Add a divider

            // Updates Section
          ],
        ),
      ),
    );
  }

  // Reusable Notification Option Widget
  Widget _buildNotificationOption({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[600],
        ),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: primaryTwo, // WhatsApp green color
    );
  }
}
