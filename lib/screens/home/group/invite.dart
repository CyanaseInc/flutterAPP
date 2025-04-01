import 'dart:io';
import 'dart:math';

import 'package:cyanase/helpers/endpoints.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cyanase/theme/theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:qr_flutter/qr_flutter.dart'; // Add this dependency for QR code

class InviteScreen extends StatefulWidget {
  final String groupName;
  final String profilePic;
  final String groupId;

  const InviteScreen({
    Key? key,
    required this.groupName,
    required this.profilePic,
    required this.groupId,
  }) : super(key: key);

  @override
  _InviteScreenState createState() => _InviteScreenState();
}

class _InviteScreenState extends State<InviteScreen> {
  late String _groupLink;

  @override
  void initState() {
    super.initState();
    _groupLink = _generateGroupLink(widget.groupId);
  }

  String _generateGroupLink(String groupId) {
    const chars = 'abcdefghijSHDGqweCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    final randomString = String.fromCharCodes(
      Iterable.generate(
        8,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
    return "${ApiEndpoints.server}/$groupId-$randomString";
  }

  void _resetLink() {
    setState(() {
      _groupLink = _generateGroupLink(widget.groupId);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Link has been reset"),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _shareViaWhatsApp(String link) async {
    final url = Uri.parse("https://wa.me/?text=${Uri.encodeComponent(link)}");
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        final storeUrl = Platform.isAndroid
            ? Uri.parse(
                "https://play.google.com/store/apps/details?id=com.whatsapp")
            : Uri.parse("https://apps.apple.com/app/id310633997");
        if (await canLaunchUrl(storeUrl)) {
          await launchUrl(storeUrl, mode: LaunchMode.externalApplication);
        } else {
          throw 'Could not launch WhatsApp or store';
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _showQRCodeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Group QR Code'),
          content: SizedBox(
            width: 200,
            height: 200,
            child: QrImageView(
              data: _groupLink,
              version: QrVersions.auto,
              size: 200.0,
              backgroundColor: Colors.white,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryTwo,
        title: Text(
          "Group Invite",
          style: TextStyle(fontSize: 20, color: white),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: white),
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
            const SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: widget.profilePic.isNotEmpty
                      ? CachedNetworkImageProvider(widget.profilePic)
                      : const AssetImage('assets/avatar.png') as ImageProvider,
                  onBackgroundImageError: widget.profilePic.isNotEmpty
                      ? (exception, stackTrace) {
                          print(
                              "Failed to load profilePic: ${widget.profilePic}, error: $exception");
                        }
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.groupName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _launchUrl(_groupLink),
                        child: SelectableText(
                          _groupLink,
                          style: const TextStyle(color: Colors.green),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            buildOption(
              icon: Icons.share,
              text: "Send link via WhatsApp",
              onTap: () => _shareViaWhatsApp(_groupLink),
            ),
            buildOption(
              icon: Icons.content_copy,
              text: "Copy link",
              onTap: () {
                Clipboard.setData(ClipboardData(text: _groupLink));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Link copied to clipboard"),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
            buildOption(
              icon: Icons.share,
              text: "Share link",
              onTap: () => Share.share(_groupLink),
            ),
            buildOption(
              icon: Icons.qr_code,
              text: "QR code",
              onTap: _showQRCodeDialog,
            ),
            buildOption(
              icon: Icons.remove_circle,
              text: "Reset link",
              color: Colors.red,
              onTap: _resetLink,
            ),
          ],
        ),
      ),
    );
  }
}
