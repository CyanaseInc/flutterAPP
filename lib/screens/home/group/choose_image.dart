import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:cyanase/helpers/database_helper.dart'; // Import your DatabaseHelper class

class ImageMessageHelper {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// Picks an image from the gallery or camera
  Future<File?> pickImage({required ImageSource source}) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);

    if (image != null) {
      return File(image.path);
    }
    return null;
  }

  /// Sends an image message
  Future<void> sendImage({
    required BuildContext context,
    required String imagePath,
    required int? groupId,
    required String senderId,
  }) async {
    try {
      // Validate the image file
      if (!File(imagePath).existsSync()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Image file not found")),
        );
        return;
      }

      // Insert the image file into the media table
      final mediaId = await _dbHelper.insertImageFile(imagePath);

      // Prepare the image message data
      final message = {
        "group_id": groupId,
        "sender_id": senderId,
        "message": imagePath,
        "type": "image",
        "timestamp": DateTime.now().toIso8601String(),
        "media_id": mediaId,
      };

      // Insert the image message into the messages table
      await _dbHelper.insertMessage(message);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Image sent successfully")),
      );
    } catch (e) {
      // Handle errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to send image: ${e.toString()}")),
      );
    }
  }

  /// Displays a dialog to choose between gallery and camera
  Future<void> showImageSourceDialog({
    required BuildContext context,
    required int? groupId,
    required String senderId,
  }) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Choose Image Source"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text("Gallery"),
                onTap: () async {
                  Navigator.pop(context); // Close the dialog
                  final imageFile =
                      await pickImage(source: ImageSource.gallery);
                  if (imageFile != null) {
                    await sendImage(
                      context: context,
                      imagePath: imageFile.path,
                      groupId: groupId,
                      senderId: senderId,
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text("Camera"),
                onTap: () async {
                  Navigator.pop(context); // Close the dialog
                  final imageFile = await pickImage(source: ImageSource.camera);
                  if (imageFile != null) {
                    await sendImage(
                      context: context,
                      imagePath: imageFile.path,
                      groupId: groupId,
                      senderId: senderId,
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
