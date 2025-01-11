import 'package:flutter/material.dart';

class GroupSettings extends StatelessWidget {
  const GroupSettings({Key? key}) : super(key: key);

  Widget _buildSettingItem(String title, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title, style: const TextStyle(color: Colors.black87)),
      onTap: () {}, // Implement functionality
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(top: 8.0),
      child: ExpansionTile(
        title: const Text(
          'Group Settings',
          style: TextStyle(
              color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        children: [
          _buildSettingItem('Edit Group Info', Icons.edit),
          _buildSettingItem('Send Messages', Icons.message),
          _buildSettingItem('Group Permissions', Icons.admin_panel_settings),
        ],
      ),
    );
  }
}
