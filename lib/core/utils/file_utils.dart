import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../constants/app_dimensions.dart';
import 'package:image/image.dart' as img;

class FileUtils {
  FileUtils._();

  static Future<String> getAppDocumentsPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  static Future<String> getProjectsDirectory() async {
    final docsPath = await getAppDocumentsPath();
    final projectsDir = Directory(p.join(docsPath, 'projects'));
    if (!await projectsDir.exists()) {
      await projectsDir.create(recursive: true);
    }
    return projectsDir.path;
  }

  static Future<String> getProjectDirectory(String projectId) async {
    final projectsDir = await getProjectsDirectory();
    final projectDir = Directory(p.join(projectsDir, projectId));
    if (!await projectDir.exists()) {
      await projectDir.create(recursive: true);
    }
    return projectDir.path;
  }

  static Future<String> getImagesDirectory(String projectId) async {
    final projectDir = await getProjectDirectory(projectId);
    final imagesDir = Directory(p.join(projectDir, 'images'));
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }
    return imagesDir.path;
  }

  static Future<String> getCoversDirectory(String projectId) async {
    final projectDir = await getProjectDirectory(projectId);
    final coversDir = Directory(p.join(projectDir, 'covers'));
    if (!await coversDir.exists()) {
      await coversDir.create(recursive: true);
    }
    return coversDir.path;
  }
}

class ImageUtils {
  ImageUtils._();

  static Future<File> compressImageIfNeeded(File imageFile, {bool isCover = false}) async {
    final bytes = await imageFile.readAsBytes();
    final sizeKB = bytes.length / 1024;

    final maxSizeKB = isCover ? 1024 : 512;
    if (sizeKB <= maxSizeKB) {
      return imageFile;
    }

    final image = img.decodeImage(bytes);
    if (image == null) return imageFile;

    final maxWidth = isCover ? AppDimensions.coverWidth.toInt() : AppDimensions.contentImageMaxWidth.toInt();
    final maxHeight = isCover ? AppDimensions.coverHeight.toInt() : AppDimensions.contentImageMaxHeight.toInt();

    img.Image resized = image;
    if (image.width > maxWidth || image.height > maxHeight) {
      if (image.width / image.height > maxWidth / maxHeight) {
        resized = img.copyResize(image, width: maxWidth);
      } else {
        resized = img.copyResize(image, height: maxHeight);
      }
    }

    final quality = isCover ? AppDimensions.coverCompressQuality : AppDimensions.contentImageCompressQuality;
    final extension = p.extension(imageFile.path).toLowerCase();
    List<int> encoded;
    if (extension == '.png') {
      encoded = img.encodePng(resized);
    } else {
      encoded = img.encodeJpg(resized, quality: quality);
    }

    final compressedFile = File(imageFile.path);
    await compressedFile.writeAsBytes(encoded);
    return compressedFile;
  }
}
