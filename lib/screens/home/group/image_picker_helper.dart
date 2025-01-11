import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'dart:io';
import 'package:flutter/material.dart';

class ImagePickerHelper {
  static final ImagePicker _picker = ImagePicker();

  // Function to pick image from gallery and crop it
  static Future<void> pickImageFromGallery(
      BuildContext context, Function(File) updateProfilePic) async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        await _cropImage(context, File(image.path), updateProfilePic);
      }
    } catch (e) {
      _showErrorSnackBar(context, 'Failed to pick image from gallery: $e');
    }
  }

  // Function to pick image from camera and crop it
  static Future<void> pickImageFromCamera(
      BuildContext context, Function(File) updateProfilePic) async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);

      if (image != null) {
        await _cropImage(context, File(image.path), updateProfilePic);
      }
    } catch (e) {
      _showErrorSnackBar(context, 'Failed to pick image from camera: $e');
    }
  }

  // Function to handle image cropping
  static Future<void> _cropImage(BuildContext context, File imageFile,
      Function(File) updateProfilePic) async {
    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: imageFile.path,
        aspectRatio:
            const CropAspectRatio(ratioX: 1, ratioY: 1), // Square aspect ratio
        compressQuality: 100,
        maxWidth: 1080,
        maxHeight: 1080,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: Colors.deepOrange,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: 'Crop Image',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
            aspectRatioPickerButtonHidden: true,
          ),
        ],
      );

      if (croppedFile != null) {
        updateProfilePic(File(croppedFile.path));
      }
    } catch (e) {
      _showErrorSnackBar(context, 'Failed to crop image: $e');
    }
  }

  // Helper function to show error messages
  static void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
