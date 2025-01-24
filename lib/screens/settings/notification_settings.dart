import 'package:flutter/material.dart';
import 'package:cyanase/theme/theme.dart'; // Import your theme

class NotificationsSettingsPage extends StatefulWidget {
  @override
  _NotificationsSettingsPageState createState() =>
      _NotificationsSettingsPageState();
}

class _NotificationsSettingsPageState extends State<NotificationsSettingsPage> {
  // State variables to manage switch values
  bool _autoSaveEnabled = false;
  bool _goalsEnabled = false;
  bool _updatesEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Notifications "),
        backgroundColor: primaryTwo, // WhatsApp green color
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
                setState(() {
                  _autoSaveEnabled = value;
                });
              },
            ),
            Divider(height: 1, indent: 72), // Add a divider

            // Goals Section
            _buildNotificationOption(
              title: "Goals",
              subtitle: "Remind me to invest for my goals",
              value: _goalsEnabled,
              onChanged: (bool value) {
                setState(() {
                  _goalsEnabled = value;
                });
              },
            ),
            Divider(height: 1, indent: 72), // Add a divider

            // Updates Section
            _buildNotificationOption(
              title: "Updates",
              subtitle: "Get me product updates and investment newsletters",
              value: _updatesEnabled,
              onChanged: (bool value) {
                setState(() {
                  _updatesEnabled = value;
                });
              },
            ),
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
