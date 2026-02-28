import 'dart:io';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class ImageProcessingService {
  static final ImagePicker _picker = ImagePicker();
  
  static Future<File?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      print('Pick image from gallery error: $e');
      return null;
    }
  }
  
  static Future<File?> captureImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      print('Capture image from camera error: $e');
      return null;
    }
  }
  
  static Future<Uint8List?> processImage(File imageFile) async {
    try {
      // Read image
      final bytes = await imageFile.readAsBytes();
      final decoded = img.decodeImage(bytes);
      
      if (decoded == null) return null;
      
      // Resize while keeping aspect ratio to reduce payload size for vision model.
      final resized = img.copyResize(decoded, width: decoded.width > 1400 ? 1400 : decoded.width);
      return Uint8List.fromList(img.encodeJpg(resized, quality: 88));
    } catch (e) {
      print('Process image error: $e');
      return null;
    }
  }
  
  static Future<File?> saveProcessedImage(Uint8List imageBytes, String fileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/receipts';
      
      // Create directory if it doesn't exist
      await Directory(path).create(recursive: true);
      
      final file = File('$path/$fileName');
      await file.writeAsBytes(imageBytes);
      
      return file;
    } catch (e) {
      print('Save processed image error: $e');
      return null;
    }
  }
}
