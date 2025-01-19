import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class ImageFunctions {
  final ImagePicker _imagePicker = ImagePicker();

  /// Opens the gallery to select an image.
  Future<File?> pickImageFromGallery() async {
    final XFile? image =
        await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      return File(image.path);
    }
    return null;
  }

  /// Opens the camera to capture an image.
  Future<File?> captureImageFromCamera() async {
    final XFile? image =
        await _imagePicker.pickImage(source: ImageSource.camera);
    if (image != null) {
      return File(image.path);
    }
    return null;
  }

  /// Saves the image to the app's private storage directory.
  Future<String> saveImageToStorage(File imageFile) async {
    // Get the app's private external storage directory
    final directory = await getExternalStorageDirectory();
    if (directory == null) {
      throw Exception('External storage not available');
    }

    // Define the folder path
    final appSpecificPath = Directory('${directory.path}/media');
    if (!await appSpecificPath.exists()) {
      await appSpecificPath.create(recursive: true);
    }

    // Generate a unique file name
    final fileName = 'image_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final filePath = '${appSpecificPath.path}/$fileName';

    // Copy the image file to the app's private storage
    final savedFile = await imageFile.copy(filePath);

    // Debug log: Confirm file was saved
    print('File saved: ${savedFile.path}');

    return savedFile.path;
  }

  /// Checks if a file exists at the given path.
  Future<bool> doesFileExist(String filePath) async {
    final file = File(filePath);
    return await file.exists();
  }

  /// Deletes a file at the given path.
  Future<void> deleteFile(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Cleans up unused media files in the storage directory.
  Future<void> cleanupUnusedMediaFiles(List<String> usedFilePaths) async {
    final directory = await getExternalStorageDirectory();
    if (directory == null) {
      throw Exception('External storage not available');
    }

    final mediaFolder = Directory('${directory.path}/media');

    if (await mediaFolder.exists()) {
      // Recursively list all files in the Media folder
      final files = await mediaFolder.list(recursive: true).toList();

      for (var file in files) {
        if (file is File) {
          // Check if the file is in the list of used file paths
          if (!usedFilePaths.contains(file.path)) {
            await file.delete();
          }
        }
      }
    }
  }
}
