import 'package:flutter/material.dart';
import 'package:cyanase/theme/theme.dart';

class GroupMedia extends StatelessWidget {
  const GroupMedia({Key? key}) : super(key: key);

  Widget _buildMediaItem(String title, String count, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title, style: const TextStyle(color: Colors.black87)),
      trailing: Text(count, style: const TextStyle(color: Colors.blue)),
      onTap: () {}, // Implement media viewing functionality
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: white,
      margin: const EdgeInsets.only(top: 8.0),
      child: ExpansionTile(
        title: const Text(
          'Media, Links, and Docs',
          style: TextStyle(
              color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        children: [
          _buildMediaItem('Photos', '15', Icons.photo),
          _buildMediaItem('Videos', '5', Icons.video_collection),
          _buildMediaItem('Documents', '3', Icons.description),
        ],
      ),
    );
  }
}
