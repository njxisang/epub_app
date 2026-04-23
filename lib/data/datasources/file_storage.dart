import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import '../../core/utils/file_utils.dart';
import '../models/book_project.dart';

class FileStorage {
  Future<void> saveProject(String projectId, BookProject project) async {
    final projectDir = await FileUtils.getProjectDirectory(projectId);
    final projectFile = File(p.join(projectDir, 'project.json'));
    await projectFile.writeAsString(jsonEncode(project.toJson()));
  }

  Future<BookProject?> loadProject(String projectId) async {
    try {
      final projectDir = await FileUtils.getProjectDirectory(projectId);
      final projectFile = File(p.join(projectDir, 'project.json'));
      if (!await projectFile.exists()) return null;

      final content = await projectFile.readAsString();
      return BookProject.fromJson(jsonDecode(content) as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  Future<void> deleteProject(String projectId) async {
    final projectDir = await FileUtils.getProjectDirectory(projectId);
    final directory = Directory(projectDir);
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  }

  Future<String> saveImage(String projectId, File imageFile) async {
    final imagesDir = await FileUtils.getImagesDirectory(projectId);
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${p.basename(imageFile.path)}';
    final destPath = p.join(imagesDir, fileName);
    await imageFile.copy(destPath);
    return destPath;
  }

  Future<String> saveCover(String projectId, File coverFile) async {
    final coversDir = await FileUtils.getCoversDirectory(projectId);
    final destPath = p.join(coversDir, 'cover${p.extension(coverFile.path)}');
    await coverFile.copy(destPath);
    return destPath;
  }

  Future<void> deleteImage(String imagePath) async {
    final file = File(imagePath);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
