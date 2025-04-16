import 'package:cyanase/helpers/web_db.dart';
import 'package:flutter/material.dart';
import 'chat_list.dart';
import 'package:cyanase/theme/theme.dart';

class GroupsTab extends StatefulWidget {
  @override
  _GroupsTabState createState() => _GroupsTabState();
}

class _GroupsTabState extends State<GroupsTab> {
  dynamic userToken = '';
  // Key to refresh the ChatList
  final GlobalKey<ChatListState> _chatListKey = GlobalKey<ChatListState>();

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
        key: _chatListKey, // Pass the key to ChatList
      ),
      // body: ChatScreen(),
    );
  }
}
