import 'package:cyanase/helpers/web_db.dart';
import 'package:flutter/material.dart';

import 'package:cyanase/screens/home/group/chat_list.dart';

import 'package:cyanase/theme/theme.dart';

class GroupsTab extends StatefulWidget {
  final Function(int)? onUnreadCountChanged;
  final GlobalKey<ChatListState>? chatListKey;

  const GroupsTab({
    super.key,
    this.onUnreadCountChanged,
    this.chatListKey,
  });

  @override
  State<GroupsTab> createState() => _GroupsTabState();
}

class _GroupsTabState extends State<GroupsTab> {
  dynamic userToken = '';

  void _handleUnreadCountChanged(int count) {
    if (mounted) {
      widget.onUnreadCountChanged?.call(count);
    }
  }

  Future<void> getToken() async {
    await WebSharedStorage.init();
    var existingProfile = WebSharedStorage();
    var token = await existingProfile.getCommon('token');
    if (mounted) {
      setState(() {
        userToken = token;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    getToken(); // Call getToken only once during initialization
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: white, // Set the background color to white
      body: ChatList(
        key: widget.chatListKey,
        onUnreadCountChanged: _handleUnreadCountChanged,
      ),
      // body: ChatScreen(),
    );
  }
}
