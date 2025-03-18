import 'package:cyanase/helpers/api_helper.dart';
import 'package:cyanase/helpers/web_db.dart';
// import 'package:cyanase/helpers/web_socket.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io'; // For handling file paths
import 'package:cyanase/theme/theme.dart';
import 'account_settings.dart';
import 'riskprofiler.dart';
import 'notification_settings.dart';
import 'help_page.dart';
import 'invite.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  File? _profileImage; // To store the selected image
  String? name;
  String? email;
  String? picture;
  String? token;

  @override
  void initState() {
    super.initState();
    getProfile(); // Fetch data when the widget is initialized
  }

  // Function to pick an image from the gallery
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final upload =
          await ApiService.uploadProfileImage(token!, _profileImage!);
    }
  }

  void getProfile() async {
    // final dbHelper = DatabaseHelper();
    // final db = await dbHelper.database;
    // final userProfile = await db.query('profile', limit: 1);

    await WebSharedStorage.init();
    var existingProfile = WebSharedStorage();
    setState(() {
      name = existingProfile.getCommon('name');
      email = existingProfile.getCommon('name');
      picture = existingProfile.getCommon('picture');
      token = existingProfile.getCommon('token');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        titleTextStyle: const TextStyle(
          color: white, // Custom color
          fontSize: 24,
        ),
        backgroundColor: primaryTwo, // WhatsApp green color
        elevation: 0,
        iconTheme: const IconThemeData(
          color: white, // Change the back arrow color to white
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Section
            _buildProfileSection(),
            // Settings Options
            _buildSettingsOptions(context),
          ],
        ),
      ),
    );
  }

  // Profile Section
  Widget _buildProfileSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade300,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Profile Picture
          GestureDetector(
            onTap: _pickImage, // Allow tapping on the profile picture to edit
            child: CircleAvatar(
              radius: 30,
              backgroundImage: picture != null
                  ? NetworkImage(picture!)
                  : const AssetImage("assets/profile.jpg")
                      as ImageProvider, // Default image
            ),
          ),
          const SizedBox(width: 16),
          // Profile Name and Status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name!, // Replace with user's name
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
              ],
            ),
          ),
          // Edit Profile Button
          IconButton(
            icon: const Icon(Icons.edit, color: primaryTwo),
            onPressed: _pickImage, // Allow tapping on the edit icon to edit
          ),
        ],
      ),
    );
  }

  // Settings Options
  Widget _buildSettingsOptions(BuildContext context) {
    return Column(
      children: [
        _buildSettingsOption(
          icon: Icons.vpn_key,
          title: "Account",
          subtitle: "Next of kin, password, privacy",
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AccountSettingsPage()),
            );
          },
        ),
        _buildSettingsOption(
          icon: Icons.lock,
          title: "Risk profile",
          subtitle: "Configure your risk preferences",
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const RiskProfilerForm()),
            );
          },
        ),
        _buildSettingsOption(
          icon: Icons.notifications,
          title: "Notifications",
          subtitle: "Customize your notification preferences",
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => NotificationsSettingsPage()),
            );
          },
        ),
        _buildSettingsOption(
          icon: Icons.help_outline,
          title: "Help",
          subtitle: "Get help and support",
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => HelpPage()),
            );
          },
        ),
        _buildSettingsOption(
          icon: Icons.people,
          title: "Invite a Friend",
          subtitle: "Share the app with your friends",
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => InviteFriendPage()),
            );
          },
        ),
      ],
    );
  }

  // Reusable Settings Option Widget
  Widget _buildSettingsOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8), // Padding around the icon
        decoration: BoxDecoration(
          color: primaryTwo.withOpacity(0.1), // Background color with opacity
          shape: BoxShape.circle, // Circular shape
        ),
        child: Icon(icon, color: primaryTwo), // Icon with primary color
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 14,
          color: Colors.grey,
        ),
      ),
      trailing:
          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }
}
