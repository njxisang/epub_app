import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import '../models/book_project.dart';
import '../datasources/file_storage.dart';
import '../../core/utils/file_utils.dart';

class ProjectRepository {
  final FileStorage _fileStorage;

  ProjectRepository({
    required FileStorage fileStorage,
  }) : _fileStorage = fileStorage;

  /// Lists all projects from the projects directory
  Future<List<BookProject>> getAllProjects() async {
    final projectsDirPath = await FileUtils.getProjectsDirectory();
    final projectsDir = Directory(projectsDirPath);
    if (!await projectsDir.exists()) {
      return [];
    }

    final List<BookProject> projects = [];
    final entities = await projectsDir.list().toList();

    for (final entity in entities) {
      if (entity is Directory) {
        final projectFile = File(p.join(entity.path, 'project.json'));
        if (await projectFile.exists()) {
          try {
            final content = await projectFile.readAsString();
            final json = jsonDecode(content) as Map<String, dynamic>;
            projects.add(BookProject.fromJson(json));
          } catch (_) {
            // Skip invalid project files
          }
        }
      }
    }

    // Sort by updatedAt descending
    projects.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return projects;
  }

  Future<BookProject?> getProjectById(String id) async {
    return _fileStorage.loadProject(id);
  }

  Future<void> saveProject(BookProject project) async {
    await _fileStorage.saveProject(project.id, project);
  }

  Future<void> deleteProject(String id) async {
    await _fileStorage.deleteProject(id);
  }

  Future<String> saveImage(String projectId, File imageFile) async {
    return _fileStorage.saveImage(projectId, imageFile);
  }

  Future<String> saveCover(String projectId, File coverFile) async {
    return _fileStorage.saveCover(projectId, coverFile);
  }

  Future<void> deleteImage(String imagePath) async {
    await _fileStorage.deleteImage(imagePath);
  }
}
