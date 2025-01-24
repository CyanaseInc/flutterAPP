import 'package:flutter/material.dart';
import 'chat_list.dart';
import 'package:cyanase/theme/theme.dart';

class GroupsTab extends StatefulWidget {
  @override
  _GroupsTabState createState() => _GroupsTabState();
}

class _GroupsTabState extends State<GroupsTab> {
  // Key to refresh the ChatList
  final GlobalKey<ChatListState> _chatListKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: white, // Set the background color to white
      body: ChatList(
        key: _chatListKey, // Pass the key to ChatList
      ),
    );
  }
}
