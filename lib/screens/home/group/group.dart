import 'package:cyanase/helpers/web_db.dart';
import 'package:cyanase/helpers/websocket.dart';
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
  final GlobalKey<ChatListState> _chatListKey = GlobalKey();

  getToken() async {
    await WebSharedStorage.init();
    var existingProfile = WebSharedStorage();
    var token = existingProfile.getCommon('token');
    setState(() {
      userToken = token;
    });
  }

  @override
  void initState() {
    super.initState();
    getToken(); // Call getToken only once during initialization
  }

  @override
  Widget build(BuildContext context) {
    print('USERTOKEN: $userToken');
    return const Scaffold(
      backgroundColor: white, // Set the background color to white
      // body: ChatList(
      //   key: _chatListKey, // Pass the key to ChatList
      // ),
      body: ChatScreen(),
    );
  }
}
