import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../core/utils/file_utils.dart';

class ImageService {
  final ImagePicker _picker = ImagePicker();

  Future<File?> pickImageFromGallery() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1600,
      imageQuality: 85,
    );
    return image != null ? File(image.path) : null;
  }

  Future<File?> takePhoto() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1200,
      maxHeight: 1600,
      imageQuality: 85,
    );
    return image != null ? File(image.path) : null;
  }

  Future<String> saveImage(String projectId, File imageFile, {bool isCover = false}) async {
    final compressedFile = await ImageUtils.compressImageIfNeeded(
      imageFile,
      isCover: isCover,
    );

    if (isCover) {
      return FileUtils.getCoversDirectory(projectId).then((dir) {
        final name = 'cover${imageFile.path.substring(imageFile.path.lastIndexOf('.'))}';
        final dest = File('$dir/$name');
        return dest.writeAsBytes(compressedFile.readAsBytesSync()).then((_) => dest.path);
      });
    } else {
      return FileUtils.getImagesDirectory(projectId).then((dir) {
        final name = '${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}';
        final dest = File('$dir/$name');
        return dest.writeAsBytes(compressedFile.readAsBytesSync()).then((_) => dest.path);
      });
    }
  }

  Future<void> deleteImage(String imagePath) async {
    final file = File(imagePath);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
