import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cyanase/theme/theme.dart';

class FullScreenImage extends StatelessWidget {
  final String imagePath;

  const FullScreenImage({Key? key, required this.imagePath}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: FutureBuilder<bool>(
          future: _checkImageExists(imagePath),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              // Show a loading indicator while checking if the image exists
              return CircularProgressIndicator(
                color: white,
              );
            } else if (snapshot.hasData && snapshot.data!) {
              // If the image exists, display it
              return GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Image.file(
                  File(imagePath),
                  fit: BoxFit.contain,
                ),
              );
            } else {
              // If the image does not exist, show an error message
              return Text(
                "Image not found",
                style: TextStyle(
                  color: white,
                  fontSize: 18,
                ),
              );
            }
          },
        ),
      ),
    );
  }

  /// Checks if the image file exists at the given path.
  Future<bool> _checkImageExists(String path) async {
    try {
      final file = File(path);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }
}
