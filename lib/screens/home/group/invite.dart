import 'package:cyanase/helpers/loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cyanase/helpers/endpoints.dart';
import 'package:cyanase/theme/theme.dart';
import 'dart:io' show Platform;

class InviteScreen extends StatefulWidget {
  final String groupName;
  final String profilePic;
  final String groupId;
  final String inviteCode;
  final Future<void> Function()? onResetLink;

  const InviteScreen({
    Key? key,
    required this.groupName,
    required this.profilePic,
    required this.groupId,
    required this.inviteCode,
    this.onResetLink,
  }) : super(key: key);

  @override
  State<InviteScreen> createState() => _InviteScreenState();
}

class _InviteScreenState extends State<InviteScreen> {
  late String _groupLink;
  bool _isResetting = false;

  @override
  void initState() {
    super.initState();
    _groupLink = _generateServerLink();
  }

  String _generateServerLink() {
    return "${ApiEndpoints.server}/invite/${widget.inviteCode}";
  }

  void _handleResetLink() {
    if (_isResetting || widget.onResetLink == null) return;

    setState(() => _isResetting = true);
    widget.onResetLink!().then((_) {
      setState(() => _groupLink = _generateServerLink());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("New invite link generated")),
      );
    }).catchError((e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to reset link: ${e.toString()}")),
      );
    }).whenComplete(() {
      setState(() => _isResetting = false);
    });
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not launch URL")),
      );
    }
  }

  Future<void> _shareViaWhatsApp(String link) async {
    String whatsappUrl;
    if (Platform.isIOS) {
      whatsappUrl = "https://wa.me/?text=${Uri.encodeComponent(link)}";
    } else {
      whatsappUrl = "whatsapp://send?text=${Uri.encodeComponent(link)}";
    }

    final uri = Uri.parse(whatsappUrl);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback to share_plus
        await Share.share(
          link,
          subject: 'Join ${widget.groupName}',
          sharePositionOrigin: Rect.fromLTWH(
              0,
              0,
              MediaQuery.of(context).size.width,
              MediaQuery.of(context).size.height / 2),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Could not open WhatsApp, using system share")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error sharing to WhatsApp: $e")),
      );
    }
  }

  void _showQRCodeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Group QR Code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            QrImageView(
              data: _groupLink,
              version: QrVersions.auto,
              size: 200.0,
              backgroundColor: Colors.white,
            ),
            const SizedBox(height: 16),
            Text(
              _groupLink,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
    bool enabled = true,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? primaryTwo),
      title: Text(label, style: TextStyle(color: color ?? primaryTwo)),
      onTap: enabled ? onTap : null,
      enabled: enabled,
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Share this link to invite others to the group",
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundImage: widget.profilePic.isNotEmpty
                      ? CachedNetworkImageProvider(widget.profilePic)
                      : const AssetImage('assets/default_group.png')
                          as ImageProvider,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.groupName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: () => _launchUrl(_groupLink),
                        child: Text(
                          _groupLink,
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildActionButton(
              icon: Icons.share,
              label: 'Share via WhatsApp',
              onTap: () => _shareViaWhatsApp(_groupLink),
            ),
            _buildActionButton(
              icon: Icons.content_copy,
              label: 'Copy link',
              onTap: () {
                Clipboard.setData(ClipboardData(text: _groupLink));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Link copied to clipboard')),
                );
              },
            ),
            _buildActionButton(
              icon: Icons.qr_code,
              label: 'Show QR code',
              onTap: _showQRCodeDialog,
            ),
            _buildActionButton(
              icon: Icons.refresh,
              label: 'Generate new link',
              onTap: _handleResetLink,
              color: _isResetting ? Colors.grey : Colors.red,
              enabled: !_isResetting && widget.onResetLink != null,
            ),
            if (_isResetting) const Loader(),
          ],
        ),
      ),
    );
  }
}
