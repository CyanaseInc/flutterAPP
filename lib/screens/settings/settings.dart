import 'package:cyanase/helpers/api_helper.dart';
import 'package:cyanase/helpers/database_helper.dart';
import 'package:cyanase/helpers/endpoints.dart';

// import 'package:cyanase/helpers/web_socket.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/material.dart' show Key;
import 'package:image_picker/image_picker.dart';
import 'dart:io'; // For handling file paths
import 'package:cyanase/theme/theme.dart';
import 'account_settings.dart';
import 'riskprofiler.dart';
import 'notification_settings.dart';
import 'help_page.dart';
import 'invite.dart';

class SettingsPage extends material.StatefulWidget {
  final Function(String?)? onProfileUpdate;
  
  const SettingsPage({Key? key, this.onProfileUpdate}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends material.State<SettingsPage> {
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
      setState(() {
        _profileImage = File(pickedFile.path);
      });

      // Show confirmation dialog
      final shouldSave = await material.showDialog<bool>(
        context: context,
        builder: (material.BuildContext context) {
          return material.AlertDialog(
            title: const material.Text('Save Profile Picture?'),
            content: const material.Text(
                'Do you want to save this as your profile picture?'),
            actions: <material.Widget>[
              material.TextButton(
                child: const material.Text('Cancel'),
                onPressed: () => material.Navigator.of(context).pop(false),
              ),
              material.TextButton(
                child: const material.Text('Save'),
                onPressed: () => material.Navigator.of(context).pop(true),
              ),
            ],
          );
        },
      );

      if (shouldSave == true) {
        final upload =
            await ApiService.uploadProfileImage(token!, _profileImage!);
        if (upload['success']) {
          setState(() {
            picture = upload['profile_pic'];
          });
          // Notify parent about the profile update
          widget.onProfileUpdate?.call(upload['profile_pic']);
        }
      }
    }
  }

  void getProfile() async {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;
    final userProfile = await db.query('profile', limit: 1);

    setState(() {
      if (userProfile.isNotEmpty) {
        name = userProfile.first['name'] as String? ?? 'User';
        email = userProfile.first['email'] as String? ?? 'Not set';
        token = userProfile.first['token'] as String? ?? '';
        picture = ApiEndpoints.server +
            ('/' + (userProfile.first['profile_pic'] as String? ?? ''));
      } else {
        name = 'User';
        email = 'Not set';
        token = '';
      }
    });
  }

  @override
  material.Widget build(material.BuildContext context) {
    return material.Scaffold(
      appBar: material.AppBar(
        title: const material.Text("Settings"),
        titleTextStyle: const material.TextStyle(
          color: white,
          fontSize: 24,
        ),
        backgroundColor: primaryTwo,
        leading: material.IconButton(
          icon: material.Icon(material.Icons.arrow_back_ios, color: white),
          onPressed: () => material.Navigator.pop(context),
        ),
        elevation: 0,
        iconTheme: const material.IconThemeData(
          color: white,
        ),
      ),
      body: material.SingleChildScrollView(
        child: material.Column(
          children: [
            _buildProfileSection(),
            _buildSettingsOptions(context),
          ],
        ),
      ),
    );
  }

  material.Widget _buildProfileSection() {
    return material.Container(
      padding: const material.EdgeInsets.all(16),
      decoration: material.BoxDecoration(
        color: white,
        border: material.Border(
          bottom: material.BorderSide(
            color: material.Colors.grey.shade300,
            width: 1,
          ),
        ),
      ),
      child: material.Row(
        children: [
          material.GestureDetector(
            onTap: _pickImage,
            child: material.CircleAvatar(
              radius: 30,
              backgroundImage: _profileImage != null
                  ? material.FileImage(_profileImage!)
                  : picture != null
                      ? material.NetworkImage(picture!)
                      : const material.AssetImage("assets/images/avatar.png")
                          as material.ImageProvider,
            ),
          ),
          const material.SizedBox(width: 16),
          material.Expanded(
            child: material.Column(
              crossAxisAlignment: material.CrossAxisAlignment.start,
              children: [
                material.Text(
                  name ?? 'User',
                  style: const material.TextStyle(
                    fontSize: 18,
                    fontWeight: material.FontWeight.bold,
                  ),
                ),
                const material.SizedBox(height: 4),
              ],
            ),
          ),
          material.IconButton(
            icon: const material.Icon(material.Icons.edit, color: primaryTwo),
            onPressed: _pickImage,
          ),
        ],
      ),
    );
  }

  material.Widget _buildSettingsOptions(material.BuildContext context) {
    return material.Column(
      children: [
        _buildSettingsOption(
          icon: material.Icons.vpn_key,
          title: "Account",
          subtitle: "Next of kin, password, passcode",
          onTap: () {
            material.Navigator.push(
              context,
              material.MaterialPageRoute(
                  builder: (context) => AccountSettingsPage()),
            );
          },
        ),
        _buildSettingsOption(
          icon: material.Icons.lock,
          title: "Risk profile",
          subtitle: "Configure your risk preferences",
          onTap: () {
            material.Navigator.push(
              context,
              material.MaterialPageRoute(
                  builder: (context) => const RiskProfilerForm()),
            );
          },
        ),
        _buildSettingsOption(
          icon: material.Icons.notifications,
          title: "Notifications",
          subtitle: "Customize your notification preferences",
          onTap: () {
            material.Navigator.push(
              context,
              material.MaterialPageRoute(
                  builder: (context) => NotificationsSettingsPage()),
            );
          },
        ),
        _buildSettingsOption(
          icon: material.Icons.help_outline,
          title: "Help",
          subtitle: "Get help and support",
          onTap: () {
            material.Navigator.push(
              context,
              material.MaterialPageRoute(builder: (context) => HelpPage()),
            );
          },
        ),
        _buildSettingsOption(
          icon: material.Icons.people,
          title: "Invite a Friend",
          subtitle: "Share the app with your friends",
          onTap: () {
            material.Navigator.push(
              context,
              material.MaterialPageRoute(
                  builder: (context) => ReferralPage(
  inviteCode: "CYANASE123", // Dynamic from your backend
  totalEarnings: 1250000.00, // Dynamic from your backend
)),
            );
          },
        ),
      ],
    );
  }

  material.Widget _buildSettingsOption({
    required material.IconData icon,
    required String title,
    required String subtitle,
    required material.VoidCallback onTap,
  }) {
    return material.ListTile(
      leading: material.Container(
        padding: const material.EdgeInsets.all(8),
        decoration: material.BoxDecoration(
          color: primaryTwo.withOpacity(0.1),
          shape: material.BoxShape.circle,
        ),
        child: material.Icon(icon, color: primaryTwo),
      ),
      title: material.Text(
        title,
        style: const material.TextStyle(
          fontSize: 16,
          fontWeight: material.FontWeight.w500,
        ),
      ),
      subtitle: material.Text(
        subtitle,
        style: const material.TextStyle(
          fontSize: 14,
          color: material.Colors.grey,
        ),
      ),
      trailing: const material.Icon(material.Icons.arrow_forward_ios,
          size: 16, color: material.Colors.grey),
      onTap: onTap,
    );
  }
}
