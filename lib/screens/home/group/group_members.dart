import 'package:cyanase/theme/theme.dart';
import 'package:flutter/material.dart';

class GroupMembers extends StatelessWidget {
  const GroupMembers({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(top: 8.0),
      child: ExpansionTile(
        title: const Text(
          'Members',
          style: TextStyle(
              color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        children: List.generate(
          10,
          (index) => ListTile(
            leading: const CircleAvatar(
              radius: 20,
              backgroundImage: NetworkImage(
                  'URL_OF_MEMBER_IMAGE'), // Replace with actual member image URL
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Member Name $index',
                        style: const TextStyle(fontSize: 16)),
                    Text('Rank: ${index + 1}',
                        style:
                            const TextStyle(fontSize: 14, color: Colors.grey)),
                  ],
                ),
                _buildRoleBreadcrumb(index),
              ],
            ),

            onTap: () {}, // Member options
          ),
        ),
      ),
    );
  }

  Widget _buildRoleBreadcrumb(int index) {
    // Simulating roles for demonstration
    String role = index % 3 == 0
        ? 'Admin'
        : index % 3 == 1
            ? 'Secretary'
            : 'Member';

    Color? backgroundColor;
    if (role == 'Admin') {
      backgroundColor = primaryColor;
    } else if (role == 'Secretary') {
      backgroundColor = Colors.grey;
    }

    return role == 'Member'
        ? SizedBox.shrink()
        : Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              role,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          );
  }
}

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      appBar: AppBar(title: const Text('Group Members')),
      body: GroupMembers(),
    ),
  ));
}
