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

  /// Saves the image to the app's storage directory.
  Future<String> saveImageToStorage(File imageFile) async {
    final directory = await getApplicationDocumentsDirectory();
    final imagesDirectory = Directory('${directory.path}/images');

    // Create the images directory if it doesn't exist
    if (!await imagesDirectory.exists()) {
      await imagesDirectory.create(recursive: true);
      print("Created directory: ${imagesDirectory.path}");
    }

    // Define the file path for the image
    final imagePath =
        '${imagesDirectory.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';

    // Copy the image to the new location
    final savedImage = await imageFile.copy(imagePath);
    print("Image saved at: ${savedImage.path}");
    return savedImage.path;
  }
}
