import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cyanase/theme/theme.dart';

class InviteScreen extends StatelessWidget {
  final String groupName;
  final String profilePic;
  final String groupId; // Unique identifier for the group

  InviteScreen({
    Key? key,
    required this.groupName,
    required this.profilePic,
    required this.groupId,
  }) : super(key: key);
  // Generate a unique link for the group
  String get groupLink =>
      "https://chat.cyanase.com/join/${_generateUniqueLink(groupId)}";

  // Helper method to generate a unique link
  String _generateUniqueLink(String groupId) {
    const chars = 'abcdefghijSHDGqweCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    final randomString = String.fromCharCodes(
      Iterable.generate(
        8, // Length of the random string
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
    return "$groupId-$randomString";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Group link"),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "People with this link do not need admin approval to join this group. Edit in group permissions.",
              style: TextStyle(color: Colors.grey),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundImage: profilePic.isNotEmpty
                      ? FileImage(File(profilePic)) as ImageProvider
                      : AssetImage("assets/images/avatar.png"),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        groupName,
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      GestureDetector(
                        onTap: () => _launchUrl(groupLink),
                        child: SelectableText(
                          groupLink,
                          style: TextStyle(color: Colors.green),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            buildOption(
              icon: Icons.share,
              text: "Send link via WhatsApp",
              onTap: () => _shareViaWhatsApp(groupLink),
            ),
            buildOption(
              icon: Icons.content_copy,
              text: "Copy link",
              onTap: () {
                Clipboard.setData(ClipboardData(text: groupLink));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Link copied to clipboard"),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
            buildOption(
              icon: Icons.share,
              text: "Share link",
              onTap: () => Share.share(groupLink),
            ),
            buildOption(
              icon: Icons.qr_code,
              text: "QR code",
              onTap: () {},
            ),
            buildOption(
              icon: Icons.remove_circle,
              text: "Reset link",
              color: Colors.red,
              onTap: () {
                // Implement logic to reset the link
                // For example, generate a new unique link
                // You can update the groupId or generate a new random string
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget buildOption({
    required IconData icon,
    required String text,
    Color? color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? primaryTwo),
      title: Text(text, style: TextStyle(color: color ?? primaryTwo)),
      onTap: onTap,
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw 'Could not launch $url';
    }
  }

  Future<void> _shareViaWhatsApp(String link) async {
    final url = Uri.parse("https://wa.me/?text=${Uri.encodeComponent(link)}");
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      // If WhatsApp is not installed, open the Play Store/App Store
      final storeUrl = Platform.isAndroid
          ? Uri.parse(
              "https://play.google.com/store/apps/details?id=com.whatsapp")
          : Uri.parse("https://apps.apple.com/app/id310633997");
      if (await canLaunchUrl(storeUrl)) {
        await launchUrl(storeUrl);
      } else {
        throw 'Could not launch $storeUrl';
      }
    }
  }
}
