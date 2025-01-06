import 'package:flutter/material.dart';
import 'chat_list.dart';

class GroupsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Set the background color to white
      body: ChatListScreen(),
    );
  }
}
